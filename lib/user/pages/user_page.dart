import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

import 'package:thunder/account/bloc/account_bloc.dart';
import 'package:thunder/account/utils/profiles.dart';
import 'package:thunder/shared/snackbar.dart';
import 'package:thunder/thunder/bloc/thunder_bloc.dart';
import 'package:thunder/user/pages/user_page_success.dart';
import 'package:thunder/shared/error_message.dart';
import 'package:thunder/user/bloc/user_bloc.dart';
import 'package:thunder/user/pages/user_settings_page.dart';
import 'package:thunder/user/utils/logout_dialog.dart';

class UserPage extends StatefulWidget {
  final int? userId;
  final bool isAccountUser;
  final String? username;

  const UserPage({super.key, this.userId, this.isAccountUser = false, this.username});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  UserBloc? userBloc;

  @override
  Widget build(BuildContext context) {
    final ThunderState state = context.read<ThunderBloc>().state;
    final bool reduceAnimations = state.reduceAnimations;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading: widget.isAccountUser
            ? IconButton(
                onPressed: () => showLogOutDialog(context),
                icon: Icon(
                  Icons.logout,
                  semanticLabel: AppLocalizations.of(context)!.logOut,
                ),
                tooltip: AppLocalizations.of(context)!.logOut,
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 4.0, 0.0, 4.0),
            child: IconButton(
              onPressed: () => userBloc?.add(ResetUserEvent()),
              icon: Icon(
                Icons.refresh_rounded,
                semanticLabel: AppLocalizations.of(context)!.refresh,
              ),
              tooltip: AppLocalizations.of(context)!.refresh,
            ),
          ),
          if (widget.userId != null && widget.isAccountUser)
            Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 4.0, 0, 4.0),
              child: IconButton(
                onPressed: () {
                  final AccountBloc accountBloc = context.read<AccountBloc>();
                  final ThunderBloc thunderBloc = context.read<ThunderBloc>();
                  Navigator.of(context).push(
                    SwipeablePageRoute(
                      transitionDuration: reduceAnimations ? const Duration(milliseconds: 100) : null,
                      canOnlySwipeFromEdge: !state.enableFullScreenSwipeNavigationGesture,
                      builder: (context) => MultiBlocProvider(
                        providers: [
                          BlocProvider.value(value: accountBloc),
                          BlocProvider.value(value: thunderBloc),
                        ],
                        child: UserSettingsPage(widget.userId),
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.settings_rounded,
                  semanticLabel: AppLocalizations.of(context)!.accountSettings,
                ),
                tooltip: AppLocalizations.of(context)!.accountSettings,
              ),
            ),
          if (widget.isAccountUser)
            Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 4.0, 4.0, 4.0),
              child: IconButton(
                onPressed: () => showProfileModalSheet(context),
                icon: Icon(
                  Icons.people_alt_rounded,
                  semanticLabel: AppLocalizations.of(context)!.profiles,
                ),
                tooltip: AppLocalizations.of(context)!.profiles,
              ),
            ),
        ],
      ),
      body: MultiBlocProvider(
        providers: [BlocProvider<UserBloc>(create: (BuildContext context) => UserBloc())],
        child: BlocBuilder<UserBloc, UserState>(builder: (context, state) {
          userBloc = context.read<UserBloc>();

          if (state.status == UserStatus.failedToBlock) {
            showSnackbar(context, state.errorMessage ?? AppLocalizations.of(context)!.missingErrorMessage);
          }

          switch (state.status) {
            case UserStatus.initial:
              context.read<UserBloc>().add(GetUserEvent(userId: widget.userId, isAccountUser: widget.isAccountUser, username: widget.username, reset: true));
              context.read<UserBloc>().add(GetUserSavedEvent(userId: widget.userId, isAccountUser: widget.isAccountUser, reset: true));
              return const Center(child: CircularProgressIndicator());
            case UserStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case UserStatus.refreshing:
            case UserStatus.success:
            case UserStatus.failedToBlock:
              return UserPageSuccess(
                userId: widget.userId,
                isAccountUser: widget.isAccountUser,
                personView: state.personView,
                moderates: state.moderates,
                commentViewTrees: state.comments,
                postViews: state.posts,
                savedPostViews: state.savedPosts,
                savedComments: state.savedComments,
                hasReachedPostEnd: state.hasReachedPostEnd,
                hasReachedSavedPostEnd: state.hasReachedSavedPostEnd,
                blockedPerson: state.blockedPerson,
              );
            case UserStatus.empty:
              return Container();
            case UserStatus.failure:
              return ErrorMessage(
                message: state.errorMessage,
                action: () => context.read<UserBloc>().add(GetUserEvent(userId: widget.userId, reset: true)),
                actionText: 'Refresh Content',
              );
          }
        }),
      ),
    );
  }
}
