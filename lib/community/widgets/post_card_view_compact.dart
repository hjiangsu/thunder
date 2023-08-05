import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lemmy_api_client/v3.dart';
import 'package:thunder/account/bloc/account_bloc.dart';

import 'package:thunder/community/utils/post_card_action_helpers.dart';
import 'package:thunder/community/widgets/post_card_metadata.dart';
import 'package:thunder/core/enums/font_scale.dart';
import 'package:thunder/core/enums/view_mode.dart';
import 'package:thunder/core/models/post_view_media.dart';
import 'package:thunder/shared/media_view.dart';
import 'package:thunder/thunder/bloc/thunder_bloc.dart';

class PostCardViewCompact extends StatelessWidget {
  final PostViewMedia postViewMedia;
  final bool showThumbnailPreviewOnRight;
  final bool showTextPostIndicator;
  final bool showPostAuthor;
  final bool hideNsfwPreviews;
  final bool showInstanceName;
  final bool markPostReadOnMediaView;
  final bool isUserLoggedIn;
  final PostListingType? listingType;

  const PostCardViewCompact({
    super.key,
    required this.postViewMedia,
    required this.showThumbnailPreviewOnRight,
    required this.showTextPostIndicator,
    required this.showPostAuthor,
    required this.hideNsfwPreviews,
    required this.showInstanceName,
    required this.markPostReadOnMediaView,
    required this.isUserLoggedIn,
    required this.listingType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ThunderState state = context.read<ThunderBloc>().state;

    final showCommunitySubscription = (listingType == PostListingType.all || listingType == PostListingType.local) &&
        isUserLoggedIn &&
        context.read<AccountBloc>().state.subsciptions.map((subscription) => subscription.community.actorId).contains(postViewMedia.postView.community.actorId);

    final TextStyle? textStyleCommunityAndAuthor = theme.textTheme.bodyMedium?.copyWith(
      color: postViewMedia.postView.read ? theme.textTheme.bodyMedium?.color?.withOpacity(0.55) : theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
    );

    final Color? readColor = postViewMedia.postView.read ? theme.textTheme.bodyMedium?.color?.withOpacity(0.55) : theme.textTheme.bodyMedium?.color?.withOpacity(0.90);
    final double textScaleFactor = state.titleFontSizeScale.textScaleFactor;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8.0,
        top: 6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!showThumbnailPreviewOnRight && (postViewMedia.media.isNotEmpty || showTextPostIndicator))
            ExcludeSemantics(
              child: MediaView(
                showLinkPreview: state.showLinkPreviews,
                postView: postViewMedia,
                showFullHeightImages: false,
                hideNsfwPreviews: hideNsfwPreviews,
                markPostReadOnMediaView: markPostReadOnMediaView,
                viewMode: ViewMode.compact,
                isUserLoggedIn: isUserLoggedIn,
              ),
            ),
          if (!showThumbnailPreviewOnRight && (postViewMedia.media.isNotEmpty || showTextPostIndicator)) const SizedBox(width: 8.0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10.0, left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: postViewMedia.postView.post.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14.2 * state.titleFontSizeScale.textScaleFactor,
                            fontWeight: FontWeight.w600,
                            color: postViewMedia.postView.post.featuredCommunity
                                ? (postViewMedia.postView.read ? Colors.green.withOpacity(0.65) : Colors.green)
                                : (postViewMedia.postView.read ? theme.textTheme.bodyMedium?.color?.withOpacity(0.65) : null),
                          ),
                        ),
                        if (postViewMedia.postView.post.featuredCommunity)
                          WidgetSpan(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 8.0,
                              ),
                              child: Icon(
                                Icons.push_pin_rounded,
                                size: 17.0 * textScaleFactor,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        if (postViewMedia.postView.saved)
                          WidgetSpan(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 8.0,
                              ),
                              child: Icon(
                                Icons.star_rounded,
                                color: Colors.purple,
                                size: 16.0 * textScaleFactor,
                                semanticLabel: 'Saved',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  PostCommunityAndAuthor(
                    showCommunityIcons: false,
                    showInstanceName: showInstanceName,
                    postView: postViewMedia.postView,
                    textStyleCommunity: textStyleCommunityAndAuthor,
                    textStyleAuthor: textStyleCommunityAndAuthor,
                    showCommunitySubscription: showCommunitySubscription,
                  ),
                  const SizedBox(height: 6.0),
                  PostCardMetaData(
                    readColor: readColor,
                    score: postViewMedia.postView.counts.score,
                    voteType: postViewMedia.postView.myVote ?? VoteType.none,
                    comments: postViewMedia.postView.counts.comments,
                    unreadComments: postViewMedia.postView.unreadComments,
                    hasBeenEdited: postViewMedia.postView.post.updated != null ? true : false,
                    published: postViewMedia.postView.post.updated != null ? postViewMedia.postView.post.updated! : postViewMedia.postView.post.published,
                    hostURL: postViewMedia.media.firstOrNull != null ? postViewMedia.media.first.originalUrl : null,
                  ),
                ],
              ),
            ),
          ),
          if (showThumbnailPreviewOnRight && (postViewMedia.media.isNotEmpty || showTextPostIndicator))
            if (showThumbnailPreviewOnRight && (postViewMedia.media.isNotEmpty || showTextPostIndicator))
              ExcludeSemantics(
                child: MediaView(
                  showLinkPreview: state.showLinkPreviews,
                  postView: postViewMedia,
                  showFullHeightImages: false,
                  hideNsfwPreviews: hideNsfwPreviews,
                  markPostReadOnMediaView: markPostReadOnMediaView,
                  viewMode: ViewMode.compact,
                  isUserLoggedIn: isUserLoggedIn,
                ),
              ),
        ],
      ),
    );
  }
}
