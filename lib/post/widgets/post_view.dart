import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:lemmy_api_client/v3.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

import 'package:thunder/account/bloc/account_bloc.dart' as account_bloc;
import 'package:thunder/account/bloc/account_bloc.dart';
import 'package:thunder/community/pages/create_post_page.dart';
import 'package:thunder/community/utils/post_card_action_helpers.dart';
import 'package:thunder/community/widgets/post_card_metadata.dart';
import 'package:thunder/core/enums/font_scale.dart';
import 'package:thunder/core/enums/local_settings.dart';
import 'package:thunder/core/singletons/lemmy_client.dart';
import 'package:thunder/core/singletons/preferences.dart';
import 'package:thunder/feed/bloc/feed_bloc.dart';
import 'package:thunder/feed/utils/utils.dart';
import 'package:thunder/feed/view/feed_page.dart';
import 'package:thunder/post/pages/create_comment_page.dart';
import 'package:thunder/shared/advanced_share_sheet.dart';
import 'package:thunder/shared/common_markdown_body.dart';
import 'package:thunder/thunder/bloc/thunder_bloc.dart';
import 'package:thunder/core/auth/bloc/auth_bloc.dart';
import 'package:thunder/core/models/post_view_media.dart';
import 'package:thunder/post/bloc/post_bloc.dart';
import 'package:thunder/shared/media_view.dart';
import 'package:thunder/thunder/thunder_icons.dart';
import 'package:thunder/user/utils/special_user_checks.dart';
import 'package:thunder/utils/instance.dart';
import 'package:thunder/utils/navigate_user.dart';
import 'package:thunder/utils/numbers.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:thunder/shared/snackbar.dart';

class PostSubview extends StatelessWidget {
  final PostViewMedia postViewMedia;
  final bool useDisplayNames;
  final int? selectedCommentId;
  final List<CommunityModeratorView>? moderators;

  const PostSubview({
    super.key,
    this.selectedCommentId,
    required this.useDisplayNames,
    required this.postViewMedia,
    required this.moderators,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool useAdvancedShareSheet = context.read<ThunderBloc>().state.useAdvancedShareSheet;

    final PostView postView = postViewMedia.postView;
    final Post post = postView.post;

    final bool isUserLoggedIn = context.read<AuthBloc>().state.isLoggedIn;
    final bool downvotesEnabled = context.read<AuthBloc>().state.downvotesEnabled;
    final ThunderState thunderState = context.read<ThunderBloc>().state;

    final bool scrapeMissingPreviews = thunderState.scrapeMissingPreviews;
    final bool hideNsfwPreviews = thunderState.hideNsfwPreviews;
    final bool markPostReadOnMediaView = thunderState.markPostReadOnMediaView;

    final bool isOwnPost = postView.creator.id == context.read<AuthBloc>().state.account?.userId;

    return Padding(
      padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              HtmlUnescape().convert(post.name),
              textScaleFactor: MediaQuery.of(context).textScaleFactor * thunderState.titleFontSizeScale.textScaleFactor,
              style: theme.textTheme.titleMedium,
            ),
          ),
          MediaView(
            scrapeMissingPreviews: scrapeMissingPreviews,
            post: post,
            postView: postViewMedia,
            hideNsfwPreviews: hideNsfwPreviews,
            markPostReadOnMediaView: markPostReadOnMediaView,
            isUserLoggedIn: isUserLoggedIn,
          ),
          if (postViewMedia.postView.post.body != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: CommonMarkdownBody(
                body: post.body ?? '',
              ),
            ),
          Padding(
            padding: EdgeInsets.only(left: isSpecialUser(context, isOwnPost, post, null, postView.creator, moderators) ? 8.0 : 3.0, right: 8.0, top: 16.0),
            child: Row(
              // Row for post view: author, community, comment count and post time
              children: [
                Tooltip(
                  excludeFromSemantics: true,
                  message: '${postView.creator.name}@${fetchInstanceNameFromUrl(postView.creator.actorId) ?? '-'}${fetchUsernameDescriptor(isOwnPost, post, null, postView.creator, moderators)}',
                  preferBelow: false,
                  child: Material(
                    color: isSpecialUser(context, isOwnPost, post, null, postView.creator, moderators)
                        ? fetchUsernameColor(context, isOwnPost, post, null, postView.creator, moderators) ?? theme.colorScheme.onBackground
                        : Colors.transparent,
                    borderRadius: isSpecialUser(context, isOwnPost, post, null, postView.creator, moderators) ? const BorderRadius.all(Radius.elliptical(5, 5)) : null,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(5),
                      onTap: () {
                        navigateToUserPage(context, userId: postView.creator.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5, right: 5),
                        child: Row(
                          children: [
                            Text(
                              postView.creator.displayName != null && useDisplayNames ? postView.creator.displayName! : postView.creator.name,
                              textScaleFactor: MediaQuery.of(context).textScaleFactor * thunderState.metadataFontSizeScale.textScaleFactor,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: (isSpecialUser(context, isOwnPost, post, null, postView.creator, moderators) ? theme.colorScheme.onBackground : theme.textTheme.bodyMedium?.color)
                                    ?.withOpacity(0.75),
                              ),
                            ),
                            if (isSpecialUser(context, isOwnPost, post, null, postView.creator, moderators)) const SizedBox(width: 2.0),
                            if (isOwnPost)
                              Padding(
                                padding: const EdgeInsets.only(left: 1),
                                child: Icon(
                                  Icons.person,
                                  size: 15.0 * thunderState.metadataFontSizeScale.textScaleFactor,
                                  color: theme.colorScheme.onBackground,
                                ),
                              ),
                            if (isAdmin(postView.creator))
                              Padding(
                                padding: const EdgeInsets.only(left: 1),
                                child: Icon(
                                  Thunder.shield_crown,
                                  size: 14.0 * thunderState.metadataFontSizeScale.textScaleFactor,
                                  color: theme.colorScheme.onBackground,
                                ),
                              ),
                            if (isModerator(postView.creator, moderators))
                              Padding(
                                padding: const EdgeInsets.only(left: 1),
                                child: Icon(
                                  Thunder.shield,
                                  size: 14.0 * thunderState.metadataFontSizeScale.textScaleFactor,
                                  color: theme.colorScheme.onBackground,
                                ),
                              ),
                            if (isBot(postView.creator))
                              Padding(
                                padding: const EdgeInsets.only(left: 1, right: 2),
                                child: Icon(
                                  Thunder.robot,
                                  size: 13.0 * thunderState.metadataFontSizeScale.textScaleFactor,
                                  color: theme.colorScheme.onBackground,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (isSpecialUser(context, isOwnPost, post, null, postView.creator, moderators)) const SizedBox(width: 8.0),
                Text(
                  'to',
                  textScaleFactor: MediaQuery.of(context).textScaleFactor * thunderState.metadataFontSizeScale.textScaleFactor,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(5),
                  onTap: () {
                    navigateToFeedPage(context, feedType: FeedType.community, communityId: postView.community.id);
                  },
                  child: Tooltip(
                    excludeFromSemantics: true,
                    message: '${postView.community.name}@${fetchInstanceNameFromUrl(postView.community.actorId) ?? 'N/A'}',
                    preferBelow: false,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 5, right: 5),
                      child: Text(
                        postView.community.name,
                        textScaleFactor: MediaQuery.of(context).textScaleFactor * thunderState.metadataFontSizeScale.textScaleFactor,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(), // use Spacer
                Padding(
                  padding: const EdgeInsets.only(right: 0.0),
                  child: PostViewMetaData(
                    comments: postViewMedia.postView.counts.comments,
                    unreadComments: postViewMedia.postView.unreadComments,
                    hasBeenEdited: postViewMedia.postView.post.updated != null ? true : false,
                    published: post.published,
                    saved: postView.saved,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 1,
                child: TextButton(
                  onPressed: isUserLoggedIn
                      ? () {
                          HapticFeedback.mediumImpact();
                          context.read<PostBloc>().add(VotePostEvent(postId: post.id, score: postView.myVote == 1 ? 0 : 1));
                        }
                      : null,
                  style: TextButton.styleFrom(
                    fixedSize: const Size.fromHeight(40),
                    foregroundColor: postView.myVote == 1 ? theme.textTheme.bodyMedium?.color : Colors.orange,
                    padding: EdgeInsets.zero,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        semanticLabel: postView.myVote == 1 ? 'Upvoted' : 'Upvote',
                        color: isUserLoggedIn ? (postView.myVote == 1 ? Colors.orange : theme.textTheme.bodyMedium?.color) : null,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        formatNumberToK(postViewMedia.postView.counts.upvotes),
                        style: TextStyle(
                          color: isUserLoggedIn ? (postView.myVote == 1 ? Colors.orange : theme.textTheme.bodyMedium?.color) : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (downvotesEnabled)
                Expanded(
                  flex: 1,
                  child: TextButton(
                    onPressed: isUserLoggedIn
                        ? () {
                            HapticFeedback.mediumImpact();
                            context.read<PostBloc>().add(VotePostEvent(postId: post.id, score: postView.myVote == -1 ? 0 : -1));
                          }
                        : null,
                    style: TextButton.styleFrom(
                      fixedSize: const Size.fromHeight(40),
                      foregroundColor: postView.myVote == -1 ? theme.textTheme.bodyMedium?.color : Colors.blue,
                      padding: EdgeInsets.zero,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_downward,
                          semanticLabel: postView.myVote == 1 ? 'Downvoted' : 'Downvote',
                          color: isUserLoggedIn ? (postView.myVote == -1 ? Colors.blue : theme.textTheme.bodyMedium?.color) : null,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          formatNumberToK(postViewMedia.postView.counts.downvotes),
                          style: TextStyle(
                            color: isUserLoggedIn ? (postView.myVote == -1 ? Colors.blue : theme.textTheme.bodyMedium?.color) : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                flex: 1,
                child: IconButton(
                  onPressed: isUserLoggedIn
                      ? () {
                          HapticFeedback.mediumImpact();
                          context.read<PostBloc>().add(SavePostEvent(postId: post.id, save: !postView.saved));
                        }
                      : null,
                  icon: Icon(
                    postView.saved ? Icons.star_rounded : Icons.star_border_rounded,
                    semanticLabel: postView.saved ? 'Saved' : 'Save',
                    color: isUserLoggedIn ? (postView.saved ? Colors.purple : theme.textTheme.bodyMedium?.color) : null,
                  ),
                  style: IconButton.styleFrom(
                    foregroundColor: postView.saved ? null : Colors.purple,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: IconButton(
                  onPressed: isUserLoggedIn
                      ? () async {
                          if (postView.post.locked) {
                            showSnackbar(context, AppLocalizations.of(context)!.postLocked);
                            return;
                          }

                          if (isOwnPost) {
                            ThunderBloc thunderBloc = context.read<ThunderBloc>();
                            AccountBloc accountBloc = context.read<AccountBloc>();

                            final ThunderState thunderState = context.read<ThunderBloc>().state;
                            final bool reduceAnimations = thunderState.reduceAnimations;

                            SharedPreferences prefs = (await UserPreferences.instance).sharedPreferences;
                            DraftPost? newDraftPost;
                            DraftPost? previousDraftPost;
                            String draftId = '${LocalSettings.draftsCache.name}-post-edit-${postViewMedia.postView.post.id}';
                            String? draftPostJson = prefs.getString(draftId);
                            if (draftPostJson != null) {
                              previousDraftPost = DraftPost.fromJson(jsonDecode(draftPostJson));
                            }
                            Timer timer = Timer.periodic(const Duration(seconds: 10), (Timer t) {
                              if (newDraftPost?.isNotEmpty == true) {
                                prefs.setString(draftId, jsonEncode(newDraftPost!.toJson()));
                              }
                            });

                            if (context.mounted) {
                              Navigator.of(context)
                                  .push(
                                SwipeablePageRoute(
                                  transitionDuration: reduceAnimations ? const Duration(milliseconds: 100) : null,
                                  canOnlySwipeFromEdge: true,
                                  backGestureDetectionWidth: 45,
                                  builder: (context) {
                                    return MultiBlocProvider(
                                      providers: [
                                        BlocProvider<FeedBloc>.value(value: FeedBloc(lemmyClient: LemmyClient.instance)),
                                        BlocProvider<ThunderBloc>.value(value: thunderBloc),
                                        BlocProvider<AccountBloc>.value(value: accountBloc),
                                      ],
                                      child: CreatePostPage(
                                        communityId: postViewMedia.postView.community.id,
                                        //communityView: postViewMedia.postView.community, // TODO
                                        previousDraftPost: previousDraftPost,
                                        onUpdateDraft: (p) => newDraftPost = p,
                                        isEdit: true,
                                        postView: postViewMedia.postView,
                                      ),
                                    );
                                  },
                                ),
                              )
                                  .whenComplete(() async {
                                timer.cancel();

                                if (newDraftPost?.saveAsDraft == true &&
                                    newDraftPost?.isNotEmpty == true &&
                                    (newDraftPost?.title != postViewMedia.postView.post.name ||
                                        newDraftPost?.text != postViewMedia.postView.post.body ||
                                        newDraftPost?.url != postViewMedia.postView.post.url)) {
                                  await Future.delayed(const Duration(milliseconds: 300));
                                  if (context.mounted) showSnackbar(context, AppLocalizations.of(context)!.postSavedAsDraft);
                                  prefs.setString(draftId, jsonEncode(newDraftPost!.toJson()));
                                } else {
                                  prefs.remove(draftId);
                                }
                              });
                            }
                            return;
                          }

                          PostBloc postBloc = context.read<PostBloc>();
                          ThunderBloc thunderBloc = context.read<ThunderBloc>();
                          account_bloc.AccountBloc accountBloc = context.read<account_bloc.AccountBloc>();

                          final ThunderState state = context.read<ThunderBloc>().state;
                          final bool reduceAnimations = state.reduceAnimations;

                          SharedPreferences prefs = (await UserPreferences.instance).sharedPreferences;
                          DraftComment? newDraftComment;
                          DraftComment? previousDraftComment;
                          String draftId = '${LocalSettings.draftsCache.name}-${postViewMedia.postView.post.id}';
                          String? draftCommentJson = prefs.getString(draftId);
                          if (draftCommentJson != null) {
                            previousDraftComment = DraftComment.fromJson(jsonDecode(draftCommentJson));
                          }
                          Timer timer = Timer.periodic(const Duration(seconds: 10), (Timer t) {
                            if (newDraftComment?.isNotEmpty == true) {
                              prefs.setString(draftId, jsonEncode(newDraftComment!.toJson()));
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
                                    BlocProvider<PostBloc>.value(value: postBloc),
                                    BlocProvider<ThunderBloc>.value(value: thunderBloc),
                                    BlocProvider<account_bloc.AccountBloc>.value(value: accountBloc),
                                  ],
                                  child: CreateCommentPage(
                                    postView: postViewMedia,
                                    previousDraftComment: previousDraftComment,
                                    onUpdateDraft: (c) => newDraftComment = c,
                                  ),
                                );
                              },
                            ),
                          )
                              .whenComplete(() async {
                            timer.cancel();

                            if (newDraftComment?.saveAsDraft == true && newDraftComment?.isNotEmpty == true) {
                              await Future.delayed(const Duration(milliseconds: 300));
                              showSnackbar(context, AppLocalizations.of(context)!.commentSavedAsDraft);
                              prefs.setString(draftId, jsonEncode(newDraftComment!.toJson()));
                            } else {
                              prefs.remove(draftId);
                            }
                          });
                        }
                      : null,
                  icon: postView.post.locked
                      ? Icon(Icons.lock, semanticLabel: AppLocalizations.of(context)!.postLocked, color: Colors.red)
                      : isOwnPost
                          ? const Icon(Icons.edit_rounded)
                          : Icon(Icons.reply_rounded, semanticLabel: AppLocalizations.of(context)!.reply(0)),
                ),
              ),
              Expanded(
                flex: 1,
                child: IconButton(
                  icon: const Icon(Icons.share_rounded, semanticLabel: 'Share'),
                  onPressed: useAdvancedShareSheet
                      ? () => showAdvancedShareSheet(context, postViewMedia)
                      : postViewMedia.media.isEmpty
                          ? () => Share.share(post.apId)
                          : () => showPostActionBottomModalSheet(
                                context,
                                postViewMedia,
                                actionsToInclude: [PostCardAction.sharePost, PostCardAction.shareMedia, PostCardAction.shareLink],
                              ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
