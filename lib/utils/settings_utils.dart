import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';
import 'package:thunder/account/bloc/account_bloc.dart';
import 'package:thunder/core/auth/bloc/auth_bloc.dart';
import 'package:thunder/core/enums/local_settings.dart';
import 'package:thunder/settings/pages/about_settings_page.dart';
import 'package:thunder/settings/pages/accessibility_settings_page.dart';
import 'package:thunder/settings/pages/appearance_settings_page.dart';
import 'package:thunder/settings/pages/comment_appearance_settings_page.dart';
import 'package:thunder/settings/pages/debug_settings_page.dart';
import 'package:thunder/settings/pages/filter_settings_page.dart';
import 'package:thunder/settings/pages/general_settings_page.dart';
import 'package:thunder/settings/pages/gesture_settings_page.dart';
import 'package:thunder/settings/pages/post_appearance_settings_page.dart';
import 'package:thunder/settings/pages/theme_settings_page.dart';
import 'package:thunder/settings/pages/user_labels_settings_page.dart';
import 'package:thunder/settings/pages/video_player_settings.dart';
import 'package:thunder/shared/snackbar.dart';
import 'package:thunder/thunder/bloc/thunder_bloc.dart';
import 'package:thunder/user/bloc/user_settings_bloc.dart';
import 'package:thunder/user/pages/user_settings_page.dart';
import 'package:thunder/utils/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void navigateToSetting(BuildContext context, LocalSettings setting) {
  String pageToNav = {
        LocalSettingsCategories.posts: SETTINGS_APPEARANCE_POSTS_PAGE,
        LocalSettingsCategories.comments: SETTINGS_APPEARANCE_COMMENTS_PAGE,
        LocalSettingsCategories.general: SETTINGS_GENERAL_PAGE,
        LocalSettingsCategories.gestures: SETTINGS_GESTURES_PAGE,
        LocalSettingsCategories.floatingActionButton: SETTINGS_FAB_PAGE,
        LocalSettingsCategories.filters: SETTINGS_FILTERS_PAGE,
        LocalSettingsCategories.accessibility: SETTINGS_ACCESSIBILITY_PAGE,
        LocalSettingsCategories.account: SETTINGS_ACCOUNT_PAGE,
        LocalSettingsCategories.userLabels: SETTINGS_USER_LABELS_PAGE,
        LocalSettingsCategories.theming: SETTINGS_APPEARANCE_THEMES_PAGE,
        LocalSettingsCategories.debug: SETTINGS_DEBUG_PAGE,
        LocalSettingsCategories.about: SETTINGS_ABOUT_PAGE,
        LocalSettingsCategories.videoPlayer: SETTINGS_VIDEO_PAGE,
        LocalSettingsCategories.appearance: SETTINGS_APPEARANCE_PAGE,
      }[setting.category] ??
      SETTINGS_GENERAL_PAGE;

  if (pageToNav == SETTINGS_ABOUT_PAGE) {
    final AccountBloc accountBloc = context.read<AccountBloc>();
    final ThunderBloc thunderBloc = context.read<ThunderBloc>();
    final AuthBloc authBloc = context.read<AuthBloc>();

    Navigator.of(context).push(
      SwipeablePageRoute(
        transitionDuration: thunderBloc.state.reduceAnimations ? const Duration(milliseconds: 100) : null,
        canSwipe: Platform.isIOS || thunderBloc.state.enableFullScreenSwipeNavigationGesture,
        canOnlySwipeFromEdge: !thunderBloc.state.enableFullScreenSwipeNavigationGesture,
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: accountBloc),
            BlocProvider.value(value: thunderBloc),
            BlocProvider.value(value: authBloc),
          ],
          child: AboutSettingsPage(settingToHighlight: setting),
        ),
      ),
    );
  } else {
    final ThunderBloc thunderBloc = context.read<ThunderBloc>();
    final UserSettingsBloc userSettingsBloc = UserSettingsBloc();

    Navigator.of(context).push(
      SwipeablePageRoute(
        transitionDuration: thunderBloc.state.reduceAnimations ? const Duration(milliseconds: 100) : null,
        canSwipe: Platform.isIOS || thunderBloc.state.enableFullScreenSwipeNavigationGesture,
        canOnlySwipeFromEdge: !thunderBloc.state.enableFullScreenSwipeNavigationGesture,
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: thunderBloc),
            BlocProvider.value(value: userSettingsBloc),
          ],
          child: switch (pageToNav) {
            SETTINGS_GENERAL_PAGE => GeneralSettingsPage(settingToHighlight: setting),
            SETTINGS_APPEARANCE_POSTS_PAGE => PostAppearanceSettingsPage(settingToHighlight: setting),
            SETTINGS_APPEARANCE_COMMENTS_PAGE => CommentAppearanceSettingsPage(settingToHighlight: setting),
            SETTINGS_GESTURES_PAGE => GestureSettingsPage(settingToHighlight: setting),
            SETTINGS_FAB_PAGE => GestureSettingsPage(settingToHighlight: setting),
            SETTINGS_FILTERS_PAGE => FilterSettingsPage(settingToHighlight: setting),
            SETTINGS_ACCOUNT_PAGE => UserSettingsPage(settingToHighlight: setting),
            SETTINGS_APPEARANCE_THEMES_PAGE => ThemeSettingsPage(settingToHighlight: setting),
            SETTINGS_DEBUG_PAGE => DebugSettingsPage(settingToHighlight: setting),
            SETTINGS_VIDEO_PAGE => VideoPlayerSettingsPage(settingToHighlight: setting),
            SETTINGS_USER_LABELS_PAGE => UserLabelSettingsPage(settingToHighlight: setting),
            SETTINGS_ACCESSIBILITY_PAGE => AccessibilitySettingsPage(settingToHighlight: setting),
            SETTINGS_APPEARANCE_PAGE => AppearanceSettingsPage(settingToHighlight: setting),
            _ => Container(),
          },
        ),
      ),
    );
  }
}

void shareSetting(BuildContext context, LocalSettings? setting, String description) {
  if (setting == null) return;

  final AppLocalizations l10n = AppLocalizations.of(context)!;
  final String settingPath = '${l10n.getLocalSettingLocalization(setting.category.toString())} > ${l10n.getLocalSettingLocalization(setting.subCategory.toString())} > $description';

  Clipboard.setData(ClipboardData(text: '[Thunder Setting: $settingPath](thunder://setting-${setting.name})'));
  showSnackbar('Setting link copied to clipboard!');
}
