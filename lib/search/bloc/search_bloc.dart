import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:lemmy_api_client/v3.dart';

import 'package:stream_transform/stream_transform.dart';

import 'package:thunder/account/models/account.dart';
import 'package:thunder/core/auth/helpers/fetch_account.dart';

import 'package:thunder/core/singletons/lemmy_client.dart';
import 'package:thunder/utils/instance.dart';

part 'search_event.dart';
part 'search_state.dart';

const throttleDuration = Duration(milliseconds: 300);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) => droppable<E>().call(events.throttle(duration), mapper);
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(SearchState()) {
    on<StartSearchEvent>(
      _startSearchEvent,
      transformer: throttleDroppable(throttleDuration),
    );
    on<ChangeCommunitySubsciptionStatusEvent>(
      _changeCommunitySubsciptionStatusEvent,
      transformer: throttleDroppable(throttleDuration),
    );
    on<ResetSearch>(
      _resetSearch,
      transformer: throttleDroppable(throttleDuration),
    );
    on<ContinueSearchEvent>(
      _continueSearchEvent,
      transformer: throttleDroppable(throttleDuration),
    );
    on<FocusSearchEvent>(
      _focusSearchEvent,
      transformer: throttleDroppable(throttleDuration),
    );
    on<GetTrendingCommunitiesEvent>(
      _getTrendingCommunitiesEvent,
      transformer: throttleDroppable(throttleDuration),
    );
  }

  Future<void> _resetSearch(ResetSearch event, Emitter<SearchState> emit) async {
    emit(state.copyWith(status: SearchStatus.initial, trendingCommunities: []));
    await _getTrendingCommunitiesEvent(GetTrendingCommunitiesEvent(), emit);
  }

  Future<void> _startSearchEvent(StartSearchEvent event, Emitter<SearchState> emit) async {
    try {
      emit(state.copyWith(status: SearchStatus.loading));

      Account? account = await fetchActiveProfileAccount();
      LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

      SearchResults searchResponse = await lemmy.run(Search(
        auth: account?.jwt,
        q: event.query,
        page: 1,
        limit: 15,
        sort: event.sortType,
      ));

      // If there are no search results, see if this is an exact search
      if (searchResponse.communities.isEmpty) {
        // Note: We could jump straight to GetCommunity here.
        // However, getLemmyCommunity has a nice instance check that can short-circuit things
        // if the instance is not valid to start.
        String? communityName = await getLemmyCommunity(event.query);
        if (communityName != null) {
          try {
            Account? account = await fetchActiveProfileAccount();

            final getCommunityResponse = await LemmyClient.instance.lemmyApiV3.run(GetCommunity(
              name: communityName,
              auth: account?.jwt,
            ));

            searchResponse = searchResponse.copyWith(communities: [getCommunityResponse.communityView]);
          } catch (e) {
            // Ignore any exceptions here and return an empty response below
          }
        }
      }

      return emit(state.copyWith(status: SearchStatus.success, communities: searchResponse.communities, page: 2));
    } catch (e) {
      return emit(state.copyWith(status: SearchStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _continueSearchEvent(ContinueSearchEvent event, Emitter<SearchState> emit) async {
    int attemptCount = 0;

    try {
      Object exception;

      while (attemptCount < 2) {
        try {
          emit(state.copyWith(status: SearchStatus.refreshing, communities: state.communities));

          Account? account = await fetchActiveProfileAccount();
          LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

          SearchResults searchResponse = await lemmy.run(Search(
            auth: account?.jwt,
            q: event.query,
            page: state.page,
            limit: 15,
            sort: event.sortType,
          ));

          if (searchResponse.communities.isEmpty) {
            return emit(state.copyWith(status: SearchStatus.done));
          }

          // Append the search results
          state.communities = [...state.communities ?? [], ...searchResponse.communities];

          return emit(state.copyWith(status: SearchStatus.success, communities: state.communities, page: state.page + 1));
        } catch (e) {
          exception = e;
          attemptCount++;
        }
      }
    } catch (e) {
      return emit(state.copyWith(status: SearchStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _focusSearchEvent(FocusSearchEvent event, Emitter<SearchState> emit) async {
    emit(state.copyWith(focusSearchId: state.focusSearchId + 1));
  }

  Future<void> _changeCommunitySubsciptionStatusEvent(ChangeCommunitySubsciptionStatusEvent event, Emitter<SearchState> emit) async {
    try {
      if (event.query.isNotEmpty) {
        emit(state.copyWith(status: SearchStatus.refreshing, communities: state.communities));
      }

      Account? account = await fetchActiveProfileAccount();
      LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

      if (account?.jwt == null) return;

      CommunityView communityResponse = await lemmy.run(FollowCommunity(
        auth: account!.jwt!,
        communityId: event.communityId,
        follow: event.follow,
      ));

      // Refetch the status of the community - communityResponse does not return back with the proper subscription status
      FullCommunityView fullCommunityView = await lemmy.run(GetCommunity(
        auth: account.jwt,
        id: event.communityId,
      ));

      List<CommunityView> communities;
      if (event.query.isNotEmpty) {
        communities = state.communities ?? [];

        communities = state.communities?.map((CommunityView communityView) {
              if (communityView.community.id == fullCommunityView.communityView.community.id) {
                return fullCommunityView.communityView;
              }
              return communityView;
            }).toList() ??
            [];

        emit(state.copyWith(status: SearchStatus.success, communities: communities));
      } else {
        communities = state.trendingCommunities ?? [];

        communities = state.trendingCommunities?.map((CommunityView communityView) {
              if (communityView.community.id == fullCommunityView.communityView.community.id) {
                return fullCommunityView.communityView;
              }
              return communityView;
            }).toList() ??
            [];

        emit(state.copyWith(status: SearchStatus.trending, trendingCommunities: communities));
      }

      // Delay a bit then refetch the status of the community again for a better chance of getting the right subscribed type
      await Future.delayed(const Duration(seconds: 1));

      fullCommunityView = await lemmy.run(GetCommunity(
        auth: account.jwt,
        id: event.communityId,
      ));

      if (event.query.isNotEmpty) {
        communities = state.communities ?? [];

        communities = state.communities?.map((CommunityView communityView) {
              if (communityView.community.id == fullCommunityView.communityView.community.id) {
                return fullCommunityView.communityView;
              }
              return communityView;
            }).toList() ??
            [];

        return emit(state.copyWith(status: event.query.isNotEmpty ? SearchStatus.success : SearchStatus.trending, communities: communities));
      } else {
        communities = state.trendingCommunities ?? [];

        communities = state.trendingCommunities?.map((CommunityView communityView) {
              if (communityView.community.id == fullCommunityView.communityView.community.id) {
                return fullCommunityView.communityView;
              }
              return communityView;
            }).toList() ??
            [];

        return emit(state.copyWith(status: SearchStatus.trending, trendingCommunities: communities));
      }
    } catch (e) {
      return emit(state.copyWith(status: SearchStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _getTrendingCommunitiesEvent(GetTrendingCommunitiesEvent event, Emitter<SearchState> emit) async {
    try {
      LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;
      Account? account = await fetchActiveProfileAccount();

      List<CommunityView> trendingCommunities = await lemmy.run(ListCommunities(
        type: PostListingType.local,
        sort: SortType.active,
        limit: 5,
        auth: account?.jwt,
      ));

      return emit(state.copyWith(status: SearchStatus.trending, trendingCommunities: trendingCommunities));
    } catch (e) {
      // Not the end of the world if we can't load trending
    }
  }
}
