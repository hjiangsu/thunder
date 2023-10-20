import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';
import 'package:thunder/account/bloc/account_bloc.dart';
import 'package:thunder/community/bloc/anonymous_subscriptions_bloc.dart';
import 'package:thunder/community/bloc/community_bloc.dart';
import 'package:thunder/core/auth/bloc/auth_bloc.dart';
import 'package:thunder/core/models/post_view_media.dart';
import 'package:thunder/feed/bloc/feed_bloc.dart';
import 'package:thunder/post/enums/post_action.dart';
import 'package:thunder/post/pages/post_page.dart';
import 'package:thunder/thunder/bloc/thunder_bloc.dart';
import 'package:thunder/utils/swipe.dart';
import 'package:thunder/post/bloc/post_bloc.dart' as post_bloc;

Future<void> navigateToPost(BuildContext context, {PostViewMedia? postViewMedia, int? selectedCommentId, String? selectedCommentPath, int? postId, Function(PostViewMedia)? onPostUpdated}) async {
  AccountBloc accountBloc = context.read<AccountBloc>();
  AuthBloc authBloc = context.read<AuthBloc>();
  ThunderBloc thunderBloc = context.read<ThunderBloc>();

  CommunityBloc? communityBloc;
  try {
    communityBloc = context.read<CommunityBloc>();
  } catch (e) {}

  AnonymousSubscriptionsBloc? anonymousSubscriptionsBloc;
  try {
    anonymousSubscriptionsBloc = context.read<AnonymousSubscriptionsBloc>();
  } catch (e) {}

  FeedBloc? feedBloc;
  try {
    feedBloc = context.read<FeedBloc>();
  } catch (e) {
    // Don't need feed block if we're not opening post in the context of a feed.
  }

  final ThunderState state = context.read<ThunderBloc>().state;
  final bool reduceAnimations = state.reduceAnimations;

  // Mark post as read when tapped
  if (authBloc.state.isLoggedIn) {
    int? _postId;
    _postId = postViewMedia?.postView.post.id ?? postId;

    feedBloc?.add(FeedItemActionedEvent(postId: _postId, postAction: PostAction.read, value: true));
  }

  await Navigator.of(context).push(
    SwipeablePageRoute(
      transitionDuration: reduceAnimations ? const Duration(milliseconds: 100) : null,
      backGestureDetectionStartOffset: Platform.isAndroid ? 45 : 0,
      backGestureDetectionWidth: 45,
      canOnlySwipeFromEdge: disableFullPageSwipe(isUserLoggedIn: authBloc.state.isLoggedIn, state: thunderBloc.state, isPostPage: true) || !thunderBloc.state.enableFullScreenSwipeNavigationGesture,
      builder: (otherContext) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: accountBloc),
            BlocProvider.value(value: authBloc),
            BlocProvider.value(value: thunderBloc),
            BlocProvider(create: (context) => post_bloc.PostBloc()),
            if (communityBloc != null) BlocProvider.value(value: communityBloc),
            if (anonymousSubscriptionsBloc != null) BlocProvider.value(value: anonymousSubscriptionsBloc),
          ],
          child: PostPage(
            postView: postViewMedia,
            postId: postId,
            selectedCommentId: selectedCommentId,
            selectedCommentPath: selectedCommentPath,
            onPostUpdated: (PostViewMedia postViewMedia) {
              FeedBloc? feedBloc;
              try {
                feedBloc = context.read<FeedBloc>();
              } catch (e) {}
              feedBloc?.add(FeedItemUpdatedEvent(postViewMedia: postViewMedia));
            },
          ),
        );
      },
    ),
  );
}
