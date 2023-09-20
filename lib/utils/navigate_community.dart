import 'package:flutter/material.dart';

import 'package:lemmy_api_client/v3.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

import 'package:thunder/account/models/account.dart';
import 'package:thunder/community/pages/community_page.dart';
import 'package:thunder/core/auth/helpers/fetch_account.dart';
import 'package:thunder/core/singletons/lemmy_client.dart';
import 'package:thunder/account/bloc/account_bloc.dart';
import 'package:thunder/core/auth/bloc/auth_bloc.dart';
import 'package:thunder/feed/feed.dart';
import 'package:thunder/thunder/bloc/thunder_bloc.dart';
import 'package:thunder/utils/swipe.dart';

/// Navigates to a [CommunityPage] with a given [communityName] or [communityId]
///
/// Note: only one of [communityName] or [communityId] should be provided
/// If both are provided, the [communityId] will take precedence
///
/// The [context] parameter should contain the following blocs within its widget tree: [AccountBloc], [AuthBloc], [ThunderBloc]
Future<void> navigateToCommunityPage(BuildContext context, {String? communityName, int? communityId}) async {
  if (communityName == null && communityId == null) return; // Return early since there's nothing to do

  // Push navigation
  AccountBloc accountBloc = context.read<AccountBloc>();
  AuthBloc authBloc = context.read<AuthBloc>();
  ThunderBloc thunderBloc = context.read<ThunderBloc>();

  ThunderState thunderState = thunderBloc.state;
  final bool reduceAnimations = thunderState.reduceAnimations;

  Navigator.of(context).push(
    SwipeablePageRoute(
      transitionDuration: reduceAnimations ? const Duration(milliseconds: 100) : null,
      backGestureDetectionWidth: 45,
      canOnlySwipeFromEdge: disableFullPageSwipe(isUserLoggedIn: authBloc.state.isLoggedIn, state: thunderBloc.state, isFeedPage: true),
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: accountBloc),
          BlocProvider.value(value: authBloc),
          BlocProvider.value(value: thunderBloc),
        ],
        child: Material(child: FeedPage(feedType: FeedType.community, sortType: SortType.active, communityName: communityName, communityId: communityId)),
      ),
    ),
  );
}
