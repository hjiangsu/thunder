import 'dart:async';

// Flutter
import 'package:flutter/material.dart';

// Packages
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:lemmy_api_client/v3.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:thunder/account/models/account.dart';
import 'package:thunder/account/utils/profiles.dart';
import 'package:thunder/community/bloc/community_bloc.dart';
import 'package:thunder/community/widgets/community_drawer.dart';
import 'package:thunder/core/auth/helpers/fetch_account.dart';

// Internal
import 'package:thunder/core/singletons/lemmy_client.dart';
import 'package:thunder/feed/bloc/feed_bloc.dart';
import 'package:thunder/feed/view/feed_page.dart';
import 'package:thunder/feed/widgets/feed_fab.dart';
import 'package:thunder/shared/snackbar.dart';
import 'package:thunder/thunder/cubits/deep_links_cubit/deep_links_cubit.dart';
import 'package:thunder/thunder/enums/deep_link_enums.dart';
import 'package:thunder/thunder/widgets/bottom_nav_bar.dart';
import 'package:thunder/utils/instance.dart';
import 'package:thunder/utils/links.dart';
import 'package:thunder/community/bloc/anonymous_subscriptions_bloc.dart';
import 'package:thunder/inbox/bloc/inbox_bloc.dart';
import 'package:thunder/inbox/inbox.dart';
import 'package:thunder/search/bloc/search_bloc.dart';
import 'package:thunder/account/account.dart';
import 'package:thunder/account/bloc/account_bloc.dart';
import 'package:thunder/core/auth/bloc/auth_bloc.dart';
import 'package:thunder/core/models/version.dart';
import 'package:thunder/search/pages/search_page.dart';
import 'package:thunder/settings/pages/settings_page.dart';
import 'package:thunder/shared/error_message.dart';
import 'package:thunder/thunder/bloc/thunder_bloc.dart';
import 'package:thunder/utils/navigate_comment.dart';
import 'package:thunder/utils/navigate_post.dart';
import 'package:thunder/utils/navigate_user.dart';

class Thunder extends StatefulWidget {
  const Thunder({super.key});

  @override
  State<Thunder> createState() => _ThunderState();
}

class _ThunderState extends State<Thunder> {
  int selectedPageIndex = 0;
  int appExitCounter = 0;

  PageController pageController = PageController(initialPage: 0);

  bool hasShownUpdateDialog = false;

  bool _isFabOpen = false;

  bool reduceAnimations = false;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      BlocProvider.of<DeepLinksCubit>(context).handleIncomingLinks();
      BlocProvider.of<DeepLinksCubit>(context).handleInitialURI();
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _showExitWarning() {
    showSnackbar(context, AppLocalizations.of(context)!.tapToExit, duration: const Duration(milliseconds: 3500));
  }

  Future<bool> _handleBackButtonPress() async {
    if (selectedPageIndex != 0) {
      setState(() {
        selectedPageIndex = 0;

        if (reduceAnimations) {
          pageController.jumpToPage(selectedPageIndex);
        } else {
          pageController.animateToPage(selectedPageIndex, duration: const Duration(milliseconds: 500), curve: Curves.ease);
        }
      });
      return Future.value(false);
    }

    if (_isFabOpen == true) {
      return Future.value(false);
    }

    if (appExitCounter == 0) {
      appExitCounter++;
      _showExitWarning();
      Timer(const Duration(milliseconds: 3500), () {
        appExitCounter = 0;
      });
      return Future.value(false);
    } else {
      return Future.value(true);
    }
  }

  Future<void> _handleDeepLinkNavigation(
    BuildContext context, {
    required LinkType linkType,
    String? link,
  }) async {
    switch (linkType) {
      case LinkType.comment:
        if (context.mounted) _navigateToComment(link!);

      case LinkType.user:
        String? username = await getLemmyUser(link!);
        if (username != null) if (context.mounted) await navigateToUserPage(context, username: username);

      case LinkType.post:
        final postId = await getLemmyPostId(link!);
        if (context.mounted) await navigateToPost(context, postId: postId);
      case LinkType.unknown:
        if (context.mounted) {
          final ThunderState state = context.read<ThunderBloc>().state;
          bool openInExternalBrowser = state.openInExternalBrowser;
          showSnackbar(context, AppLocalizations.of(context)!.uriNotSupported,
              trailingIcon: Icons.arrow_forward_ios,
              duration: const Duration(seconds: 10),
              clearSnackBars: false,
              trailingAction: () => openLink(
                    context,
                    url: link!,
                    openInExternalBrowser: openInExternalBrowser,
                  ));
        }
    }
  }

  Future<void> _navigateToComment(String link) async {
    final commentId = await getLemmyCommentId(link);
    if (context.mounted) {
      final ThunderState state = context.read<ThunderBloc>().state;
      final openInExternalBrowser = state.openInExternalBrowser;
      if (commentId != null) {
        LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;
        Account? account = await fetchActiveProfileAccount();

        try {
          FullCommentView fullCommentView = await lemmy.run(GetComment(
            id: commentId,
            auth: account?.jwt,
          ));
          if (context.mounted) navigateToComment(context, fullCommentView.commentView);
          return;
        } catch (e) {
          // Ignore exception, if it's not a valid comment, we'll perform the next fallback
        }
      } else {
        // commentId not found or could not resolve link.
        // show a snackbar with option to open link

        showSnackbar(context, AppLocalizations.of(context)!.exceptionProcessingUri,
            clearSnackBars: false,
            duration: const Duration(seconds: 10),
            trailingIcon: Icons.arrow_forward_ios,
            trailingAction: () => openLink(
                  context,
                  url: link,
                  openInExternalBrowser: openInExternalBrowser,
                ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => InboxBloc()),
        BlocProvider(create: (context) => SearchBloc()),
        BlocProvider(create: (context) => AnonymousSubscriptionsBloc()),
        BlocProvider(create: (context) => FeedBloc(lemmyClient: LemmyClient.instance)),
        BlocProvider(create: (context) => CommunityBloc(lemmyClient: LemmyClient.instance)),
      ],
      child: WillPopScope(
        onWillPop: () async => _handleBackButtonPress(),
        child: BlocListener<DeepLinksCubit, DeepLinksState>(
          listener: (context, state) {
            switch (state.deepLinkStatus) {
              case DeepLinkStatus.loading:
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(content: CircularProgressIndicator.adaptive()),
                  );
                });

              case DeepLinkStatus.empty:
                showSnackbar(context, state.error ?? l10n.emptyUri);
              case DeepLinkStatus.error:
                showSnackbar(context, state.error ?? l10n.exceptionProcessingUri);

              case DeepLinkStatus.success:
                _handleDeepLinkNavigation(context, linkType: state.linkType, link: state.link);

              case DeepLinkStatus.unknown:
                showSnackbar(context, state.error ?? l10n.uriNotSupported);
            }
          },
          child: BlocBuilder<ThunderBloc, ThunderState>(
            builder: (context, thunderBlocState) {
              reduceAnimations = thunderBlocState.reduceAnimations;

              switch (thunderBlocState.status) {
                case ThunderStatus.initial:
                  context.read<ThunderBloc>().add(InitializeAppEvent());
                  return Container();
                case ThunderStatus.loading:
                  return Container();
                case ThunderStatus.refreshing:
                case ThunderStatus.success:
                  FlutterNativeSplash.remove();

                  // Update the variable so that it can be used in _handleBackButtonPress
                  _isFabOpen = thunderBlocState.isFabOpen;

                  return Scaffold(
                    key: scaffoldMessengerKey,
                    drawer: selectedPageIndex == 0 ? const CommunityDrawer() : null,
                    floatingActionButton: thunderBlocState.enableFeedsFab
                        ? AnimatedOpacity(
                            opacity: selectedPageIndex == 0 ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeIn,
                            child: const FeedFAB(),
                          )
                        : null,
                    floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
                    bottomNavigationBar: CustomBottomNavigationBar(
                      selectedPageIndex: selectedPageIndex,
                      onPageChange: (int index) {
                        setState(() {
                          selectedPageIndex = index;

                          if (reduceAnimations) {
                            pageController.jumpToPage(index);
                          } else {
                            pageController.animateToPage(index, duration: const Duration(milliseconds: 500), curve: Curves.ease);
                          }
                        });
                      },
                    ),
                    body: BlocConsumer<AuthBloc, AuthState>(
                      listenWhen: (AuthState previous, AuthState current) {
                        if (previous.isLoggedIn != current.isLoggedIn || previous.status == AuthStatus.initial) return true;
                        return false;
                      },
                      buildWhen: (previous, current) => current.status != AuthStatus.failure && current.status != AuthStatus.loading,
                      listener: (context, state) {
                        context.read<AccountBloc>().add(GetAccountInformation());

                        // Add a bit of artificial delay to allow preferences to set the proper active profile
                        Future.delayed(const Duration(milliseconds: 500), () => context.read<InboxBloc>().add(const GetInboxEvent(reset: true)));
                        context.read<FeedBloc>().add(
                              FeedFetchedEvent(
                                feedType: FeedType.general,
                                postListingType: thunderBlocState.defaultPostListingType,
                                sortType: thunderBlocState.defaultSortType,
                                reset: true,
                              ),
                            );
                      },
                      builder: (context, state) {
                        switch (state.status) {
                          case AuthStatus.initial:
                            context.read<AuthBloc>().add(CheckAuth());
                            return Container();
                          case AuthStatus.success:
                            Version? version = thunderBlocState.version;
                            bool showInAppUpdateNotification = thunderBlocState.showInAppUpdateNotification;

                            if (version?.hasUpdate == true && hasShownUpdateDialog == false && showInAppUpdateNotification == true) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                showUpdateNotification(context, version);
                                setState(() => hasShownUpdateDialog = true);
                              });
                            }

                            return PageView(
                              controller: pageController,
                              onPageChanged: (index) => setState(() => selectedPageIndex = index),
                              physics: const NeverScrollableScrollPhysics(),
                              children: <Widget>[
                                Stack(
                                  children: [
                                    FeedPage(useGlobalFeedBloc: true, feedType: FeedType.general, postListingType: thunderBlocState.defaultPostListingType, sortType: thunderBlocState.defaultSortType),
                                    AnimatedOpacity(
                                      opacity: _isFabOpen ? 1.0 : 0.0,
                                      duration: const Duration(milliseconds: 150),
                                      child: _isFabOpen
                                          ? ModalBarrier(
                                              color: theme.colorScheme.background.withOpacity(0.95),
                                              dismissible: true,
                                              onDismiss: () => context.read<ThunderBloc>().add(const OnFabToggle(false)),
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                                const SearchPage(),
                                const AccountPage(),
                                const InboxPage(),
                                SettingsPage(),
                              ],
                            );

                          // Should never hit these, they're handled by the login page
                          case AuthStatus.failure:
                          case AuthStatus.loading:
                            return Container();
                          case AuthStatus.failureCheckingInstance:
                            showSnackbar(context, state.errorMessage ?? AppLocalizations.of(context)!.missingErrorMessage);
                            return ErrorMessage(
                              title: AppLocalizations.of(context)!.unableToLoadInstance(LemmyClient.instance.lemmyApiV3.host),
                              message: AppLocalizations.of(context)!.internetOrInstanceIssues,
                              actionText: AppLocalizations.of(context)!.accountSettings,
                              action: () => showProfileModalSheet(context),
                            );
                        }
                      },
                    ),
                  );
                case ThunderStatus.failure:
                  return ErrorMessage(
                    message: thunderBlocState.errorMessage,
                    action: () => {context.read<AuthBloc>().add(CheckAuth())},
                    actionText: AppLocalizations.of(context)!.refreshContent,
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  // Update notification
  void showUpdateNotification(BuildContext context, Version? version) {
    final theme = Theme.of(context);

    final ThunderState state = context.read<ThunderBloc>().state;
    final bool openInExternalBrowser = state.openInExternalBrowser;

    showSimpleNotification(
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.updateReleased(version?.latestVersion ?? ''),
              style: theme.textTheme.titleMedium,
            ),
            Icon(
              Icons.arrow_forward,
              color: theme.colorScheme.onBackground,
            ),
          ],
        ),
        onTap: () {
          openLink(context, url: version?.latestVersionUrl ?? 'https://github.com/thunder-app/thunder/releases', openInExternalBrowser: openInExternalBrowser);
        },
      ),
      background: theme.cardColor,
      autoDismiss: true,
      duration: const Duration(seconds: 5),
      slideDismissDirection: DismissDirection.vertical,
    );
  }
}
