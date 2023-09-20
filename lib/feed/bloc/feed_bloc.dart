import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:lemmy_api_client/v3.dart';
import 'package:stream_transform/stream_transform.dart';

import 'package:thunder/account/models/account.dart';
import 'package:thunder/core/auth/helpers/fetch_account.dart';
import 'package:thunder/core/models/post_view_media.dart';
import 'package:thunder/core/singletons/lemmy_client.dart';
import 'package:thunder/feed/view/feed_page.dart';
import 'package:thunder/utils/post.dart';

part 'feed_event.dart';
part 'feed_state.dart';

const throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final LemmyClient lemmyClient;

  FeedBloc({required this.lemmyClient}) : super(const FeedState()) {
    on<ResetFeed>(_onResetFeed);
    on<FeedFetched>(
      _onFeedFetched,
      transformer: throttleDroppable(throttleDuration),
    );
    on<FeedChangeSortTypeEvent>(_onFeedChangeSortType);
    on<FeedItemUpdated>(_onFeedItemUpdated);
  }

  Future<void> _onFeedItemUpdated(FeedItemUpdated event, Emitter<FeedState> emit) async {
    emit(state.copyWith(status: FeedStatus.fetching));

    List<PostViewMedia> updatedPostViewMedias = state.postViewMedias.map((PostViewMedia postViewMedia) {
      if (postViewMedia.postView.post.id == event.postViewMedia.postView.post.id) {
        return event.postViewMedia;
      } else {
        return postViewMedia;
      }
    }).toList();

    emit(state.copyWith(status: FeedStatus.success, postViewMedias: updatedPostViewMedias));
  }

  /// Resets the FeedState to its initial state
  Future<void> _onResetFeed(ResetFeed event, Emitter<FeedState> emit) async {
    emit(const FeedState(
      status: FeedStatus.initial,
      postViewMedias: <PostViewMedia>[],
      hasReachedEnd: false,
      feedType: FeedType.general,
      postListingType: null,
      sortType: null,
      fullCommunityView: null,
      communityId: null,
      communityName: null,
      userId: null,
      username: null,
      currentPage: 1,
    ));
  }

  /// Changes the current sort type of the feed, and refreshes the feed
  Future<void> _onFeedChangeSortType(FeedChangeSortTypeEvent event, Emitter<FeedState> emit) async {
    add(FeedFetched(
      feedType: state.feedType,
      postListingType: state.postListingType,
      sortType: event.sortType,
      communityId: state.communityId,
      communityName: state.communityName,
      userId: state.userId,
      username: state.username,
      reset: true,
    ));
  }

  /// Fetches the posts, community information, and user information for the feed
  Future<void> _onFeedFetched(FeedFetched event, Emitter<FeedState> emit) async {
    // Assert any requirements
    if (event.reset) assert(event.feedType != null);
    if (event.reset && event.feedType == FeedType.community) assert(!(event.communityId == null && event.communityName == null));
    if (event.reset && event.feedType == FeedType.user) assert(event.userId != null && event.username != null);
    if (event.reset && event.feedType == FeedType.general) assert(event.postListingType != null);

    // Handle the initial fetch or reload of a feed
    if (event.reset) {
      add(ResetFeed());
      emit(state.copyWith(status: FeedStatus.fetching));

      FullCommunityView? fullCommunityView;

      switch (event.feedType) {
        case FeedType.community:
          // Fetch community information
          fullCommunityView = await _fetchCommunityInformation(id: event.communityId, name: event.communityName);
          break;
        case FeedType.user:
          // Fetch user information
          break;
        case FeedType.general:
          break;
        default:
          break;
      }

      Map<String, dynamic> postViewMediaResult = await _fetchPosts(
        page: 1,
        postListingType: event.postListingType,
        sortType: event.sortType,
        communityId: event.communityId,
        communityName: event.communityName,
        userId: event.userId,
        username: event.username,
      );

      // Extract information from the response
      List<PostViewMedia> postViewMedias = postViewMediaResult['postViewMedias'];
      bool hasReachedEnd = postViewMediaResult['hasReachedEnd'];
      int currentPage = postViewMediaResult['currentPage'];

      return emit(state.copyWith(
        status: FeedStatus.success,
        postViewMedias: postViewMedias,
        hasReachedEnd: hasReachedEnd,
        feedType: event.feedType,
        postListingType: event.postListingType,
        sortType: event.sortType,
        fullCommunityView: fullCommunityView,
        communityId: event.communityId,
        communityName: event.communityName,
        userId: event.userId,
        username: event.username,
        currentPage: currentPage,
      ));
    }

    // Handle fetching the next page of the feed
    emit(state.copyWith(status: FeedStatus.fetching));

    List<PostViewMedia> postViewMedias = List.from(state.postViewMedias);

    Map<String, dynamic> postViewMediaResult = await _fetchPosts(
      page: state.currentPage,
      postListingType: state.postListingType,
      sortType: state.sortType,
      communityId: state.communityId,
      communityName: state.communityName,
      userId: state.userId,
      username: state.username,
    );

    // Extract information from the response
    List<PostViewMedia> newPostViewMedias = postViewMediaResult['postViewMedias'];
    bool hasReachedEnd = postViewMediaResult['hasReachedEnd'];
    int currentPage = postViewMediaResult['currentPage'];

    postViewMedias.addAll(newPostViewMedias);

    return emit(state.copyWith(
      status: FeedStatus.success,
      postViewMedias: postViewMedias,
      hasReachedEnd: hasReachedEnd,
      currentPage: currentPage,
    ));
  }

  /// Helper function which handles the logic of fetching posts from the API
  Future<Map<String, dynamic>> _fetchPosts({
    int limit = 20,
    int page = 1,
    PostListingType? postListingType,
    SortType? sortType,
    int? communityId,
    String? communityName,
    int? userId,
    String? username,
  }) async {
    Account? account = await fetchActiveProfileAccount();
    LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

    bool hasReachedEnd = false;

    List<PostViewMedia> postViewMedias = [];

    int currentPage = page;

    do {
      List<PostView> batch = await lemmy.run(GetPosts(
        auth: account?.jwt,
        page: currentPage,
        sort: sortType,
        type: postListingType,
        communityId: communityId,
        communityName: communityName,
      ));

      // Parse the posts and add in media information which is used elsewhere in the app
      List<PostViewMedia> formattedPosts = await parsePostViews(batch);
      postViewMedias.addAll(formattedPosts);

      if (batch.isEmpty) hasReachedEnd = true;
      currentPage++;
    } while (!hasReachedEnd && postViewMedias.length < limit);

    return {'postViewMedias': postViewMedias, 'hasReachedEnd': hasReachedEnd, 'currentPage': currentPage};
  }

  Future<FullCommunityView> _fetchCommunityInformation({int? id, String? name}) async {
    assert(!(id == null && name == null));

    Account? account = await fetchActiveProfileAccount();
    LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

    FullCommunityView fullCommunityView = await lemmy.run(GetCommunity(
      auth: account?.jwt,
      id: id,
      name: name,
    ));

    return fullCommunityView;
  }
}
