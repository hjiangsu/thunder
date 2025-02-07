import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:thunder/core/enums/action_color.dart';

import 'package:thunder/core/enums/custom_theme_type.dart';
import 'package:thunder/core/enums/font_scale.dart';
import 'package:thunder/core/enums/full_name.dart';
import 'package:thunder/core/enums/local_settings.dart';
import 'package:thunder/core/enums/theme_type.dart';
import 'package:thunder/core/singletons/preferences.dart';
import 'package:thunder/core/theme/bloc/theme_bloc.dart';
import 'package:thunder/settings/widgets/action_color_setting_widget.dart';
import 'package:thunder/settings/widgets/list_option.dart';
import 'package:thunder/settings/widgets/toggle_option.dart';
import 'package:thunder/thunder/bloc/thunder_bloc.dart';
import 'package:thunder/utils/bottom_sheet_list_picker.dart';
import 'package:thunder/utils/global_context.dart';

class ThemeSettingsPage extends StatefulWidget {
  final LocalSettings? settingToHighlight;

  const ThemeSettingsPage({super.key, this.settingToHighlight});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  final l10n = AppLocalizations.of(GlobalContext.context)!;

  /// -------------------------- Theme Related Settings --------------------------
  // Theme Settings
  ThemeType themeType = ThemeType.system;
  bool usePureBlackTheme = false;
  bool useMaterialYouTheme = false;
  CustomThemeType selectedTheme = CustomThemeType.deepBlue;

  // For now, we will use the pre-made themes provided by FlexScheme
  // @TODO: Make this into our own custom enum list and extend this functionality to allow for more themes

  List<ListPickerItem> customThemeOptions = [
    ListPickerItem(
        colors: [CustomThemeType.deepBlue.primaryColor, CustomThemeType.deepBlue.secondaryColor, CustomThemeType.deepBlue.tertiaryColor],
        label: '${CustomThemeType.deepBlue.label} (Default)',
        payload: CustomThemeType.deepBlue),
    ...CustomThemeType.values.where((element) => element != CustomThemeType.deepBlue).map((CustomThemeType scheme) {
      return ListPickerItem(colors: [scheme.primaryColor, scheme.secondaryColor, scheme.tertiaryColor], label: scheme.label, payload: scheme);
    })
  ];

  ActionColor upvoteColor = const ActionColor.fromString(colorRaw: ActionColor.orange);
  ActionColor downvoteColor = const ActionColor.fromString(colorRaw: ActionColor.blue);
  ActionColor saveColor = const ActionColor.fromString(colorRaw: ActionColor.purple);
  ActionColor markReadColor = const ActionColor.fromString(colorRaw: ActionColor.teal);
  ActionColor replyColor = const ActionColor.fromString(colorRaw: ActionColor.green);
  ActionColor hideColor = const ActionColor.fromString(colorRaw: ActionColor.red);

  // Font Settings
  FontScale titleFontSizeScale = FontScale.base;
  FontScale contentFontSizeScale = FontScale.base;
  FontScale commentFontSizeScale = FontScale.base;
  FontScale metadataFontSizeScale = FontScale.base;

  /// Theme - this is initialized in initState since we need to get l10n for localization strings
  List<ListPickerItem> themeOptions = [];

  /// Font size scales
  List<ListPickerItem> fontScaleOptions = [];

  /// Defines the separator used to denote full usernames
  FullNameSeparator userSeparator = FullNameSeparator.at;

  /// Defines the style used to denote full usernames
  NameThickness userFullNameUserNameThickness = NameThickness.normal;
  NameColor userFullNameUserNameColor = const NameColor.fromString(color: NameColor.defaultColor);
  NameThickness userFullNameInstanceNameThickness = NameThickness.light;
  NameColor userFullNameInstanceNameColor = const NameColor.fromString(color: NameColor.defaultColor);

  /// Defines the separator used to denote full commuity names
  FullNameSeparator communitySeparator = FullNameSeparator.dot;

  /// Defines the style used to denote full community names
  NameThickness communityFullNameCommunityNameThickness = NameThickness.normal;
  NameColor communityFullNameCommunityNameColor = const NameColor.fromString(color: NameColor.defaultColor);
  NameThickness communityFullNameInstanceNameThickness = NameThickness.light;
  NameColor communityFullNameInstanceNameColor = const NameColor.fromString(color: NameColor.defaultColor);

  /// When enabled, displays the user's display name instead of the username
  bool useDisplayNamesForUsers = false;

  /// When enabled, displays the community's display name instead of the community name
  bool useDisplayNamesForCommunities = false;

  // Loading
  bool isLoading = true;

  GlobalKey settingToHighlightKey = GlobalKey();
  LocalSettings? settingToHighlight;

  Future<void> setPreferences(attribute, value) async {
    final prefs = (await UserPreferences.instance).sharedPreferences;

    switch (attribute) {
      /// -------------------------- Theme Related Settings --------------------------
      // Theme Settings
      case LocalSettings.appTheme:
        await prefs.setInt(LocalSettings.appTheme.name, value);
        setState(() => themeType = ThemeType.values[value]);
        if (context.mounted) context.read<ThemeBloc>().add(ThemeChangeEvent());
        Future.delayed(const Duration(milliseconds: 300), () => _initFontScaleOptions()); // Refresh the font scale options since the textTheme has most likely changed (dark -> light and vice versa)
        break;
      case LocalSettings.usePureBlackTheme:
        await prefs.setBool(LocalSettings.usePureBlackTheme.name, value);
        setState(() => usePureBlackTheme = value);
        if (context.mounted) context.read<ThemeBloc>().add(ThemeChangeEvent());
        break;
      case LocalSettings.appThemeAccentColor:
        await prefs.setString(LocalSettings.appThemeAccentColor.name, (value as CustomThemeType).name);
        setState(() => selectedTheme = value);
        if (context.mounted) context.read<ThemeBloc>().add(ThemeChangeEvent());
        break;
      case LocalSettings.useMaterialYouTheme:
        await prefs.setBool(LocalSettings.useMaterialYouTheme.name, value);
        setState(() => useMaterialYouTheme = value);
        if (context.mounted) context.read<ThemeBloc>().add(ThemeChangeEvent());
        break;

      // Color settings
      case LocalSettings.upvoteColor:
        await prefs.setString(LocalSettings.upvoteColor.name, value);
        setState(() => upvoteColor = ActionColor.fromString(colorRaw: value));
        break;
      case LocalSettings.downvoteColor:
        await prefs.setString(LocalSettings.downvoteColor.name, value);
        setState(() => downvoteColor = ActionColor.fromString(colorRaw: value));
        break;
      case LocalSettings.saveColor:
        await prefs.setString(LocalSettings.saveColor.name, value);
        setState(() => saveColor = ActionColor.fromString(colorRaw: value));
        break;
      case LocalSettings.markReadColor:
        await prefs.setString(LocalSettings.markReadColor.name, value);
        setState(() => markReadColor = ActionColor.fromString(colorRaw: value));
        break;
      case LocalSettings.replyColor:
        await prefs.setString(LocalSettings.replyColor.name, value);
        setState(() => replyColor = ActionColor.fromString(colorRaw: value));
        break;
      case LocalSettings.hideColor:
        await prefs.setString(LocalSettings.hideColor.name, value);
        setState(() => hideColor = ActionColor.fromString(colorRaw: value));
        break;

      // Font Settings
      case LocalSettings.titleFontSizeScale:
        await prefs.setString(LocalSettings.titleFontSizeScale.name, (value as FontScale).name);
        setState(() => titleFontSizeScale = value);
        if (context.mounted) context.read<ThemeBloc>().add(ThemeChangeEvent());
        break;
      case LocalSettings.contentFontSizeScale:
        await prefs.setString(LocalSettings.contentFontSizeScale.name, (value as FontScale).name);
        setState(() => contentFontSizeScale = value);
        if (context.mounted) context.read<ThemeBloc>().add(ThemeChangeEvent());
        break;
      case LocalSettings.commentFontSizeScale:
        await prefs.setString(LocalSettings.commentFontSizeScale.name, (value as FontScale).name);
        setState(() => commentFontSizeScale = value);
        if (context.mounted) context.read<ThemeBloc>().add(ThemeChangeEvent());
        break;
      case LocalSettings.metadataFontSizeScale:
        await prefs.setString(LocalSettings.metadataFontSizeScale.name, (value as FontScale).name);
        setState(() => metadataFontSizeScale = value);
        if (context.mounted) context.read<ThemeBloc>().add(ThemeChangeEvent());
        break;

      // Name Settings
      case LocalSettings.userFormat:
        await prefs.setString(LocalSettings.userFormat.name, value);
        setState(() => userSeparator = FullNameSeparator.values.byName(value ?? FullNameSeparator.at));
        break;
      case LocalSettings.userFullNameUserNameThickness:
        await prefs.setString(LocalSettings.userFullNameUserNameThickness.name, value);
        setState(() => userFullNameUserNameThickness = NameThickness.values.byName(value ?? NameThickness.normal));
        break;
      case LocalSettings.userFullNameInstanceNameThickness:
        await prefs.setString(LocalSettings.userFullNameInstanceNameThickness.name, value);
        setState(() => userFullNameInstanceNameThickness = NameThickness.values.byName(value ?? NameThickness.light));
        break;
      case LocalSettings.userFullNameUserNameColor:
        await prefs.setString(LocalSettings.userFullNameUserNameColor.name, value);
        setState(() => userFullNameUserNameColor = NameColor.fromString(color: value ?? NameColor.defaultColor));
        break;
      case LocalSettings.userFullNameInstanceNameColor:
        await prefs.setString(LocalSettings.userFullNameInstanceNameColor.name, value);
        setState(() => userFullNameInstanceNameColor = NameColor.fromString(color: value ?? NameColor.defaultColor));
        break;
      case LocalSettings.communityFormat:
        await prefs.setString(LocalSettings.communityFormat.name, value);
        setState(() => communitySeparator = FullNameSeparator.values.byName(value ?? FullNameSeparator.dot));
        break;
      case LocalSettings.communityFullNameCommunityNameThickness:
        await prefs.setString(LocalSettings.communityFullNameCommunityNameThickness.name, value);
        setState(() => communityFullNameCommunityNameThickness = NameThickness.values.byName(value ?? NameThickness.normal));
        break;
      case LocalSettings.communityFullNameInstanceNameThickness:
        await prefs.setString(LocalSettings.communityFullNameInstanceNameThickness.name, value);
        setState(() => communityFullNameInstanceNameThickness = NameThickness.values.byName(value ?? NameThickness.normal));
        break;
      case LocalSettings.communityFullNameCommunityNameColor:
        await prefs.setString(LocalSettings.communityFullNameCommunityNameColor.name, value);
        setState(() => communityFullNameCommunityNameColor = NameColor.fromString(color: value ?? NameColor.defaultColor));
        break;
      case LocalSettings.communityFullNameInstanceNameColor:
        await prefs.setString(LocalSettings.communityFullNameInstanceNameColor.name, value);
        setState(() => communityFullNameInstanceNameColor = NameColor.fromString(color: value ?? NameColor.defaultColor));
        break;
      case LocalSettings.useDisplayNamesForUsers:
        await prefs.setBool(LocalSettings.useDisplayNamesForUsers.name, value);
        setState(() => useDisplayNamesForUsers = value);
        break;
      case LocalSettings.useDisplayNamesForCommunities:
        await prefs.setBool(LocalSettings.useDisplayNamesForCommunities.name, value);
        setState(() => useDisplayNamesForCommunities = value);
        break;
    }

    if (context.mounted) {
      context.read<ThunderBloc>().add(UserPreferencesChangeEvent());
    }
  }

  void _initPreferences() async {
    final prefs = (await UserPreferences.instance).sharedPreferences;

    setState(() {
      /// -------------------------- Theme Related Settings --------------------------
      // Theme Settings
      themeType = ThemeType.values[prefs.getInt(LocalSettings.appTheme.name) ?? ThemeType.system.index];
      usePureBlackTheme = prefs.getBool(LocalSettings.usePureBlackTheme.name) ?? false;
      selectedTheme = CustomThemeType.values.byName(prefs.getString(LocalSettings.appThemeAccentColor.name) ?? CustomThemeType.deepBlue.name);
      useMaterialYouTheme = prefs.getBool(LocalSettings.useMaterialYouTheme.name) ?? false;

      // Color settings
      upvoteColor = ActionColor.fromString(colorRaw: prefs.getString(LocalSettings.upvoteColor.name) ?? ActionColor.orange);
      downvoteColor = ActionColor.fromString(colorRaw: prefs.getString(LocalSettings.downvoteColor.name) ?? ActionColor.blue);
      saveColor = ActionColor.fromString(colorRaw: prefs.getString(LocalSettings.saveColor.name) ?? ActionColor.purple);
      markReadColor = ActionColor.fromString(colorRaw: prefs.getString(LocalSettings.markReadColor.name) ?? ActionColor.teal);
      replyColor = ActionColor.fromString(colorRaw: prefs.getString(LocalSettings.replyColor.name) ?? ActionColor.green);
      hideColor = ActionColor.fromString(colorRaw: prefs.getString(LocalSettings.hideColor.name) ?? ActionColor.red);

      // Font Settings
      titleFontSizeScale = FontScale.values.byName(prefs.getString(LocalSettings.titleFontSizeScale.name) ?? FontScale.base.name);
      contentFontSizeScale = FontScale.values.byName(prefs.getString(LocalSettings.contentFontSizeScale.name) ?? FontScale.base.name);
      commentFontSizeScale = FontScale.values.byName(prefs.getString(LocalSettings.commentFontSizeScale.name) ?? FontScale.base.name);
      metadataFontSizeScale = FontScale.values.byName(prefs.getString(LocalSettings.metadataFontSizeScale.name) ?? FontScale.base.name);

      // Name Settings
      userSeparator = FullNameSeparator.values.byName(prefs.getString(LocalSettings.userFormat.name) ?? FullNameSeparator.at.name);
      userFullNameUserNameThickness = NameThickness.values.byName(prefs.getString(LocalSettings.userFullNameUserNameThickness.name) ?? NameThickness.normal.name);
      userFullNameUserNameColor = NameColor.fromString(color: prefs.getString(LocalSettings.userFullNameUserNameColor.name) ?? NameColor.defaultColor);
      userFullNameInstanceNameThickness = NameThickness.values.byName(prefs.getString(LocalSettings.userFullNameInstanceNameThickness.name) ?? NameThickness.light.name);
      userFullNameInstanceNameColor = NameColor.fromString(color: prefs.getString(LocalSettings.userFullNameInstanceNameColor.name) ?? NameColor.defaultColor);
      communitySeparator = FullNameSeparator.values.byName(prefs.getString(LocalSettings.communityFormat.name) ?? FullNameSeparator.dot.name);
      communityFullNameCommunityNameThickness = NameThickness.values.byName(prefs.getString(LocalSettings.communityFullNameCommunityNameThickness.name) ?? NameThickness.normal.name);
      communityFullNameCommunityNameColor = NameColor.fromString(color: prefs.getString(LocalSettings.communityFullNameCommunityNameColor.name) ?? NameColor.defaultColor);
      communityFullNameInstanceNameThickness = NameThickness.values.byName(prefs.getString(LocalSettings.communityFullNameInstanceNameThickness.name) ?? NameThickness.light.name);
      communityFullNameInstanceNameColor = NameColor.fromString(color: prefs.getString(LocalSettings.communityFullNameInstanceNameColor.name) ?? NameColor.defaultColor);
      useDisplayNamesForUsers = prefs.getBool(LocalSettings.useDisplayNamesForUsers.name) ?? false;
      useDisplayNamesForCommunities = prefs.getBool(LocalSettings.useDisplayNamesForCommunities.name) ?? false;

      isLoading = false;
    });
  }

  void _initFontScaleOptions() {
    final theme = Theme.of(context);

    setState(() {
      fontScaleOptions = FontScale.values
          .map(
            (FontScale fontScale) => ListPickerItem(
              icon: Icons.text_fields_rounded,
              label: fontScale.label,
              payload: fontScale,
              textTheme: theme.textTheme.copyWith(
                bodyMedium: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: MediaQuery.textScalerOf(context).scale(theme.textTheme.bodyMedium!.fontSize! * fontScale.textScaleFactor),
                ),
              ),
            ),
          )
          .toList();
    });
  }

  @override
  void initState() {
    themeOptions = [
      ListPickerItem(icon: Icons.phonelink_setup_rounded, label: l10n.system, payload: ThemeType.system),
      ListPickerItem(icon: Icons.light_mode_rounded, label: l10n.light, payload: ThemeType.light),
      ListPickerItem(icon: Icons.dark_mode_outlined, label: l10n.dark, payload: ThemeType.dark),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) => _initPreferences());
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFontScaleOptions());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.settingToHighlight != null) {
        setState(() => settingToHighlight = widget.settingToHighlight);

        // Need some delay to finish building, even though we're in a post-frame callback.
        Timer(const Duration(milliseconds: 500), () {
          if (settingToHighlightKey.currentContext != null) {
            // Ensure that the selected setting is visible on the screen
            Scrollable.ensureVisible(
              settingToHighlightKey.currentContext!,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            );
          }

          // Give time for the highlighting to appear, then turn it off
          Timer(const Duration(seconds: 1), () {
            setState(() => settingToHighlight = null);
          });
        });
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.theming), centerTitle: false),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                          child: Text(l10n.theme, style: theme.textTheme.titleLarge),
                        ),
                        ListOption(
                          description: l10n.theme,
                          value: ListPickerItem(label: themeType.name.capitalize, icon: Icons.wallpaper_rounded, payload: themeType),
                          options: themeOptions,
                          icon: Icons.wallpaper_rounded,
                          onChanged: (value) async => setPreferences(LocalSettings.appTheme, value.payload.index),
                          highlightKey: settingToHighlightKey,
                          setting: LocalSettings.appTheme,
                          highlightedSetting: settingToHighlight,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOutCubicEmphasized,
                          child: themeType == ThemeType.dark || themeType == ThemeType.system
                              ? ToggleOption(
                                  description: l10n.pureBlack,
                                  subtitle: l10n.systemDarkModeDescription,
                                  value: usePureBlackTheme,
                                  iconEnabled: Icons.dark_mode_rounded,
                                  iconDisabled: Icons.dark_mode_outlined,
                                  onToggle: (bool value) => setPreferences(LocalSettings.usePureBlackTheme, value),
                                  highlightKey: settingToHighlightKey,
                                  setting: LocalSettings.usePureBlackTheme,
                                  highlightedSetting: settingToHighlight,
                                )
                              : Container(),
                        ),
                        ListOption(
                          description: l10n.themeAccentColor,
                          value: ListPickerItem(label: selectedTheme.label, icon: Icons.wallpaper_rounded, payload: selectedTheme),
                          valueDisplay: Stack(
                            children: [
                              Container(
                                height: 28,
                                width: 28,
                                decoration: BoxDecoration(
                                  color: selectedTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  height: 14,
                                  width: 14,
                                  decoration: BoxDecoration(
                                    color: selectedTheme.secondaryColor,
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(100),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  height: 14,
                                  width: 14,
                                  decoration: BoxDecoration(
                                    color: selectedTheme.tertiaryColor,
                                    borderRadius: const BorderRadius.only(
                                      bottomRight: Radius.circular(100),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          options: customThemeOptions,
                          icon: Icons.wallpaper_rounded,
                          onChanged: (value) async => setPreferences(LocalSettings.appThemeAccentColor, value.payload),
                          closeOnSelect: false,
                          highlightKey: settingToHighlightKey,
                          setting: LocalSettings.appThemeAccentColor,
                          highlightedSetting: settingToHighlight,
                        ),
                        if (!kIsWeb && Platform.isAndroid) ...[
                          ToggleOption(
                            description: l10n.useMaterialYouTheme,
                            subtitle: l10n.useMaterialYouThemeDescription,
                            value: useMaterialYouTheme,
                            iconEnabled: Icons.color_lens_rounded,
                            iconDisabled: Icons.color_lens_rounded,
                            onToggle: (bool value) => setPreferences(LocalSettings.useMaterialYouTheme, value),
                            highlightKey: settingToHighlightKey,
                            setting: LocalSettings.useMaterialYouTheme,
                            highlightedSetting: settingToHighlight,
                          )
                        ],
                      ],
                    ),
                  ),
                  ActionColorSettingWidget(
                    settingToHighlight: widget.settingToHighlight,
                    settingToHighlightKey: settingToHighlightKey,
                    setPreferences: setPreferences,
                    upvoteColor: upvoteColor,
                    downvoteColor: downvoteColor,
                    saveColor: saveColor,
                    markReadColor: markReadColor,
                    replyColor: replyColor,
                    hideColor: hideColor,
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                          child: Text(l10n.fonts, style: theme.textTheme.titleLarge),
                        ),
                        ListOption(
                          description: l10n.postTitleFontScale,
                          value: ListPickerItem(label: titleFontSizeScale.name.capitalize, icon: Icons.feed, payload: titleFontSizeScale),
                          options: fontScaleOptions,
                          icon: Icons.text_fields_rounded,
                          onChanged: (value) async => setPreferences(LocalSettings.titleFontSizeScale, value.payload),
                          highlightKey: settingToHighlightKey,
                          setting: LocalSettings.titleFontSizeScale,
                          highlightedSetting: settingToHighlight,
                        ),
                        ListOption(
                          description: l10n.postContentFontScale,
                          value: ListPickerItem(label: contentFontSizeScale.name.capitalize, icon: Icons.feed, payload: contentFontSizeScale),
                          options: fontScaleOptions,
                          icon: Icons.text_fields_rounded,
                          onChanged: (value) async => setPreferences(LocalSettings.contentFontSizeScale, value.payload),
                          highlightKey: settingToHighlightKey,
                          setting: LocalSettings.contentFontSizeScale,
                          highlightedSetting: settingToHighlight,
                        ),
                        ListOption(
                          description: l10n.commentFontScale,
                          value: ListPickerItem(label: commentFontSizeScale.name.capitalize, icon: Icons.feed, payload: commentFontSizeScale),
                          options: fontScaleOptions,
                          icon: Icons.text_fields_rounded,
                          onChanged: (value) async => setPreferences(LocalSettings.commentFontSizeScale, value.payload),
                          highlightKey: settingToHighlightKey,
                          setting: LocalSettings.commentFontSizeScale,
                          highlightedSetting: settingToHighlight,
                        ),
                        ListOption(
                          description: l10n.metadataFontScale,
                          value: ListPickerItem(label: metadataFontSizeScale.name.capitalize, icon: Icons.feed, payload: metadataFontSizeScale),
                          options: fontScaleOptions,
                          icon: Icons.text_fields_rounded,
                          onChanged: (value) async => setPreferences(LocalSettings.metadataFontSizeScale, value.payload),
                          highlightKey: settingToHighlightKey,
                          setting: LocalSettings.metadataFontSizeScale,
                          highlightedSetting: settingToHighlight,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                          child: Text(l10n.names, style: theme.textTheme.titleLarge),
                        ),
                        ListOption(
                          description: l10n.userFormat,
                          value: ListPickerItem(
                            label: generateSampleUserFullName(userSeparator, useDisplayNamesForUsers),
                            labelWidget: generateSampleUserFullNameWidget(
                              userSeparator,
                              userNameThickness: userFullNameUserNameThickness,
                              userNameColor: userFullNameUserNameColor,
                              instanceNameThickness: userFullNameInstanceNameThickness,
                              instanceNameColor: userFullNameInstanceNameColor,
                              textStyle: theme.textTheme.bodyMedium,
                              useDisplayName: useDisplayNamesForUsers,
                            ),
                            icon: Icons.person_rounded,
                            payload: userSeparator,
                            capitalizeLabel: false,
                          ),
                          options: [
                            ListPickerItem(
                              icon: const IconData(0x2022),
                              label: generateSampleUserFullName(FullNameSeparator.dot, useDisplayNamesForUsers),
                              labelWidget: generateSampleUserFullNameWidget(
                                FullNameSeparator.dot,
                                userNameThickness: userFullNameUserNameThickness,
                                userNameColor: userFullNameUserNameColor,
                                instanceNameThickness: userFullNameInstanceNameThickness,
                                instanceNameColor: userFullNameInstanceNameColor,
                                textStyle: theme.textTheme.bodyMedium,
                                useDisplayName: useDisplayNamesForUsers,
                              ),
                              payload: FullNameSeparator.dot,
                              capitalizeLabel: false,
                            ),
                            ListPickerItem(
                              icon: Icons.alternate_email_rounded,
                              label: generateSampleUserFullName(FullNameSeparator.at, useDisplayNamesForUsers),
                              labelWidget: generateSampleUserFullNameWidget(
                                FullNameSeparator.at,
                                userNameThickness: userFullNameUserNameThickness,
                                userNameColor: userFullNameUserNameColor,
                                instanceNameThickness: userFullNameInstanceNameThickness,
                                instanceNameColor: userFullNameInstanceNameColor,
                                textStyle: theme.textTheme.bodyMedium,
                                useDisplayName: useDisplayNamesForUsers,
                              ),
                              payload: FullNameSeparator.at,
                              capitalizeLabel: false,
                            ),
                            ListPickerItem(
                              icon: Icons.alternate_email_rounded,
                              label: generateSampleUserFullName(FullNameSeparator.lemmy, useDisplayNamesForUsers),
                              labelWidget: generateSampleUserFullNameWidget(
                                FullNameSeparator.lemmy,
                                userNameThickness: userFullNameUserNameThickness,
                                userNameColor: userFullNameUserNameColor,
                                instanceNameThickness: userFullNameInstanceNameThickness,
                                instanceNameColor: userFullNameInstanceNameColor,
                                textStyle: theme.textTheme.bodyMedium,
                                useDisplayName: useDisplayNamesForUsers,
                              ),
                              payload: FullNameSeparator.lemmy,
                              capitalizeLabel: false,
                            ),
                          ],
                          icon: Icons.person_rounded,
                          onChanged: (value) => setPreferences(LocalSettings.userFormat, value.payload.name),
                          highlightKey: settingToHighlightKey,
                          setting: LocalSettings.userFormat,
                          highlightedSetting: settingToHighlight,
                        ),
                        ListOption(
                          isBottomModalScrollControlled: true,
                          value: const ListPickerItem(payload: -1),
                          description: l10n.userStyle,
                          icon: Icons.person_rounded,
                          highlightKey: settingToHighlightKey,
                          setting: LocalSettings.userStyle,
                          highlightedSetting: settingToHighlight,
                          customListPicker: StatefulBuilder(
                            builder: (context, setState) {
                              return BottomSheetListPicker(
                                title: l10n.userStyle,
                                heading: generateSampleUserFullNameWidget(
                                  userSeparator,
                                  userNameThickness: userFullNameUserNameThickness,
                                  userNameColor: userFullNameUserNameColor,
                                  instanceNameThickness: userFullNameInstanceNameThickness,
                                  instanceNameColor: userFullNameInstanceNameColor,
                                  textStyle: theme.textTheme.bodyMedium,
                                  useDisplayName: useDisplayNamesForUsers,
                                ),
                                items: [
                                  ListPickerItem(
                                    payload: -1,
                                    customWidget: ListTile(
                                      title: Text(
                                        l10n.userNameThickness,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      subtitle: SizedBox(
                                        width: 200.0,
                                        child: Slider(
                                          value: userFullNameUserNameThickness.toSliderValue(),
                                          max: 2,
                                          divisions: 2,
                                          label: userFullNameUserNameThickness.label(context),
                                          onChanged: (double value) async {
                                            await setPreferences(LocalSettings.userFullNameUserNameThickness, NameThickness.fromSliderValue(value).name);
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  ListPickerItem(
                                    payload: -1,
                                    customWidget: ListTile(
                                      title: Text(
                                        l10n.instanceNameThickness,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      subtitle: SizedBox(
                                        width: 200.0,
                                        child: Slider(
                                          value: userFullNameInstanceNameThickness.toSliderValue(),
                                          max: 2,
                                          divisions: 2,
                                          label: userFullNameInstanceNameThickness.label(context),
                                          onChanged: (double value) async {
                                            await setPreferences(LocalSettings.userFullNameInstanceNameThickness, NameThickness.fromSliderValue(value).name);
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  ListPickerItem(
                                    payload: -1,
                                    customWidget: ListTile(
                                      title: Text(
                                        l10n.userNameColor,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                                        child: DropdownButton<NameColor>(
                                          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                                          isExpanded: true,
                                          underline: Container(),
                                          value: userFullNameUserNameColor,
                                          items: NameColor.getPossibleValues(userFullNameUserNameColor)
                                              .map(
                                                (nameColor) => DropdownMenuItem<NameColor>(
                                                  alignment: Alignment.center,
                                                  value: nameColor,
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 10.0,
                                                        backgroundColor: nameColor.toColor(context),
                                                      ),
                                                      const SizedBox(width: 16.0),
                                                      Text(
                                                        nameColor.label(context),
                                                        style: theme.textTheme.bodyMedium,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (value) async {
                                            await setPreferences(LocalSettings.userFullNameUserNameColor, value?.color);
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  ListPickerItem(
                                    payload: -1,
                                    customWidget: ListTile(
                                      title: Text(
                                        l10n.instanceNameColor,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                                        child: DropdownButton<NameColor>(
                                          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                                          isExpanded: true,
                                          underline: Container(),
                                          value: userFullNameInstanceNameColor,
                                          items: NameColor.getPossibleValues(userFullNameInstanceNameColor)
                                              .map(
                                                (nameColor) => DropdownMenuItem<NameColor>(
                                                  alignment: Alignment.center,
                                                  value: nameColor,
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 10.0,
                                                        backgroundColor: nameColor.toColor(context),
                                                      ),
                                                      const SizedBox(width: 16.0),
                                                      Text(
                                                        nameColor.label(context),
                                                        style: theme.textTheme.bodyMedium,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (value) async {
                                            await setPreferences(LocalSettings.userFullNameInstanceNameColor, value?.color);
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        ListOption(
                          description: l10n.communityFormat,
                          value: ListPickerItem(
                            label: generateSampleCommunityFullName(communitySeparator, useDisplayNamesForCommunities),
                            labelWidget: generateSampleCommunityFullNameWidget(
                              communitySeparator,
                              communityNameThickness: communityFullNameCommunityNameThickness,
                              communityNameColor: communityFullNameCommunityNameColor,
                              instanceNameThickness: communityFullNameInstanceNameThickness,
                              instanceNameColor: communityFullNameInstanceNameColor,
                              textStyle: theme.textTheme.bodyMedium,
                              useDisplayName: useDisplayNamesForCommunities,
                            ),
                            icon: Icons.people_rounded,
                            payload: communitySeparator,
                            capitalizeLabel: false,
                          ),
                          options: [
                            ListPickerItem(
                              icon: const IconData(0x2022),
                              label: generateSampleCommunityFullName(FullNameSeparator.dot, useDisplayNamesForCommunities),
                              labelWidget: generateSampleCommunityFullNameWidget(
                                FullNameSeparator.dot,
                                communityNameThickness: communityFullNameCommunityNameThickness,
                                communityNameColor: communityFullNameCommunityNameColor,
                                instanceNameThickness: communityFullNameInstanceNameThickness,
                                instanceNameColor: communityFullNameInstanceNameColor,
                                textStyle: theme.textTheme.bodyMedium,
                                useDisplayName: useDisplayNamesForCommunities,
                              ),
                              payload: FullNameSeparator.dot,
                              capitalizeLabel: false,
                            ),
                            ListPickerItem(
                              icon: Icons.alternate_email_rounded,
                              label: generateSampleCommunityFullName(FullNameSeparator.at, useDisplayNamesForCommunities),
                              labelWidget: generateSampleCommunityFullNameWidget(
                                FullNameSeparator.at,
                                communityNameThickness: communityFullNameCommunityNameThickness,
                                communityNameColor: communityFullNameCommunityNameColor,
                                instanceNameThickness: communityFullNameInstanceNameThickness,
                                instanceNameColor: communityFullNameInstanceNameColor,
                                textStyle: theme.textTheme.bodyMedium,
                                useDisplayName: useDisplayNamesForCommunities,
                              ),
                              payload: FullNameSeparator.at,
                              capitalizeLabel: false,
                            ),
                            ListPickerItem(
                              icon: Icons.alternate_email_rounded,
                              label: generateSampleCommunityFullName(FullNameSeparator.lemmy, useDisplayNamesForCommunities),
                              labelWidget: generateSampleCommunityFullNameWidget(
                                FullNameSeparator.lemmy,
                                communityNameThickness: communityFullNameCommunityNameThickness,
                                communityNameColor: communityFullNameCommunityNameColor,
                                instanceNameThickness: communityFullNameInstanceNameThickness,
                                instanceNameColor: communityFullNameInstanceNameColor,
                                textStyle: theme.textTheme.bodyMedium,
                                useDisplayName: useDisplayNamesForCommunities,
                              ),
                              payload: FullNameSeparator.lemmy,
                              capitalizeLabel: false,
                            ),
                          ],
                          icon: Icons.people_rounded,
                          onChanged: (value) => setPreferences(LocalSettings.communityFormat, value.payload.name),
                          highlightKey: settingToHighlightKey,
                          setting: LocalSettings.communityFormat,
                          highlightedSetting: settingToHighlight,
                        ),
                        ListOption(
                          isBottomModalScrollControlled: true,
                          value: const ListPickerItem(payload: -1),
                          description: l10n.communityStyle,
                          icon: Icons.person_rounded,
                          highlightKey: settingToHighlightKey,
                          setting: LocalSettings.communityStyle,
                          highlightedSetting: settingToHighlight,
                          customListPicker: StatefulBuilder(
                            builder: (context, setState) {
                              return BottomSheetListPicker(
                                title: l10n.communityStyle,
                                heading: generateSampleCommunityFullNameWidget(
                                  communitySeparator,
                                  communityNameThickness: communityFullNameCommunityNameThickness,
                                  communityNameColor: communityFullNameCommunityNameColor,
                                  instanceNameThickness: communityFullNameInstanceNameThickness,
                                  instanceNameColor: communityFullNameInstanceNameColor,
                                  textStyle: theme.textTheme.bodyMedium,
                                  useDisplayName: useDisplayNamesForCommunities,
                                ),
                                items: [
                                  ListPickerItem(
                                    payload: -1,
                                    customWidget: ListTile(
                                      title: Text(
                                        l10n.communityNameThickness,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      subtitle: SizedBox(
                                        width: 200.0,
                                        child: Slider(
                                          value: communityFullNameCommunityNameThickness.toSliderValue(),
                                          max: 2,
                                          divisions: 2,
                                          label: communityFullNameCommunityNameThickness.label(context),
                                          onChanged: (double value) async {
                                            await setPreferences(LocalSettings.communityFullNameCommunityNameThickness, NameThickness.fromSliderValue(value).name);
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  ListPickerItem(
                                    payload: -1,
                                    customWidget: ListTile(
                                      title: Text(
                                        l10n.instanceNameThickness,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      subtitle: SizedBox(
                                        width: 200.0,
                                        child: Slider(
                                          value: communityFullNameInstanceNameThickness.toSliderValue(),
                                          max: 2,
                                          divisions: 2,
                                          label: communityFullNameInstanceNameThickness.label(context),
                                          onChanged: (double value) async {
                                            await setPreferences(LocalSettings.communityFullNameInstanceNameThickness, NameThickness.fromSliderValue(value).name);
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  ListPickerItem(
                                    payload: -1,
                                    customWidget: ListTile(
                                      title: Text(
                                        l10n.communityNameColor,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                                        child: DropdownButton<NameColor>(
                                          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                                          isExpanded: true,
                                          underline: Container(),
                                          value: communityFullNameCommunityNameColor,
                                          items: NameColor.getPossibleValues(communityFullNameCommunityNameColor)
                                              .map(
                                                (nameColor) => DropdownMenuItem<NameColor>(
                                                  alignment: Alignment.center,
                                                  value: nameColor,
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 10.0,
                                                        backgroundColor: nameColor.toColor(context),
                                                      ),
                                                      const SizedBox(width: 16.0),
                                                      Text(
                                                        nameColor.label(context),
                                                        style: theme.textTheme.bodyMedium,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (value) async {
                                            await setPreferences(LocalSettings.communityFullNameCommunityNameColor, value?.color);
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  ListPickerItem(
                                    payload: -1,
                                    customWidget: ListTile(
                                      title: Text(
                                        l10n.instanceNameColor,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                                        child: DropdownButton<NameColor>(
                                          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                                          isExpanded: true,
                                          underline: Container(),
                                          value: communityFullNameInstanceNameColor,
                                          items: NameColor.getPossibleValues(communityFullNameInstanceNameColor)
                                              .map(
                                                (nameColor) => DropdownMenuItem<NameColor>(
                                                  alignment: Alignment.center,
                                                  value: nameColor,
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 10.0,
                                                        backgroundColor: nameColor.toColor(context),
                                                      ),
                                                      const SizedBox(width: 16.0),
                                                      Text(
                                                        nameColor.label(context),
                                                        style: theme.textTheme.bodyMedium,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (value) async {
                                            await setPreferences(LocalSettings.communityFullNameInstanceNameColor, value?.color);
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        ToggleOption(
                          description: l10n.showUserDisplayNames,
                          value: useDisplayNamesForUsers,
                          iconEnabled: Icons.person_rounded,
                          iconDisabled: Icons.person_off_rounded,
                          onToggle: (bool value) => setPreferences(LocalSettings.useDisplayNamesForUsers, value),
                          highlightKey: settingToHighlightKey,
                          setting: LocalSettings.useDisplayNamesForUsers,
                          highlightedSetting: settingToHighlight,
                        ),
                        ToggleOption(
                          description: l10n.showCommunityDisplayNames,
                          value: useDisplayNamesForCommunities,
                          iconEnabled: Icons.people_rounded,
                          iconDisabled: Icons.people_outline_rounded,
                          onToggle: (bool value) => setPreferences(LocalSettings.useDisplayNamesForCommunities, value),
                          highlightKey: settingToHighlightKey,
                          setting: LocalSettings.useDisplayNamesForCommunities,
                          highlightedSetting: settingToHighlight,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 128),
                ],
              ),
            ),
    );
  }
}
