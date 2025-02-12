import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lemmy_api_client/v3.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

import 'package:thunder/account/bloc/account_bloc.dart';
import 'package:thunder/community/bloc/anonymous_subscriptions_bloc.dart';
import 'package:thunder/community/bloc/community_bloc.dart';
import 'package:thunder/core/auth/bloc/auth_bloc.dart';
import 'package:thunder/feed/feed.dart';
import 'package:thunder/instance/bloc/instance_bloc.dart';
import 'package:thunder/shared/pages/loading_page.dart';
import 'package:thunder/shared/sort_picker.dart';
import 'package:thunder/community/widgets/community_drawer.dart';
import 'package:thunder/thunder/bloc/thunder_bloc.dart';
import 'package:thunder/utils/swipe.dart';

String getAppBarTitle(FeedState state) {
  if (state.status == FeedStatus.initial) {
    return '';
  }

  if (state.communityId != null || state.communityName != null) {
    return state.fullCommunityView?.communityView.community.title ?? '';
  }

  if (state.userId != null || state.username != null) {
    return state.fullPersonView?.personView.person.displayName ?? state.fullPersonView?.personView.person.name ?? '';
  }

  return (state.postListingType != null) ? (destinations.firstWhere((destination) => destination.listingType == state.postListingType).label) : '';
}

String getSortName(FeedState state) {
  if (state.status == FeedStatus.initial) {
    return '';
  }

  final sortTypeItemIndex = allSortTypeItems.indexWhere((sortTypeItem) => sortTypeItem.payload == state.sortType);
  final sortTypeItem = sortTypeItemIndex > -1 ? allSortTypeItems[sortTypeItemIndex] : null;

  return sortTypeItem?.label ?? '';
}

IconData? getSortIcon(FeedState state) {
  if (state.status == FeedStatus.initial) {
    return null;
  }

  final sortTypeItemIndex = allSortTypeItems.indexWhere((sortTypeItem) => sortTypeItem.payload == state.sortType);
  final sortTypeItem = sortTypeItemIndex > -1 ? allSortTypeItems[sortTypeItemIndex] : null;

  return sortTypeItem?.icon;
}

/// Navigates to a [FeedPage] with the given parameters
///
/// [feedType] must be provided.
/// If [feedType] is [FeedType.general], [postListingType] must be provided
/// If [feedType] is [FeedType.community], one of [communityId] or [communityName] must be provided
/// If [feedType] is [FeedType.user], one of [userId] or [username] must be provided
///
/// The [context] parameter should contain the following blocs within its widget tree: [AccountBloc], [AuthBloc], [ThunderBloc]
Future<void> navigateToFeedPage(
  BuildContext context, {
  required FeedType feedType,
  ListingType? postListingType,
  SortType? sortType,
  String? communityName,
  int? communityId,
  String? username,
  int? userId,
}) async {
  // Push navigation
  AccountBloc accountBloc = context.read<AccountBloc>();
  AuthBloc authBloc = context.read<AuthBloc>();
  ThunderBloc thunderBloc = context.read<ThunderBloc>();
  CommunityBloc communityBloc = context.read<CommunityBloc>();
  InstanceBloc instanceBloc = context.read<InstanceBloc>();
  AnonymousSubscriptionsBloc anonymousSubscriptionsBloc = context.read<AnonymousSubscriptionsBloc>();

  ThunderState thunderState = thunderBloc.state;
  final bool reduceAnimations = thunderState.reduceAnimations;

  if (feedType == FeedType.general) {
    return context.read<FeedBloc>().add(
          FeedFetchedEvent(
            feedType: feedType,
            postListingType: postListingType,
            sortType: sortType ?? authBloc.state.getSiteResponse?.myUser?.localUserView.localUser.defaultSortType ?? thunderBloc.state.sortTypeForInstance,
            communityId: communityId,
            communityName: communityName,
            userId: userId,
            username: username,
            reset: true,
            showHidden: thunderBloc.state.showHiddenPosts,
          ),
        );
  }

  SwipeablePageRoute route = SwipeablePageRoute(
    transitionDuration: isLoadingPageShown
        ? Duration.zero
        : reduceAnimations
            ? const Duration(milliseconds: 100)
            : null,
    reverseTransitionDuration: reduceAnimations ? const Duration(milliseconds: 100) : const Duration(milliseconds: 500),
    backGestureDetectionWidth: 45,
    canSwipe: Platform.isIOS || thunderState.enableFullScreenSwipeNavigationGesture,
    canOnlySwipeFromEdge: disableFullPageSwipe(isUserLoggedIn: authBloc.state.isLoggedIn, state: thunderBloc.state, isFeedPage: true) || !thunderState.enableFullScreenSwipeNavigationGesture,
    builder: (context) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: accountBloc),
        BlocProvider.value(value: authBloc),
        BlocProvider.value(value: thunderBloc),
        BlocProvider.value(value: instanceBloc),
        BlocProvider.value(value: anonymousSubscriptionsBloc),
        BlocProvider.value(value: communityBloc),
      ],
      child: Material(
        child: FeedPage(
          feedType: feedType,
          sortType: sortType ?? authBloc.state.getSiteResponse?.myUser?.localUserView.localUser.defaultSortType ?? thunderBloc.state.sortTypeForInstance,
          communityName: communityName,
          communityId: communityId,
          userId: userId,
          username: username,
          postListingType: postListingType,
          showHidden: thunderBloc.state.showHiddenPosts,
        ),
      ),
    ),
  );

  pushOnTopOfLoadingPage(context, route);
}

Future<void> triggerRefresh(BuildContext context) async {
  FeedState state = context.read<FeedBloc>().state;

  context.read<FeedBloc>().add(
        FeedFetchedEvent(
          feedType: state.feedType,
          postListingType: state.postListingType,
          sortType: state.sortType,
          communityId: state.communityId,
          communityName: state.communityName,
          userId: state.userId,
          username: state.username,
          reset: true,
          showHidden: state.showHidden,
          showSaved: state.showSaved,
        ),
      );
}
