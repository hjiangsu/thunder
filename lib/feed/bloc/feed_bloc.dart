import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:lemmy_api_client/v3.dart';
import 'package:stream_transform/stream_transform.dart';

import 'package:thunder/core/models/post_view_media.dart';
import 'package:thunder/core/singletons/lemmy_client.dart';
import 'package:thunder/feed/utils/community.dart';
import 'package:thunder/feed/utils/post.dart';
import 'package:thunder/feed/view/feed_page.dart';
import 'package:thunder/post/enums/post_action.dart';
import 'package:thunder/post/utils/post.dart';
import 'package:thunder/utils/error_messages.dart';

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
    /// Handles resetting the feed to its initial state
    on<ResetFeedEvent>(
      _onResetFeed,
      transformer: restartable(),
    );

    /// Handles fetching the feed
    on<FeedFetchedEvent>(
      _onFeedFetched,
      transformer: restartable(),
    );

    /// Handles changing the sort type of the feed
    on<FeedChangeSortTypeEvent>(
      _onFeedChangeSortType,
      transformer: restartable(),
    );

    /// Handles updating a given item within the feed
    on<FeedItemUpdatedEvent>(
      _onFeedItemUpdated,
      transformer: throttleDroppable(Duration.zero),
    );

    on<FeedCommunityViewUpdatedEvent>(
      _onFeedCommunityViewUpdated,
      transformer: throttleDroppable(Duration.zero),
    );

    /// Handles actions on a given item within the feed
    on<FeedItemActionedEvent>(
      _onFeedItemActioned,
      transformer: throttleDroppable(Duration.zero),
    );

    /// Handles clearing any messages from the state
    on<FeedClearMessageEvent>(
      _onFeedClearMessage,
      transformer: throttleDroppable(Duration.zero),
    );

    /// Handles scrolling to top of the feed
    on<ScrollToTopEvent>(
      _onFeedScrollToTop,
      transformer: throttleDroppable(Duration.zero),
    );

    /// Handles dismissing read posts from the feed
    on<FeedDismissReadEvent>(
      _onFeedDismissRead,
      transformer: throttleDroppable(Duration.zero),
    );

    /// Handles hiding posts from the feed
    on<FeedHidePostsFromViewEvent>(
      _onFeedHidePostsFromView,
      transformer: throttleDroppable(Duration.zero),
    );

    /// Handles creating a new post
    on<CreatePostEvent>(
      _onCreatePost,
      transformer: throttleDroppable(Duration.zero),
    );

    on<PopulatePostsEvent>(
      _onPopulatePosts,
      transformer: throttleDroppable(Duration.zero),
    );
  }

  /// Handles hiding posts from the feed. This will remove any posts from the feed for the given post ids
  Future<void> _onFeedHidePostsFromView(FeedHidePostsFromViewEvent event, Emitter<FeedState> emit) async {
    emit(state.copyWith(status: FeedStatus.fetching));

    List<PostViewMedia> postViewMedias = List.from(state.postViewMedias);
    postViewMedias.removeWhere((PostViewMedia postViewMedia) => event.postIds.contains(postViewMedia.postView.post.id));

    emit(state.copyWith(status: FeedStatus.success, postViewMedias: postViewMedias));
  }

  /// Handles dismissing read posts from the feed
  Future<void> _onFeedDismissRead(FeedDismissReadEvent event, Emitter<FeedState> emit) async {
    emit(state.copyWith(status: FeedStatus.success, dismissReadId: state.dismissReadId + 1));
  }

  /// Handles scrolling to top of the feed
  Future<void> _onFeedScrollToTop(ScrollToTopEvent event, Emitter<FeedState> emit) async {
    emit(state.copyWith(status: FeedStatus.success, scrollId: state.scrollId + 1));
  }

  /// Handles clearing any messages from the state
  Future<void> _onFeedClearMessage(FeedClearMessageEvent event, Emitter<FeedState> emit) async {
    emit(state.copyWith(status: state.status == FeedStatus.failureLoadingCommunity ? state.status : FeedStatus.success, message: null));
  }

  /// Handles post related actions on a given item within the feed
  Future<void> _onFeedItemActioned(FeedItemActionedEvent event, Emitter<FeedState> emit) async {
    assert(!(event.postViewMedia == null && event.postId == null));
    emit(state.copyWith(status: FeedStatus.fetching));

    // TODO: Check if the current account has permission to perform the PostAction
    switch (event.postAction) {
      case PostAction.vote:
        // Optimistically update the post
        int existingPostViewMediaIndex = state.postViewMedias.indexWhere((PostViewMedia postViewMedia) => postViewMedia.postView.post.id == event.postId);

        PostViewMedia postViewMedia = state.postViewMedias[existingPostViewMediaIndex];
        PostView originalPostView = postViewMedia.postView;

        try {
          PostView updatedPostView = optimisticallyVotePost(postViewMedia, event.value);
          state.postViewMedias[existingPostViewMediaIndex].postView = updatedPostView;

          // Emit the state to update UI immediately
          emit(state.copyWith(status: FeedStatus.success));
          emit(state.copyWith(status: FeedStatus.fetching));

          PostView postView = await votePost(originalPostView.post.id, event.value);
          state.postViewMedias[existingPostViewMediaIndex].postView = postView;

          emit(state.copyWith(status: FeedStatus.success));
        } catch (e) {
          // Restore the original post contents
          state.postViewMedias[existingPostViewMediaIndex].postView = originalPostView;
          return emit(state.copyWith(status: FeedStatus.failure));
        }
      case PostAction.save:
        // Optimistically save the post
        int existingPostViewMediaIndex = state.postViewMedias.indexWhere((PostViewMedia postViewMedia) => postViewMedia.postView.post.id == event.postId);

        PostViewMedia postViewMedia = state.postViewMedias[existingPostViewMediaIndex];
        PostView originalPostView = postViewMedia.postView;

        try {
          PostView updatedPostView = optimisticallySavePost(postViewMedia, event.value);
          state.postViewMedias[existingPostViewMediaIndex].postView = updatedPostView;

          // Emit the state to update UI immediately
          emit(state.copyWith(status: FeedStatus.success));
          emit(state.copyWith(status: FeedStatus.fetching));

          PostView postView = await savePost(originalPostView.post.id, event.value);
          state.postViewMedias[existingPostViewMediaIndex].postView = postView;

          emit(state.copyWith(status: FeedStatus.success));
        } catch (e) {
          // Restore the original post contents
          state.postViewMedias[existingPostViewMediaIndex].postView = originalPostView;
          return emit(state.copyWith(status: FeedStatus.failure));
        }
      case PostAction.read:
        // Optimistically read the post
        int existingPostViewMediaIndex = state.postViewMedias.indexWhere((PostViewMedia postViewMedia) => postViewMedia.postView.post.id == event.postId);

        PostViewMedia postViewMedia = state.postViewMedias[existingPostViewMediaIndex];
        PostView originalPostView = postViewMedia.postView;

        // Give a slight delay to have the UI perform any navigation first
        await Future.delayed(const Duration(milliseconds: 250));

        try {
          PostView updatedPostView = optimisticallyReadPost(postViewMedia, event.value);
          state.postViewMedias[existingPostViewMediaIndex].postView = updatedPostView;

          // Emit the state to update UI immediately
          emit(state.copyWith(status: FeedStatus.success));
          emit(state.copyWith(status: FeedStatus.fetching));

          bool success = await markPostAsRead(originalPostView.post.id, event.value);
          if (success) return emit(state.copyWith(status: FeedStatus.success));

          // Restore the original post contents if not successful
          state.postViewMedias[existingPostViewMediaIndex].postView = originalPostView;
          return emit(state.copyWith(status: FeedStatus.failure));
        } catch (e) {
          // Restore the original post contents
          state.postViewMedias[existingPostViewMediaIndex].postView = originalPostView;
          return emit(state.copyWith(status: FeedStatus.failure));
        }
      case PostAction.delete:
        // Optimistically delete the post
        int existingPostViewMediaIndex = state.postViewMedias.indexWhere((PostViewMedia postViewMedia) => postViewMedia.postView.post.id == event.postId);

        PostViewMedia postViewMedia = state.postViewMedias[existingPostViewMediaIndex];
        PostView originalPostView = postViewMedia.postView;

        try {
          PostView updatedPostView = optimisticallyDeletePost(postViewMedia.postView, event.value);
          state.postViewMedias[existingPostViewMediaIndex].postView = updatedPostView;

          // Emit the state to update UI immediately
          emit(state.copyWith(status: FeedStatus.success));
          emit(state.copyWith(status: FeedStatus.fetching));

          bool success = await deletePost(originalPostView.post.id, event.value);
          if (success) return emit(state.copyWith(status: FeedStatus.success));

          // Restore the original post contents if not successful
          state.postViewMedias[existingPostViewMediaIndex].postView = originalPostView;
          return emit(state.copyWith(status: FeedStatus.failure));
        } catch (e) {
          // Restore the original post contents
          state.postViewMedias[existingPostViewMediaIndex].postView = originalPostView;
          return emit(state.copyWith(status: FeedStatus.failure));
        }
      case PostAction.report:
      // TODO: Handle this case.
      case PostAction.lock:
      // TODO: Handle this case.
      case PostAction.pinCommunity:
      // TODO: Handle this case.
      case PostAction.remove:
      // TODO: Handle this case.
      case PostAction.pinInstance:
      // TODO: Handle this case.
      case PostAction.purge:
      // TODO: Handle this case.
      default:
        emit(state.copyWith(status: FeedStatus.failure, message: 'Action is not supported'));
        break;
    }
  }

  /// Handles updating a given item within the feed
  Future<void> _onFeedItemUpdated(FeedItemUpdatedEvent event, Emitter<FeedState> emit) async {
    emit(state.copyWith(status: FeedStatus.fetching));

    for (final (index, postViewMedia) in state.postViewMedias.indexed) {
      if (postViewMedia.postView.post.id == event.postViewMedia.postView.post.id) {
        state.postViewMedias[index] = event.postViewMedia;
      }
    }

    emit(state.copyWith(status: FeedStatus.success, postViewMedias: state.postViewMedias));
  }

  /// Handles updating information about a community
  Future<void> _onFeedCommunityViewUpdated(FeedCommunityViewUpdatedEvent event, Emitter<FeedState> emit) async {
    emit(state.copyWith(status: FeedStatus.fetching));

    GetCommunityResponse? updatedFullCommunityView = state.fullCommunityView?.copyWith(communityView: event.communityView);

    emit(state.copyWith(status: FeedStatus.success, fullCommunityView: updatedFullCommunityView));
  }

  /// Resets the FeedState to its initial state
  Future<void> _onResetFeed(ResetFeedEvent event, Emitter<FeedState> emit) async {
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
    add(FeedFetchedEvent(
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
  Future<void> _onFeedFetched(FeedFetchedEvent event, Emitter<FeedState> emit) async {
    // Assert any requirements
    if (event.reset) assert(event.feedType != null);
    if (event.reset && event.feedType == FeedType.community) assert(!(event.communityId == null && event.communityName == null));
    if (event.reset && event.feedType == FeedType.user) assert(event.userId != null && event.username != null);
    if (event.reset && event.feedType == FeedType.general) assert(event.postListingType != null);

    // Handle the initial fetch or reload of a feed
    if (event.reset) {
      if (state.status != FeedStatus.initial) add(ResetFeedEvent());

      GetCommunityResponse? fullCommunityView;

      switch (event.feedType) {
        case FeedType.community:
          // Fetch community information
          try {
            fullCommunityView = await fetchCommunityInformation(id: event.communityId, name: event.communityName);
          } catch (e) {
            // If we are given a community feed, but we can't load the community, that's a problem! Emit an error.
            return emit(state.copyWith(
              status: FeedStatus.failureLoadingCommunity,
              message: getExceptionErrorMessage(e, additionalInfo: event.communityName),
              feedType: event.feedType,
            ));
          }
          break;
        case FeedType.user:
          // Fetch user information
          break;
        case FeedType.general:
          break;
        default:
          break;
      }

      Map<String, dynamic> postViewMediaResult = await fetchPosts(
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

    // If the feed is already being fetched but it is not a reset, then just wait
    if (state.status == FeedStatus.fetching) return;

    // Handle fetching the next page of the feed
    emit(state.copyWith(status: FeedStatus.fetching));

    List<PostViewMedia> postViewMedias = List.from(state.postViewMedias);

    Map<String, dynamic> postViewMediaResult = await fetchPosts(
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

    Set<int> newInsertedPostIds = Set.from(state.insertedPostIds);
    List<PostViewMedia> filteredPostViewMedias = [];

    // Ensure we don't add existing posts to view
    for (PostViewMedia postViewMedia in newPostViewMedias) {
      int id = postViewMedia.postView.post.id;
      if (!newInsertedPostIds.contains(id)) {
        newInsertedPostIds.add(id);
        filteredPostViewMedias.add(postViewMedia);
      }
    }

    postViewMedias.addAll(filteredPostViewMedias);

    return emit(state.copyWith(
      status: FeedStatus.success,
      insertedPostIds: newInsertedPostIds.toList(),
      postViewMedias: postViewMedias,
      hasReachedEnd: hasReachedEnd,
      currentPage: currentPage,
    ));
  }

  /// This function is used to create a post. We can pass in a communityId directly to determine the community to post to.
  Future<void> _onCreatePost(CreatePostEvent event, Emitter<FeedState> emit) async {
    emit(state.copyWith(status: FeedStatus.fetching));

    try {
      PostView postView = await createPost(
        communityId: event.communityId,
        name: event.name,
        body: event.body,
        url: event.url,
        nsfw: event.nsfw,
      );

      // Parse the newly created post
      List<PostViewMedia> formattedPost = await parsePostViews([postView]);

      // Add the post to the state
      List<PostViewMedia> updatedPostViewMedias = List.from(state.postViewMedias);
      updatedPostViewMedias.insert(0, formattedPost[0]);

      emit(state.copyWith(status: FeedStatus.success, postViewMedias: updatedPostViewMedias));
    } catch (e) {
      return emit(state.copyWith(status: FeedStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onPopulatePosts(PopulatePostsEvent event, Emitter<FeedState> emit) async {
    emit(state.copyWith(postViewMedias: event.posts));
  }
}
