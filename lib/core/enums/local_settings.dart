import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum LocalSettingsCategories {
  general('General'),
  filters('Filters'),
  posts('Posts'),
  comments('Comments'),
  gestures('Gestures'),
  floatingActionButton('floatingActionButton'),
  accessibility('Accessibility'),
  account('Account'),
  userLabels('User Labels'),
  about('About'),
  debug('Debug'),
  theming('Theming'),
  videoPlayer('Video Player');

  final String value;

  const LocalSettingsCategories(this.value);

  factory LocalSettingsCategories.fromJson(String value) => values.firstWhere((e) => e.value == value);

  String toJson() => value;

  @override
  String toString() => value;
}

enum LocalSettingsSubCategories {
  feedTypeAndSorts('feedTypeAndSorts'),
  general('general'),
  feed('feed'),
  posts('posts'),
  comments('comments'),
  linksBehaviourSettings('linksBehaviourSettings'),
  advanced('advanced'),
  names('names'),
  notifications('notifications'),
  importExportThunderSettings('importExportThunderSettings'),
  filters('filters'),
  themes('theme'),
  fonts('fonts'),
  profiles('Profiles'),
  blockedCommunities('blockedCommunities'),
  animations('animations'),
  theme('Theme'),
  sidebar('Sidebar'),
  cardView('cardView'),
  navigation('navigation'),
  videoPlayer('videoPlayer'),
  contentManagement('contentManagement'),
  importExportLemmyAccountSettings('importExportLemmyAccountSettings'),
  dangerZone('dangerZone'),
  reset('reset'),
  experimental('experimental'),
  userLabels('userLabels');

  final String value;

  const LocalSettingsSubCategories(this.value);

  factory LocalSettingsSubCategories.fromJson(String value) => values.firstWhere((e) => e.value == value);

  String toJson() => value;

  @override
  String toString() => value;
}

enum LocalSettings {
  /// -------------------------- Account Settings --------------------------
  // Discussion Languages
  discussionLanguages(name: 'account_discussion_languages', key: 'discussionLanguages', category: LocalSettingsCategories.account, subCategory: LocalSettingsSubCategories.contentManagement),

  /// -------------------------- Feed Related Settings --------------------------
  // Default Listing/Sort Settings

  defaultFeedListingType(name: 'setting_general_default_listing_type', key: 'defaultFeedType', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.feedTypeAndSorts),
  defaultFeedSortType(name: 'setting_general_default_sort_type', key: 'defaultFeedSortType', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.feedTypeAndSorts),

  // NSFW Settings
  hideNsfwPosts(name: 'setting_general_hide_nsfw_posts', key: 'hideNsfwPostsFromFeed', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.feed),
  hideNsfwPreviews(name: 'setting_general_hide_nsfw_previews', key: 'hideNsfwPreviews', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.general),

  // Tablet Settings
  useTabletMode(name: 'setting_post_tablet_mode', key: 'tabletMode', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.feed),

  // General Settings

  scrapeMissingPreviews(
      name: 'setting_general_scrape_missing_previews', key: 'scrapeMissingLinkPreviews', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.linksBehaviourSettings),
  // Deprecated, use browserMode
  openLinksInExternalBrowser(
      name: 'setting_links_open_in_external_browser',
      key: 'openLinksInExternalBrowser',
      category: LocalSettingsCategories.general,
      subCategory: LocalSettingsSubCategories.linksBehaviourSettings,
      searchable: false),
  browserMode(name: 'setting_browser_mode', key: 'browserMode', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.linksBehaviourSettings),
  openByDefault(name: 'setting_links_open_by_default', key: 'openByDefault', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.linksBehaviourSettings),
  openLinksInReaderMode(
      name: 'setting_links_open_in_reader_mode', key: 'openLinksInReaderMode', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.linksBehaviourSettings),
  useDisplayNamesForUsers(name: 'setting_use_display_names_for_users', key: 'showUserDisplayNames', category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.theme),
  useDisplayNamesForCommunities(
      name: 'setting_use_display_names_for_communities', key: 'showCommunityDisplayNames', category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.theme),
  markPostAsReadOnMediaView(
      name: 'setting_general_mark_post_read_on_media_view', key: 'markPostAsReadOnMediaView', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.feed),
  markPostAsReadOnScroll(name: 'setting_general_mark_post_read_on_scroll', key: 'markPostAsReadOnScroll', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.feed),
  showInAppUpdateNotification(
      name: 'setting_notifications_show_inapp_update', key: 'showInAppUpdateNotifications', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.notifications),
  showUpdateChangelogs(name: 'setting_show_update_changelogs', key: 'showUpdateChangelogs', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.notifications),
  scoreCounters(name: 'setting_score_counters', key: "showScoreCounters", category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.feed),
  appLanguageCode(name: 'setting_app_language_code', key: 'appLanguage', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.feedTypeAndSorts),
  useProfilePictureForDrawer(
      name: 'setting_use_profile_picture_for_drawer', key: 'useProfilePictureForDrawer', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.feedTypeAndSorts),
  inboxNotificationType(name: 'setting_inbox_notification_type', key: 'inboxNotificationType', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.notifications),
  pushNotificationServer(name: 'setting_push_notification_server', key: 'pushNotificationServer', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.notifications),
  showExpandedTaglines(name: 'setting_feed_show_expanded_taglines', key: 'showExpandedTaglines', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.feed),

  /// -------------------------- Feed Post Related Settings --------------------------
  // Compact Related Settings
  useCompactView(name: 'setting_general_use_compact_view', key: 'compactView', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.posts),
  showPostTitleFirst(name: 'setting_general_show_title_first', key: 'showPostTitleFirst', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.posts),
  hideThumbnails(name: 'setting_general_hide_thumbnails', key: 'hideThumbnails', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.feed),
  showThumbnailPreviewOnRight(
      name: 'setting_compact_show_thumbnail_on_right', key: 'showThumbnailPreviewOnRight', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.posts),
  showTextPostIndicator(name: 'setting_compact_show_text_post_indicator', key: 'showTextPostIndicator', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.posts),
  tappableAuthorCommunity(name: 'setting_compact_tappable_author_community', key: 'tappableAuthorCommunity', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.feed),

  // General Settings
  showPostVoteActions(name: 'setting_general_show_vote_actions', key: 'showPostVoteActions', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.cardView),
  showPostSaveAction(name: 'setting_general_show_save_action', key: 'showPostSaveAction', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.cardView),
  showPostCommunityIcons(name: 'setting_general_show_community_icons', key: 'showPostCommunityIcons', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.cardView),
  showPostFullHeightImages(name: 'setting_general_show_full_height_images', key: 'showFullHeightImages', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.cardView),
  showPostEdgeToEdgeImages(name: 'setting_general_show_edge_to_edge_images', key: 'showEdgeToEdgeImages', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.cardView),
  showPostTextContentPreview(name: 'setting_general_show_text_content', key: 'showPostTextContentPreview', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.cardView),
  showPostAuthor(name: 'setting_general_show_post_author', key: 'showPostAuthor', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.general),
  postShowUserInstance(name: 'setting_general_post_show_user_instance', key: 'postShowUserInstance', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.general),
  dimReadPosts(name: 'setting_dim_read_posts', key: 'dimReadPosts', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.general),
  keywordFilters(name: 'setting_general_keyword_filters', key: 'keywordFilters', category: LocalSettingsCategories.filters, subCategory: LocalSettingsSubCategories.filters),
  hideTopBarOnScroll(name: 'setting_general_hide_topbar_on_scroll', key: 'hideTopBarOnScroll', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.feed),
  showHiddenPosts(name: 'setting_general_show_hidden_posts', key: 'showHiddenPosts', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.feed),
  compactPostCardMetadataItems(
      name: 'setting_compact_post_card_metadata_items', key: 'compactPostCardMetadataItems', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.posts),
  cardPostCardMetadataItems(name: 'setting_card_post_card_metadata_items', key: 'cardPostCardMetadataItems', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.posts),
  showFullPostDate(name: 'setting_general_show_full_post_date', key: 'showFullPostDate', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.posts),
  dateFormat(name: 'setting_general_date_format', key: 'dateFormat', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.posts),
  // This setting exists purely for the searching function
  dividerAppearance(name: '', key: 'dividerAppearance', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.posts),
  feedCardDividerThickness(
      name: 'setting_feed_card_divider_thickness', key: 'feedCardDividerThickness', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.posts, searchable: false),
  feedCardDividerColor(name: 'setting_feed_card_divider_color', key: 'feedCardDividerColor', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.posts, searchable: false),

  // Post body settings
  showCrossPosts(name: 'setting_show_cross_posts', key: 'showCrossPosts', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.general),
  postBodyViewType(name: 'setting_general_post_body_view_type', key: 'postBodyViewType', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.general),
  postBodyShowUserInstance(
      name: 'setting_general_post_body_show_user_instance', key: 'postBodyShowUserInstance', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.general),
  postBodyShowCommunityInstance(
      name: 'setting_general_post_body_show_community_instance', key: 'postBodyShowCommunityInstance', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.general),
  postBodyShowCommunityAvatar(
      name: 'setting_general_post_body_show_community_avatar', key: 'postBodyShowCommunityAvatar', category: LocalSettingsCategories.posts, subCategory: LocalSettingsSubCategories.general),

  // Advanced Settings
  imageCachingMode(name: 'setting_advanced_image_caching_mode', key: 'imageCachingMode', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.advanced),
  showNavigationLabels(name: 'setting_advanced_show_navigation_labels', key: 'showNavigationLabels', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.advanced),

  /// -------------------------- Post Page Related Settings --------------------------
  // Comment Related Settings
  defaultCommentSortType(
      name: 'setting_post_default_comment_sort_type', key: 'defaultCommentSortType', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.feedTypeAndSorts),
  collapseParentCommentBodyOnGesture(
      name: 'setting_comments_collapse_parent_comment_on_gesture',
      key: 'collapseParentCommentBodyOnGesture',
      category: LocalSettingsCategories.general,
      subCategory: LocalSettingsSubCategories.comments),
  showCommentActionButtons(
      name: 'setting_general_show_comment_button_actions', key: 'showCommentActionButtons', category: LocalSettingsCategories.comments, subCategory: LocalSettingsSubCategories.general),
  commentShowUserInstance(name: 'settings_comment_show_user_instance', key: 'showUserInstance', category: LocalSettingsCategories.comments, subCategory: LocalSettingsSubCategories.comments),
  commentShowUserAvatar(name: 'settings_comment_show_user_avatar', key: 'showUserAvatar', category: LocalSettingsCategories.comments, subCategory: LocalSettingsSubCategories.comments),
  combineCommentScores(name: 'setting_general_combine_comment_scores', key: 'combineCommentScores', category: LocalSettingsCategories.comments, subCategory: LocalSettingsSubCategories.comments),
  nestedCommentIndicatorStyle(
      name: 'setting_general_nested_comment_indicator_style', key: 'nestedCommentIndicatorStyle', category: LocalSettingsCategories.comments, subCategory: LocalSettingsSubCategories.comments),
  nestedCommentIndicatorColor(
      name: 'setting_general_nested_comment_indicator_color', key: 'nestedCommentIndicatorColor', category: LocalSettingsCategories.comments, subCategory: LocalSettingsSubCategories.comments),
  // Deprecated, use userFullNameColorizeUserName
  commentUseColorizedUsername(
    name: 'settings_general_comments_colorized_usernames',
    key: 'commentUseColorizedUsername',
    category: LocalSettingsCategories.comments,
    subCategory: LocalSettingsSubCategories.comments,
    searchable: false,
  ),

  /// -------------------------- Accessibility Related Settings --------------------------
  reduceAnimations(name: 'setting_accessibility_reduce_animations', key: 'reduceAnimations', category: LocalSettingsCategories.accessibility, subCategory: LocalSettingsSubCategories.animations),

  /// -------------------------- Theme Related Settings --------------------------
  // Theme Settings
  appTheme(name: 'setting_theme_app_theme', key: 'theme', category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.theme),
  usePureBlackTheme(name: 'setting_theme_system_pure_black', key: 'systemThemePureBlack', category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.theme),
  appThemeAccentColor(name: 'setting_theme_custom_app_theme', key: 'themeAccentColor', category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.theme),
  useMaterialYouTheme(name: 'setting_theme_use_material_you', key: 'useMaterialYouTheme', category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.theme),

  // Color settings
  // The first setting exists purely for searching
  actionColors(name: 'setting_action_colors', key: 'actionColors', category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.theme),
  upvoteColor(name: 'settings_theme_upvote_color', key: 'upvoteColor', searchable: false, category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.theme),
  downvoteColor(name: 'settings_theme_downvote_color', key: 'downvoteColor', searchable: false, category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.theme),
  saveColor(name: 'settings_theme_save_color', key: 'saveColor', searchable: false, category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.theme),
  markReadColor(name: 'settings_theme_mark_read_color', key: 'markReadColor', searchable: false, category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.theme),
  hideColor(name: 'settings_theme_hide_color', key: 'hideColor', searchable: false, category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.theme),
  replyColor(name: 'settings_theme_reply_color', key: 'replyColor', searchable: false, category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.theme),

  // Font Settings
  titleFontSizeScale(name: 'setting_theme_title_font_size_scale', key: 'postTitleFontScale', category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.fonts),
  contentFontSizeScale(name: 'setting_theme_content_font_size_scale', key: 'postContentFontScale', category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.fonts),
  commentFontSizeScale(name: 'setting_theme_comment_font_size_scale', key: 'commentFontScale', category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.fonts),
  metadataFontSizeScale(name: 'setting_theme_metadata_font_size_scale', key: 'metadataFontScale', category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.fonts),

  // Theme > Names
  userFormat(name: 'user_format', key: 'userFormat', category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.names),
  // This setting exists purely for the searching function
  userStyle(name: '', key: 'userStyle', category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.names),
  userFullNameUserNameThickness(
      name: 'user_full_name_user_name_thickness', key: 'userFullNameUserNameThickness', category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.names, searchable: false),
  userFullNameUserNameColor(
      name: 'user_full_name_user_name_color', key: 'userFullNameUserNameColor', category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.names, searchable: false),
  userFullNameInstanceNameThickness(
      name: 'user_full_name_instance_name_thickness',
      key: 'userFullNameInstanceNameThickness',
      category: LocalSettingsCategories.theming,
      subCategory: LocalSettingsSubCategories.names,
      searchable: false),
  userFullNameInstanceNameColor(
      name: 'usr_full_name_instance_name_color', key: 'userFullNameInstanceNameColor', category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.names, searchable: false),

  // This setting exists purely for the searching function
  communityStyle(name: '', key: 'communityStyle', category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.names),
  communityFormat(name: 'community_format', key: 'communityFormat', category: LocalSettingsCategories.theming, subCategory: LocalSettingsSubCategories.names),
  communityFullNameCommunityNameThickness(
      name: 'community_full_name_community_name_thickness',
      key: 'communityFullNameCommunityNameThickness',
      category: LocalSettingsCategories.theming,
      subCategory: LocalSettingsSubCategories.names,
      searchable: false),
  communityFullNameCommunityNameColor(
      name: 'community_full_name_community_name_color',
      key: 'communityFullNameCommunityNameColor',
      category: LocalSettingsCategories.theming,
      subCategory: LocalSettingsSubCategories.names,
      searchable: false),
  communityFullNameInstanceNameThickness(
      name: 'community_full_name_instance_name_thickness',
      key: 'communityFullNameInstanceNameThickness',
      category: LocalSettingsCategories.theming,
      subCategory: LocalSettingsSubCategories.names,
      searchable: false),
  communityFullNameInstanceNameColor(
      name: 'community_full_name_instance_name_color',
      key: 'communityFullNameInstanceNameColor',
      category: LocalSettingsCategories.theming,
      subCategory: LocalSettingsSubCategories.names,
      searchable: false),

  userLabels(name: 'setting_user_labels', key: 'userLabels', category: LocalSettingsCategories.userLabels, subCategory: LocalSettingsSubCategories.userLabels),

  /// -------------------------- Gesture Related Settings --------------------------
  // Sidebar Gesture Settings
  sidebarBottomNavBarSwipeGesture(
      name: 'setting_general_enable_swipe_gestures', key: 'navbarSwipeGestures', category: LocalSettingsCategories.gestures, subCategory: LocalSettingsSubCategories.sidebar),
  sidebarBottomNavBarDoubleTapGesture(
      name: 'setting_general_enable_doubletap_gestures', key: 'navbarDoubleTapGestures', category: LocalSettingsCategories.gestures, subCategory: LocalSettingsSubCategories.sidebar),

  // Post Gesture Settings
  enablePostGestures(name: 'setting_gesture_enable_post_gestures', key: 'postSwipeActions', category: LocalSettingsCategories.gestures, subCategory: LocalSettingsSubCategories.posts),
  postGestureLeftPrimary(name: 'setting_gesture_post_left_primary_gesture', key: 'leftShortSwipe', category: LocalSettingsCategories.gestures, subCategory: LocalSettingsSubCategories.posts),
  postGestureLeftSecondary(name: 'setting_gesture_post_left_secondary_gesture', key: 'leftLongSwipe', category: LocalSettingsCategories.gestures, subCategory: LocalSettingsSubCategories.posts),
  postGestureRightPrimary(name: 'setting_gesture_post_right_primary_gesture', key: 'rightShortSwipe', category: LocalSettingsCategories.gestures, subCategory: LocalSettingsSubCategories.posts),
  postGestureRightSecondary(name: 'setting_gesture_post_right_secondary_gesture', key: 'rightLongSwipe', category: LocalSettingsCategories.gestures, subCategory: LocalSettingsSubCategories.posts),

  // Comment Gesture Settings
  enableCommentGestures(name: 'setting_gesture_enable_comment_gestures', key: 'commentSwipeActions', category: LocalSettingsCategories.gestures, subCategory: LocalSettingsSubCategories.comments),
  commentGestureLeftPrimary(name: 'setting_gesture_comment_left_primary_gesture', key: 'leftShortSwipe', category: LocalSettingsCategories.gestures, subCategory: LocalSettingsSubCategories.comments),
  commentGestureLeftSecondary(
      name: 'setting_gesture_comment_left_secondary_gesture', key: 'leftLongSwipe', category: LocalSettingsCategories.gestures, subCategory: LocalSettingsSubCategories.comments),
  commentGestureRightPrimary(
      name: 'setting_gesture_comment_right_primary_gesture', key: 'rightShortSwipe', category: LocalSettingsCategories.gestures, subCategory: LocalSettingsSubCategories.comments),
  commentGestureRightSecondary(
      name: 'setting_gesture_comment_right_secondary_gesture', key: 'rightLongSwipe', category: LocalSettingsCategories.gestures, subCategory: LocalSettingsSubCategories.comments),

  enableFullScreenSwipeNavigationGesture(
      name: 'setting_gesture_enable_fullscreen_navigation_gesture', key: 'fullscreenSwipeGestures', category: LocalSettingsCategories.gestures, subCategory: LocalSettingsSubCategories.navigation),

  /// -------------------------- FAB Related Settings --------------------------
  enableFeedsFab(name: 'setting_enable_feed_fab', key: 'enableFloatingButtonOnFeeds', category: LocalSettingsCategories.floatingActionButton, subCategory: LocalSettingsSubCategories.feed),
  enablePostsFab(name: 'setting_enable_post_fab', key: 'enableFloatingButtonOnPosts', category: LocalSettingsCategories.floatingActionButton, subCategory: LocalSettingsSubCategories.feed),
  enableBackToTop(name: 'setting_enable_back_to_top_fab', key: 'backToTop', category: LocalSettingsCategories.floatingActionButton, subCategory: LocalSettingsSubCategories.feed),
  enableSubscriptions(name: 'setting_enable_subscribed_fab', key: 'subscriptions', category: LocalSettingsCategories.floatingActionButton, subCategory: LocalSettingsSubCategories.feed),
  enableRefresh(name: 'setting_enable_refresh_fab', key: 'refresh', category: LocalSettingsCategories.floatingActionButton, subCategory: LocalSettingsSubCategories.feed),
  enableDismissRead(name: 'setting_enable_dismiss_read_fab', key: 'dismissRead', category: LocalSettingsCategories.floatingActionButton, subCategory: LocalSettingsSubCategories.feed),
  enableChangeSort(name: 'setting_enable_change_sort_fab', key: 'changeSort', category: LocalSettingsCategories.floatingActionButton, subCategory: LocalSettingsSubCategories.feed),
  enableNewPost(name: 'setting_enable_new_post_fab', key: 'newPost', category: LocalSettingsCategories.floatingActionButton, subCategory: LocalSettingsSubCategories.feed),
  postFabEnableBackToTop(name: 'setting_post_fab_enable_back_to_top', key: 'backToTop', category: LocalSettingsCategories.floatingActionButton, subCategory: LocalSettingsSubCategories.posts),
  postFabEnableChangeSort(name: 'setting_post_fab_enable_change_sort', key: 'changeSort', category: LocalSettingsCategories.floatingActionButton, subCategory: LocalSettingsSubCategories.posts),
  postFabEnableReplyToPost(name: 'setting_post_fab_enable_reply_to_post', key: 'replyToPost', category: LocalSettingsCategories.floatingActionButton, subCategory: LocalSettingsSubCategories.posts),
  postFabEnableRefresh(name: 'setting_post_fab_enable_refresh', key: 'refresh', category: LocalSettingsCategories.floatingActionButton, subCategory: LocalSettingsSubCategories.posts),
  postFabEnableSearch(name: 'setting_post_fab_enable_search', key: 'search', category: LocalSettingsCategories.floatingActionButton, subCategory: LocalSettingsSubCategories.posts),
  feedFabSinglePressAction(name: 'settings_feed_fab_single_press_action', key: '', category: LocalSettingsCategories.floatingActionButton, subCategory: LocalSettingsSubCategories.feed),
  feedFabLongPressAction(name: 'settings_feed_fab_long_press_action', key: '', category: LocalSettingsCategories.floatingActionButton, subCategory: LocalSettingsSubCategories.feed),
  postFabSinglePressAction(name: 'settings_post_fab_single_press_action', key: '', category: LocalSettingsCategories.floatingActionButton, subCategory: LocalSettingsSubCategories.posts),
  postFabLongPressAction(name: 'settings_post_fab_long_press_action', key: '', category: LocalSettingsCategories.floatingActionButton, subCategory: LocalSettingsSubCategories.posts),
  enableCommentNavigation(name: 'setting_enable_comment_navigation', key: 'enableCommentNavigation', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.comments),
  combineNavAndFab(name: 'setting_combine_nav_and_fab', key: 'combineNavAndFab', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.comments),

  enableExperimentalFeatures(
      name: 'setting_enable_experimental_features', key: 'enableExperimentalFeatures', category: LocalSettingsCategories.debug, subCategory: LocalSettingsSubCategories.experimental),
  imageDimensionTimeout(name: 'setting_image_dimension_timeout', key: 'imageDimensionTimeout', category: LocalSettingsCategories.debug, subCategory: LocalSettingsSubCategories.feed),

  currentAnonymousInstance(name: 'setting_current_anonymous_instance', key: '', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.general, searchable: false),

  // This setting exists purely to save/load the user's selected advanced share options
  advancedShareOptions(name: 'advanced_share_options', key: '', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.general, searchable: false),
  // import export settings
  importExportSettings(name: 'import_export_settings', key: 'importExportSettings', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.importExportThunderSettings),
  importExportDatabase(name: 'import_export_database', key: 'importExportDatabase', category: LocalSettingsCategories.general, subCategory: LocalSettingsSubCategories.importExportThunderSettings),
  // video player
  videoAutoMute(name: 'auto_mute_videos', key: 'videoAutoMute', category: LocalSettingsCategories.videoPlayer, subCategory: LocalSettingsSubCategories.videoPlayer),
  videoDefaultPlaybackSpeed(name: 'video_default_playback_speed', key: 'videoDefaultPlaybackSpeed', category: LocalSettingsCategories.videoPlayer, subCategory: LocalSettingsSubCategories.videoPlayer),
  videoAutoFullscreen(name: 'video_auto_fullscreen', key: 'videoAutoFullscreen', category: LocalSettingsCategories.videoPlayer, subCategory: LocalSettingsSubCategories.videoPlayer),
  videoAutoLoop(name: 'video_auto_loop', key: '', category: LocalSettingsCategories.videoPlayer, subCategory: LocalSettingsSubCategories.videoPlayer),
  videoAutoPlay(name: 'video_auto_play', key: '', category: LocalSettingsCategories.videoPlayer, subCategory: LocalSettingsSubCategories.videoPlayer),
  videoPlayerMode(name: 'setting_video_player_mode', key: 'videoPlayerMode', category: LocalSettingsCategories.videoPlayer, subCategory: LocalSettingsSubCategories.videoPlayer),

  // Searchable settings
  // The settings under this section do not correspond to settings that we persist in SharedPreferences.
  // Rather these entries exist simply so that we can link/search these settings.
  accountDisplayName(name: 'account_display_name', key: 'accountDisplayName', category: LocalSettingsCategories.account, subCategory: LocalSettingsSubCategories.general),
  accountProfileBio(name: 'account_profile_bio', key: 'accountProfileBio', category: LocalSettingsCategories.account, subCategory: LocalSettingsSubCategories.general),
  accountEmail(name: 'account_email', key: 'accountEmail', category: LocalSettingsCategories.account, subCategory: LocalSettingsSubCategories.general),
  accountMatrixUser(name: 'account_matrix_user', key: 'accountMatrixUser', category: LocalSettingsCategories.account, subCategory: LocalSettingsSubCategories.general),
  accountDefaultFeedType(name: 'account_default_feed_type', key: 'accountDefaultFeedType', category: LocalSettingsCategories.account, subCategory: LocalSettingsSubCategories.feed),
  accountDefaultFeedSortType(name: 'account_default_feed_sort_type', key: 'accountDefaultFeedSortType', category: LocalSettingsCategories.account, subCategory: LocalSettingsSubCategories.feed),
  accountShowNsfwContent(name: 'account_show_nsfw_content', key: 'accountShowNsfwContent', category: LocalSettingsCategories.account, subCategory: LocalSettingsSubCategories.feed),
  accountShowScores(name: 'account_show_scores', key: 'accountShowScores', category: LocalSettingsCategories.account, subCategory: LocalSettingsSubCategories.feed),
  accountShowReadPosts(name: 'account_show_read_posts', key: 'accountShowReadPosts', category: LocalSettingsCategories.account, subCategory: LocalSettingsSubCategories.feed),
  accountIsBot(name: 'account_is_bot', key: 'accountIsBot', category: LocalSettingsCategories.account, subCategory: LocalSettingsSubCategories.feed),
  accountShowBotAccounts(name: 'account_show_bot_accounts', key: 'accountShowBotAccounts', category: LocalSettingsCategories.account, subCategory: LocalSettingsSubCategories.feed),
  accountBlocks(name: 'account_blocks', key: 'accountBlocks', category: LocalSettingsCategories.account, subCategory: LocalSettingsSubCategories.contentManagement),
  accountChangePassword(name: 'account_change_password', key: 'accountChangePassword', category: LocalSettingsCategories.account, subCategory: LocalSettingsSubCategories.dangerZone),
  accountImportSettings(
      name: 'account_import_settings', key: 'accountImportSettings', category: LocalSettingsCategories.account, subCategory: LocalSettingsSubCategories.importExportLemmyAccountSettings),
  accountExportSettings(
      name: 'account_export_settings', key: 'accountExportSettings', category: LocalSettingsCategories.account, subCategory: LocalSettingsSubCategories.importExportLemmyAccountSettings),
  accountDeleteAccount(name: 'account_delete_account', key: 'accountDeleteAccount', category: LocalSettingsCategories.account, subCategory: LocalSettingsSubCategories.dangerZone),
  accountManageMedia(name: 'account_manage_media', key: 'accountManageMedia', category: LocalSettingsCategories.account, subCategory: LocalSettingsSubCategories.dangerZone),
  debugDeleteLocalPreferences(name: 'debug_delete_local_preferences', key: 'debugDeleteLocalPreferences', category: LocalSettingsCategories.debug, subCategory: LocalSettingsSubCategories.reset),
  debugDeleteLocalDatabase(name: 'debug_delete_local_database', key: 'debugDeleteLocalDatabase', category: LocalSettingsCategories.debug, subCategory: LocalSettingsSubCategories.reset),
  debugClearCache(name: 'debug_clear_cache', key: 'debugClearCache', category: LocalSettingsCategories.debug, subCategory: LocalSettingsSubCategories.reset),
  debugSendTestLocalNotification(
      name: 'debug_send_test_local_notification', key: 'debugSendTestLocalNotification', category: LocalSettingsCategories.debug, subCategory: LocalSettingsSubCategories.notifications),
  debugSendBackgroundTestLocalNotification(
      name: 'debug_send_background_test_local_notification',
      key: 'debugSendBackgroundTestLocalNotification',
      category: LocalSettingsCategories.debug,
      subCategory: LocalSettingsSubCategories.notifications),
  debugSendTestUnifiedPushNotification(
      name: 'debug_send_test_unifiedpush_notification', key: 'debugSendTestUnifiedPushNotification', category: LocalSettingsCategories.debug, subCategory: LocalSettingsSubCategories.notifications),
  debugSendBackgroundTestUnifiedPushNotification(
      name: 'debug_send_background_test_unifiedpush_notification',
      key: 'debugSendBackgroundTestUnifiedPushNotification',
      category: LocalSettingsCategories.debug,
      subCategory: LocalSettingsSubCategories.notifications);

  const LocalSettings({
    required this.name,
    required this.category,
    required this.subCategory,
    required this.key,
    this.searchable = true,
  });

  /// The name of the setting as stored in local preferences
  final String name;

  /// Describes the key to be used to determine the localized label
  final String key;

  /// Represents the category to which the settings belong and indicates
  /// where it appears in the settings interface.
  final LocalSettingsCategories category;

  /// Represents a key used to uniquely identify the settings subcategory.
  /// This key is essential for organizing and managing specific settings.
  final LocalSettingsSubCategories subCategory;

  /// Whether this setting should appear as a search result
  final bool searchable;

  /// Defines the settings that are excluded from import/export
  static List<LocalSettings> importExportExcludedSettings = [
    LocalSettings.currentAnonymousInstance,
    LocalSettings.advancedShareOptions,
  ];
}

extension LocalizationExt on AppLocalizations {
  String getLocalSettingLocalization(String key) {
    Map<String, String> localizationMap = {
      'defaultFeedType': defaultFeedType,
      'defaultFeedSortType': defaultFeedSortType,
      'hideNsfwPostsFromFeed': hideNsfwPostsFromFeed,
      'hideNsfwPreviews': hideNsfwPreviews,
      'tabletMode': tabletMode,
      'scrapeMissingLinkPreviews': scrapeMissingLinkPreviews,
      'openLinksInExternalBrowser': openLinksInExternalBrowser,
      'browserMode': browserMode,
      'openByDefault': openByDefault,
      'openLinksInReaderMode': openLinksInReaderMode,
      'showUserDisplayNames': showUserDisplayNames,
      'showCommunityDisplayNames': showCommunityDisplayNames,
      'markPostAsReadOnMediaView': markPostAsReadOnMediaView,
      'markPostAsReadOnScroll': markPostAsReadOnScroll,
      'showInAppUpdateNotifications': showInAppUpdateNotifications,
      'showUpdateChangelogs': showUpdateChangelogs,
      'inboxNotificationType': enableInboxNotifications,
      'pushNotificationServer': pushNotificationServer,
      'showExpandedTaglines': showExpandedTaglines,
      'showScoreCounters': showScoreCounters,
      'appLanguage': appLanguage,
      'compactView': compactView,
      'showPostTitleFirst': showPostTitleFirst,
      'hideThumbnails': hideThumbnails,
      'showThumbnailPreviewOnRight': showThumbnailPreviewOnRight,
      'showTextPostIndicator': showTextPostIndicator,
      'tappableAuthorCommunity': tappableAuthorCommunity,
      'postBodyViewType': postBodyViewType,
      'showPostVoteActions': showPostVoteActions,
      'showPostSaveAction': showPostSaveAction,
      'showPostCommunityIcons': showPostCommunityIcons,
      'showFullHeightImages': showFullHeightImages,
      'showEdgeToEdgeImages': showEdgeToEdgeImages,
      'showPostTextContentPreview': showPostTextContentPreview,
      'showPostAuthor': showPostAuthor,
      'postShowUserInstance': postShowUserInstance,
      'dimReadPosts': dimReadPosts,
      'showFullPostDate': showFullDate,
      'dateFormat': dateFormat,
      'dividerAppearance': dividerAppearance,
      'showCrossPosts': showCrossPosts,
      'postBodyShowUserInstance': postBodyShowUserInstance,
      'postBodyShowCommunityInstance': postBodyShowCommunityInstance,
      'postBodyShowCommunityAvatar': postBodyShowCommunityAvatar,
      'keywordFilters': keywordFilters,
      'hideTopBarOnScroll': hideTopBarOnScroll,
      'showHiddenPosts': showHiddenPosts,
      'compactPostCardMetadataItems': compactPostCardMetadataItems,
      'cardPostCardMetadataItems': cardPostCardMetadataItems,
      'userFormat': userFormat,
      'userStyle': userStyle,
      'communityFormat': communityFormat,
      'communityStyle': communityStyle,
      'imageCachingMode': imageCachingMode,
      'showNavigationLabels': showNavigationLabels,
      'defaultCommentSortType': defaultCommentSortType,
      'useProfilePictureForDrawer': useProfilePictureForDrawer,
      'collapseParentCommentBodyOnGesture': collapseParentCommentBodyOnGesture,
      'showCommentActionButtons': showCommentActionButtons,
      'showUserInstance': showUserInstance,
      'showUserAvatar': showUserAvatar,
      'combineCommentScores': combineCommentScores,
      'nestedCommentIndicatorStyle': nestedCommentIndicatorStyle,
      'nestedCommentIndicatorColor': nestedCommentIndicatorColor,
      'reduceAnimations': reduceAnimations,
      'theme': theme,
      'systemThemePureBlack': systemDarkMode,
      'themeAccentColor': themeAccentColor,
      'useMaterialYouTheme': useMaterialYouTheme,
      'actionColors': actionColors,
      'postTitleFontScale': postTitleFontScale,
      'postContentFontScale': postContentFontScale,
      'commentFontScale': commentFontScale,
      'metadataFontScale': metadataFontScale,
      'navbarSwipeGestures': navbarSwipeGestures,
      'navbarDoubleTapGestures': navbarDoubleTapGestures,
      'postSwipeActions': postSwipeActions,
      'leftShortSwipe': leftShortSwipe,
      'leftLongSwipe': leftLongSwipe,
      'rightShortSwipe': rightShortSwipe,
      'rightLongSwipe': rightLongSwipe,
      'commentSwipeActions': commentSwipeActions,
      'fullscreenSwipeGestures': fullscreenSwipeGestures,
      'enableFloatingButtonOnFeeds': enableFloatingButtonOnFeeds,
      'enableFloatingButtonOnPosts': enableFloatingButtonOnPosts,
      'backToTop': backToTop,
      'subscriptions': subscriptions,
      'refresh': refresh,
      'dismissRead': dismissRead,
      'changeSort': changeSort,
      'newPost': newPost,
      'replyToPost': replyToPost,
      'search': search,
      'enableCommentNavigation': enableCommentNavigation,
      'combineNavAndFab': combineNavAndFab,
      'floatingActionButton': floatingActionButton,
      'general': general,
      'feed': feed,
      'posts': posts,
      'comments': comments,
      'linksBehaviourSettings': linksBehaviourSettings,
      'importExportSettings': importExportThunderSettings,
      'importExportDatabase': importExportDatabase,
      'advanced': advanced,
      'names': names,
      'notifications': notifications(1),
      'sidebar': sidebar,
      'cardView': cardView,
      'navigation': navigation,
      'fonts': fonts,
      'filters': filters,
      'blockedCommunities': blockedCommunities,
      'feedTypeAndSorts': feedTypeAndSorts,
      'profiles': profiles,
      'animations': animations,
      'discussionLanguages': discussionLanguages,
      'videoAutoMute': videoAutoMute,
      'videoAutoFullscreen': videoAutoFullscreen,
      'videoAutoLoop': videoAutoLoop,
      'videoAutoPlay': videoAutoPlay,
      'videoDefaultPlaybackSpeed': videoDefaultPlaybackSpeed,
      'videoPlayerMode': videoPlayerMode,
      'userLabels': userLabels,
      'accountDisplayName': displayName,
      'accountProfileBio': profileBio,
      'accountEmail': email,
      'accountMatrixUser': matrixUser,
      'accountDefaultFeedType': defaultFeedType,
      'accountDefaultFeedSortType': defaultFeedSortType,
      'accountShowNsfwContent': showNsfwContent,
      'accountShowScores': showScoreCounters,
      'accountShowReadPosts': showReadPosts,
      'accountIsBot': bot,
      'accountShowBotAccounts': showBotAccounts,
      'accountDiscussionLanguages': discussionLanguages,
      'contentManagement': contentManagement,
      'accountBlocks': blockSettingLabel,
      'accountChangePassword': changePassword,
      'importExportLemmyAccountSettings': importExportLemmyAccountSettings,
      'dangerZone': dangerZone,
      'accountDeleteAccount': deleteAccount,
      'accountManageMedia': manageMedia,
      'reset': resetPreferencesAndData,
      'debugDeleteLocalPreferences': deleteLocalPreferences,
      'debugDeleteLocalDatabase': deleteLocalDatabase,
      'debugClearCache': clearCacheLabel,
      'debugSendTestLocalNotification': sendTestLocalNotification,
      'debugSendBackgroundTestLocalNotification': sendBackgroundTestLocalNotification,
      'debugSendTestUnifiedPushNotification': sendTestUnifiedPushNotification,
      'debugSendBackgroundTestUnifiedPushNotification': sendBackgroundTestUnifiedPushNotification,
      'enableExperimentalFeatures': enableExperimentalFeatures,
      'experimental': experimentalFeatures,
      'imageDimensionTimeout': imageDimensionTimeout,
      'accountImportSettings': importLemmyAccountSettingsDescription,
      'accountExportSettings': exportLemmyAccountSettingsDescription,
    };

    if (localizationMap.containsKey(key)) {
      return localizationMap[key]!;
    } else {
      return key;
    }
  }
}
