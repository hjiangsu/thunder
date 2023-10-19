import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

import 'package:thunder/account/bloc/account_bloc.dart';
import 'package:thunder/community/pages/create_post_page.dart';
import 'package:thunder/core/auth/bloc/auth_bloc.dart';
import 'package:thunder/core/enums/fab_action.dart';
import 'package:thunder/core/enums/local_settings.dart';
import 'package:thunder/core/singletons/preferences.dart';
import 'package:thunder/feed/bloc/feed_bloc.dart';
import 'package:thunder/feed/utils/utils.dart';
import 'package:thunder/feed/view/feed_page.dart';
import 'package:thunder/shared/gesture_fab.dart';
import 'package:thunder/shared/snackbar.dart';
import 'package:thunder/shared/sort_picker.dart';
import 'package:thunder/thunder/bloc/thunder_bloc.dart';
import 'package:thunder/thunder/thunder_icons.dart';

class FeedFAB extends StatelessWidget {
  const FeedFAB({super.key, this.heroTag});

  final String? heroTag;

  @override
  build(BuildContext context) {
    final ThunderState state = context.watch<ThunderBloc>().state;
    final FeedState feedState = context.watch<FeedBloc>().state;

    // A list of actions that are not supported through the general feed
    List<FeedFabAction> unsupportedGeneralFeedFabActions = [];

    // A list of actions that are not supported through the navigated community feed
    List<FeedFabAction> unsupportedNavigatedCommunityFeedFabActions = [
      FeedFabAction.subscriptions,
    ];

    FeedFabAction singlePressAction = state.feedFabSinglePressAction;
    FeedFabAction longPressAction = state.feedFabLongPressAction;

    // Check to see if we are in the general feeds
    bool isGeneralFeed = feedState.status != FeedStatus.initial && feedState.feedType == FeedType.general;
    bool isCommunityFeed = feedState.status != FeedStatus.initial && feedState.feedType == FeedType.community;

    bool isNavigatedFeed = Navigator.canPop(context);

    // Check single-press action
    if (isGeneralFeed && unsupportedGeneralFeedFabActions.contains(singlePressAction)) {
      singlePressAction = FeedFabAction.openFab; // Default to open fab on unsupported actions
    } else if (isCommunityFeed && isNavigatedFeed && unsupportedNavigatedCommunityFeedFabActions.contains(singlePressAction)) {
      singlePressAction = FeedFabAction.openFab; // Default to open fab on unsupported actions
    }

    // Check long-press action
    if (isGeneralFeed && unsupportedGeneralFeedFabActions.contains(longPressAction)) {
      longPressAction = FeedFabAction.openFab; // Default to open fab on unsupported actions
    } else if (isCommunityFeed && isNavigatedFeed && unsupportedNavigatedCommunityFeedFabActions.contains(longPressAction)) {
      longPressAction = FeedFabAction.openFab; // Default to open fab on unsupported actions
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.ease,
      switchOutCurve: Curves.ease,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.2), end: const Offset(0, 0)).animate(animation),
          child: child,
        );
      },
      child: state.isFabSummoned
          ? GestureFab(
              heroTag: heroTag,
              distance: 60,
              icon: Icon(
                singlePressAction.icon,
                semanticLabel: singlePressAction.title,
                size: 35,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();

                switch (singlePressAction) {
                  case FeedFabAction.openFab:
                    triggerOpenFab(context);
                    break;
                  case FeedFabAction.dismissRead:
                    triggerDismissRead(context);
                    break;
                  case FeedFabAction.refresh:
                    triggerRefresh(context);
                    break;
                  case FeedFabAction.changeSort:
                    triggerChangeSort(context);
                    break;
                  case FeedFabAction.subscriptions:
                    triggerOpenDrawer(context);
                    break;
                  case FeedFabAction.backToTop:
                    triggerScrollToTop(context);
                    break;
                  case FeedFabAction.newPost:
                    triggerNewPost(context);
                    break;
                  default:
                    break;
                }
              },
              onLongPress: () {
                HapticFeedback.mediumImpact();

                switch (longPressAction) {
                  case FeedFabAction.openFab:
                    triggerOpenFab(context);
                    break;
                  case FeedFabAction.dismissRead:
                    triggerDismissRead(context);
                    break;
                  case FeedFabAction.refresh:
                    triggerRefresh(context);
                    break;
                  case FeedFabAction.changeSort:
                    triggerChangeSort(context);
                    break;
                  case FeedFabAction.subscriptions:
                    triggerOpenDrawer(context);
                    break;
                  case FeedFabAction.backToTop:
                    triggerScrollToTop(context);
                    break;
                  case FeedFabAction.newPost:
                    triggerNewPost(context);
                    break;
                  default:
                    break;
                }
              },
              children: getEnabledActions(context),
            )
          : Stack(
              // This creates an invisible touch target to summon the FAB
              alignment: AlignmentDirectional.bottomEnd,
              children: [
                SizedBox(
                  width: 75,
                  height: 75,
                  child: GestureDetector(
                    onVerticalDragEnd: (DragEndDetails details) {
                      if (details.primaryVelocity! < 0) {
                        context.read<ThunderBloc>().add(const OnFabSummonToggle(true));
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }

  List<ActionButton> getEnabledActions(BuildContext context) {
    final ThunderState state = context.watch<ThunderBloc>().state;

    bool enableBackToTop = state.enableBackToTop;
    bool enableSubscriptions = state.enableSubscriptions;
    bool enableChangeSort = state.enableChangeSort;
    bool enableRefresh = state.enableRefresh;
    bool enableDismissRead = state.enableDismissRead;
    bool enableNewPost = state.enableNewPost;

    List<ActionButton> actions = [
      if (enableDismissRead)
        ActionButton(
          title: FeedFabAction.dismissRead.title,
          icon: Icon(FeedFabAction.dismissRead.icon),
          onPressed: () {
            HapticFeedback.lightImpact();
            triggerDismissRead(context);
          },
        ),
      if (enableRefresh)
        ActionButton(
          title: FeedFabAction.refresh.title,
          icon: Icon(FeedFabAction.refresh.icon),
          onPressed: () {
            HapticFeedback.lightImpact();
            triggerRefresh(context);
          },
        ),
      if (enableChangeSort)
        ActionButton(
          title: FeedFabAction.changeSort.title,
          icon: Icon(FeedFabAction.changeSort.icon),
          onPressed: () {
            HapticFeedback.lightImpact();
            triggerChangeSort(context);
          },
        ),
      if (enableSubscriptions && Scaffold.maybeOf(context) != null)
        ActionButton(
          title: FeedFabAction.subscriptions.title,
          icon: Icon(FeedFabAction.subscriptions.icon),
          onPressed: () {
            HapticFeedback.lightImpact();
            triggerOpenDrawer(context);
          },
        ),
      if (enableBackToTop)
        ActionButton(
          title: FeedFabAction.backToTop.title,
          icon: Icon(FeedFabAction.backToTop.icon),
          onPressed: () {
            HapticFeedback.lightImpact();
            triggerScrollToTop(context);
          },
        ),
      if (enableNewPost)
        ActionButton(
          title: FeedFabAction.newPost.title,
          icon: Icon(FeedFabAction.newPost.icon),
          onPressed: () {
            HapticFeedback.lightImpact();
            triggerNewPost(context);
          },
        ),
    ];

    return actions;
  }

  Future<void> triggerOpenFab(BuildContext context) async {
    context.read<ThunderBloc>().add(const OnFabToggle(true));
  }

  Future<void> triggerDismissRead(BuildContext context) async {
    context.read<FeedBloc>().add(FeedDismissReadEvent());
  }

  Future<void> triggerChangeSort(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet<void>(
      showDragHandle: true,
      context: context,
      isScrollControlled: true,
      builder: (builderContext) => SortPicker(
        title: l10n.sortOptions,
        onSelect: (selected) => context.read<FeedBloc>().add(FeedChangeSortTypeEvent(selected.payload)),
        previouslySelected: context.read<FeedBloc>().state.sortType,
      ),
    );
  }

  Future<void> triggerOpenDrawer(BuildContext context) async {
    Scaffold.of(context).openDrawer();
  }

  Future<void> triggerScrollToTop(BuildContext context) async {
    context.read<FeedBloc>().add(ScrollToTopEvent());
  }

  Future<void> triggerNewPost(BuildContext context) async {
    FeedBloc feedBloc = context.read<FeedBloc>();

    if (!context.read<AuthBloc>().state.isLoggedIn) {
      showSnackbar(context, AppLocalizations.of(context)!.mustBeLoggedInPost);
    } else {
      ThunderBloc thunderBloc = context.read<ThunderBloc>();
      AccountBloc accountBloc = context.read<AccountBloc>();

      final ThunderState thunderState = context.read<ThunderBloc>().state;
      final bool reduceAnimations = thunderState.reduceAnimations;

      SharedPreferences prefs = (await UserPreferences.instance).sharedPreferences;
      DraftPost? newDraftPost;
      DraftPost? previousDraftPost;
      String draftId = '${LocalSettings.draftsCache.name}-${feedBloc.state.communityId}';
      String? draftPostJson = prefs.getString(draftId);
      if (draftPostJson != null) {
        previousDraftPost = DraftPost.fromJson(jsonDecode(draftPostJson));
      }
      Timer timer = Timer.periodic(const Duration(seconds: 10), (Timer t) {
        if (newDraftPost?.isNotEmpty == true) {
          prefs.setString(draftId, jsonEncode(newDraftPost!.toJson()));
        }
      });

      Navigator.of(context)
          .push(
        SwipeablePageRoute(
          transitionDuration: reduceAnimations ? const Duration(milliseconds: 100) : null,
          canOnlySwipeFromEdge: true,
          backGestureDetectionWidth: 45,
          builder: (context) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<FeedBloc>.value(value: feedBloc),
                BlocProvider<ThunderBloc>.value(value: thunderBloc),
                BlocProvider<AccountBloc>.value(value: accountBloc),
              ],
              child: CreatePostPage(
                communityId: feedBloc.state.communityId,
                communityView: feedBloc.state.fullCommunityView?.communityView,
                previousDraftPost: previousDraftPost,
                onUpdateDraft: (p) => newDraftPost = p,
              ),
            );
          },
        ),
      )
          .whenComplete(() async {
        timer.cancel();

        if (newDraftPost?.saveAsDraft == true && newDraftPost?.isNotEmpty == true) {
          await Future.delayed(const Duration(milliseconds: 300));
          showSnackbar(context, AppLocalizations.of(context)!.postSavedAsDraft);
          prefs.setString(draftId, jsonEncode(newDraftPost!.toJson()));
        } else {
          prefs.remove(draftId);
        }
      });
    }
  }
}
