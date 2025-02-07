import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lemmy_api_client/v3.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thunder/account/models/account.dart';
import 'package:thunder/account/models/draft.dart';
import 'package:thunder/comment/view/create_comment_page.dart';
import 'package:thunder/community/pages/create_post_page.dart';
import 'package:thunder/core/enums/browser_mode.dart';
import 'package:thunder/core/enums/full_name.dart';
import 'package:thunder/core/enums/local_settings.dart';
import 'package:thunder/core/enums/theme_type.dart';
import 'package:thunder/drafts/draft_type.dart';
import 'package:thunder/notification/enums/notification_type.dart';
import 'package:thunder/core/singletons/preferences.dart';
import 'package:thunder/utils/constants.dart';

Future<void> performSharedPreferencesMigration() async {
  final SharedPreferences prefs = (await UserPreferences.instance).sharedPreferences;

  // Migrate the openInExternalBrowser setting, if found.
  bool? legacyOpenInExternalBrowser = prefs.getBool(LocalSettings.openLinksInExternalBrowser.name);
  if (legacyOpenInExternalBrowser != null) {
    final BrowserMode browserMode = legacyOpenInExternalBrowser ? BrowserMode.external : BrowserMode.customTabs;
    await prefs.remove(LocalSettings.openLinksInExternalBrowser.name);
    await prefs.setString(LocalSettings.browserMode.name, browserMode.name);
  }

  // Check to see if browserMode was set incorrectly
  String? browserMode = prefs.getString(LocalSettings.browserMode.name);
  if (browserMode != null && browserMode.contains("BrowserMode")) {
    await prefs.setString(LocalSettings.browserMode.name, browserMode.replaceAll('BrowserMode.', ''));
  }

  // Migrate the commentUseColorizedUsername setting, if found.
  bool? legacyCommentUseColorizedUsername = prefs.getBool(LocalSettings.commentUseColorizedUsername.name);
  if (legacyCommentUseColorizedUsername != null) {
    await prefs.remove(LocalSettings.commentUseColorizedUsername.name);
    if (legacyCommentUseColorizedUsername == true) {
      await prefs.setString(LocalSettings.userFullNameUserNameColor.name, NameColor.themePrimary);
    }
  }

  // Migrate the enableInboxNotifications setting, if found.
  bool? legacyEnableInboxNotifications = prefs.getBool('setting_enable_inbox_notifications');
  if (legacyEnableInboxNotifications != null) {
    await prefs.remove('setting_enable_inbox_notifications');
    await prefs.setString(LocalSettings.inboxNotificationType.name, legacyEnableInboxNotifications ? NotificationType.local.name : NotificationType.none.name);
  }

  // Migrate drafts to database
  Iterable<String> draftsKeys = prefs.getKeys().where((pref) => pref.startsWith('drafts_cache'));
  for (String draftKey in draftsKeys) {
    try {
      late DraftType draftType;
      int? existingId;
      int? replyId;

      // ignore: deprecated_member_use_from_same_package
      DraftPost? draftPost;
      // ignore: deprecated_member_use_from_same_package
      DraftComment? draftComment;

      if (draftKey.contains('post-create-general')) {
        draftType = DraftType.postCreateGeneral;
        // ignore: deprecated_member_use_from_same_package
        draftPost = DraftPost.fromJson(jsonDecode(prefs.getString(draftKey)!));
      } else if (draftKey.contains('post-create')) {
        draftType = DraftType.postCreate;
        replyId = int.parse(draftKey.split('-').last);
        // ignore: deprecated_member_use_from_same_package
        draftPost = DraftPost.fromJson(jsonDecode(prefs.getString(draftKey)!));
      } else if (draftKey.contains('post-edit')) {
        draftType = DraftType.postEdit;
        existingId = int.parse(draftKey.split('-').last);
        // ignore: deprecated_member_use_from_same_package
        draftPost = DraftPost.fromJson(jsonDecode(prefs.getString(draftKey)!));
      } else if (draftKey.contains('comment-create')) {
        draftType = DraftType.commentCreate;
        replyId = int.parse(draftKey.split('-').last);
        // ignore: deprecated_member_use_from_same_package
        draftComment = DraftComment.fromJson(jsonDecode(prefs.getString(draftKey)!));
      } else if (draftKey.contains('comment-edit')) {
        draftType = DraftType.commentEdit;
        existingId = int.parse(draftKey.split('-').last);
        // ignore: deprecated_member_use_from_same_package
        draftComment = DraftComment.fromJson(jsonDecode(prefs.getString(draftKey)!));
      } else {
        // We can't parse the draft type from the shared preferences.
        debugPrint('Cannot parse draft type from SharedPreferences key: $draftKey');
        continue;
      }

      Draft draft = Draft(
        id: '',
        draftType: draftType,
        existingId: existingId,
        replyId: replyId,
        title: draftPost?.title,
        url: draftPost?.url,
        body: draftPost?.text ?? draftComment?.text,
      );

      Draft.upsertDraft(draft);

      // If we've gotten this far without exception, it's safe to delete the shared pref eky
      prefs.remove(draftKey);
    } catch (e) {
      debugPrint('Cannot migrate draft from SharedPreferences: $draftKey');
    }
  }

  // Update the default feed type setting
  ListingType defaultListingType = ListingType.values.byName(prefs.getString(LocalSettings.defaultFeedListingType.name) ?? DEFAULT_LISTING_TYPE.name);
  if (defaultListingType == ListingType.subscribed) {
    await prefs.setString(LocalSettings.defaultFeedListingType.name, DEFAULT_LISTING_TYPE.name);
  }

  // Migrate anonymous instances to database
  final List<String>? anonymousInstances = prefs.getStringList('setting_anonymous_instances');
  try {
    for (String instance in anonymousInstances ?? []) {
      Account anonymousInstance = Account(id: '', instance: instance, index: -1, anonymous: true);
      Account.insertAnonymousInstance(anonymousInstance);
    }

    // If we've gotten this far without exception, it's safe to delete the shared pref eky
    prefs.remove('setting_anonymous_instances');
  } catch (e) {
    debugPrint('Cannot migrate anonymous instances from SharedPreferences: $e');
  }

  // Migrate theme settings for pure black to use dark theme + pure black setting
  ThemeType themeType = ThemeType.values[prefs.getInt(LocalSettings.appTheme.name) ?? ThemeType.system.index];
  if (themeType == ThemeType.pureBlack) {
    await prefs.setInt(LocalSettings.appTheme.name, ThemeType.dark.index);
    await prefs.setBool(LocalSettings.usePureBlackTheme.name, true);
  }
}
