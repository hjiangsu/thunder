import 'dart:ui';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:thunder/utils/links.dart';
import 'package:thunder/feed/bloc/feed_bloc.dart';
import 'package:thunder/shared/image_viewer.dart';
import 'package:thunder/core/enums/view_mode.dart';
import 'package:thunder/core/enums/media_type.dart';
import 'package:thunder/post/enums/post_action.dart';
import 'package:thunder/shared/link_preview_card.dart';
import 'package:thunder/thunder/bloc/thunder_bloc.dart';
import 'package:thunder/core/models/post_view_media.dart';
import 'package:thunder/core/enums/image_caching_mode.dart';

class MediaView extends StatefulWidget {
  /// The post containing the media information
  final PostViewMedia postViewMedia;

  /// Whether to show the full height for images
  final bool showFullHeightImages;

  /// Whether to blur NSFW images
  final bool hideNsfwPreviews;

  /// Whether to extend the image to the edge of the screen (ViewMode.comfortable)
  final bool edgeToEdgeImages;

  /// Whether to mark the post as read when the media is viewed
  final bool markPostReadOnMediaView;

  /// Whether the user is logged in
  final bool isUserLoggedIn;

  /// Whether to scrape missing previews for thumbnails
  final bool? scrapeMissingPreviews;

  /// The view mode of the media
  final ViewMode viewMode;

  /// The function to navigate to the post
  final void Function({PostViewMedia? postViewMedia})? navigateToPost;

  /// Whether the post has been read
  final bool? read;

  const MediaView({
    super.key,
    required this.postViewMedia,
    this.showFullHeightImages = true,
    this.edgeToEdgeImages = false,
    this.hideNsfwPreviews = true,
    this.markPostReadOnMediaView = false,
    this.isUserLoggedIn = false,
    this.viewMode = ViewMode.comfortable,
    this.scrapeMissingPreviews,
    this.navigateToPost,
    this.read,
  });

  @override
  State<MediaView> createState() => _MediaViewState();
}

class _MediaViewState extends State<MediaView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 130), lowerBound: 0.0, upperBound: 1.0);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Creates a text preview for posts in compact mode
  Widget buildMediaText() {
    final theme = Theme.of(context);

    if (widget.viewMode == ViewMode.comfortable) return Container();

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Container(
        color: theme.cardColor.darken(5),
        child: widget.postViewMedia.postView.post.body?.isNotEmpty == true
            ? SizedBox(
                height: 75.0,
                width: 75.0,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      widget.postViewMedia.postView.post.body!,
                      style: TextStyle(
                        fontSize: min(20, max(4.5, (20 * (1 / log(widget.postViewMedia.postView.post.body!.length))))),
                        color: widget.read == true ? theme.colorScheme.onBackground.withOpacity(0.55) : theme.colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              )
            : Container(
                height: 75,
                width: 75,
                color: theme.cardColor.darken(5),
                child: Icon(
                  Icons.text_fields_rounded,
                  color: theme.colorScheme.onSecondaryContainer.withOpacity(widget.read == true ? 0.55 : 1.0),
                ),
              ),
      ),
    );
  }

  /// Creates an image preview
  Widget buildMediaImage() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final blurNSFWPreviews = widget.hideNsfwPreviews && widget.postViewMedia.postView.post.nsfw;

    return InkWell(
      splashColor: theme.colorScheme.primary.withOpacity(0.4),
      borderRadius: BorderRadius.circular((widget.edgeToEdgeImages ? 0 : 12)),
      onTap: () {
        if (widget.isUserLoggedIn && widget.markPostReadOnMediaView) {
          try {
            // Mark post as read when on the feed page
            int postId = widget.postViewMedia.postView.post.id;
            context.read<FeedBloc>().add(FeedItemActionedEvent(postAction: PostAction.read, postId: postId, value: true));
          } catch (e) {}
        }
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            transitionDuration: const Duration(milliseconds: 100),
            reverseTransitionDuration: const Duration(milliseconds: 100),
            transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
              return FadeTransition(opacity: animation, child: child);
            },
            pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
              return ImageViewer(
                url: widget.postViewMedia.media.first.mediaUrl ?? widget.postViewMedia.media.first.originalUrl!,
                postId: widget.postViewMedia.postView.post.id,
                navigateToPost: widget.navigateToPost,
              );
            },
          ),
        );
      },
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular((widget.edgeToEdgeImages ? 0 : 12))),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ImageFiltered(
              enabled: blurNSFWPreviews,
              imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: previewImage(context),
            ),
            if (blurNSFWPreviews)
              Column(
                children: [
                  Icon(Icons.warning_rounded, size: widget.viewMode != ViewMode.compact ? 55 : 30),
                  if (widget.viewMode != ViewMode.compact) Text(l10n.nsfwWarning, textScaler: const TextScaler.linear(1.5)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.postViewMedia.media.firstOrNull?.mediaType) {
      case MediaType.image:
        return buildMediaImage();
      case MediaType.link:
      case MediaType.video:
        return LinkPreviewCard(
          hideNsfw: widget.hideNsfwPreviews && widget.postViewMedia.postView.post.nsfw,
          scrapeMissingPreviews: widget.scrapeMissingPreviews!,
          originURL: widget.postViewMedia.media.first.originalUrl,
          mediaURL: widget.postViewMedia.media.first.mediaUrl ?? widget.postViewMedia.postView.post.thumbnailUrl,
          mediaHeight: widget.postViewMedia.media.first.height,
          mediaWidth: widget.postViewMedia.media.first.width,
          showFullHeightImages: widget.viewMode == ViewMode.comfortable ? widget.showFullHeightImages : false,
          edgeToEdgeImages: widget.viewMode == ViewMode.comfortable ? widget.edgeToEdgeImages : false,
          viewMode: widget.viewMode,
          postId: widget.postViewMedia.postView.post.id,
          markPostReadOnMediaView: widget.markPostReadOnMediaView,
          isUserLoggedIn: widget.isUserLoggedIn,
          read: widget.read,
        );
      case MediaType.text:
        return buildMediaText();
      default:
        return Container();
    }
  }

  Widget previewImage(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.read<ThunderBloc>().state;

    double? height = widget.viewMode == ViewMode.compact ? 75 : (widget.showFullHeightImages ? widget.postViewMedia.media.first.height : 150);
    double width = widget.viewMode == ViewMode.compact ? 75 : MediaQuery.of(context).size.width - (widget.edgeToEdgeImages ? 0 : 24);

    return ExtendedImage.network(
      color: widget.read == true ? const Color.fromRGBO(255, 255, 255, 0.5) : null,
      colorBlendMode: widget.read == true ? BlendMode.modulate : null,
      widget.postViewMedia.media.first.mediaUrl ?? widget.postViewMedia.media.first.originalUrl!,
      height: height,
      width: width,
      fit: widget.viewMode == ViewMode.compact ? BoxFit.cover : BoxFit.fitWidth,
      cache: true,
      clearMemoryCacheWhenDispose: state.imageCachingMode == ImageCachingMode.relaxed,
      cacheWidth: widget.viewMode == ViewMode.compact
          ? (75 * View.of(context).devicePixelRatio.ceil())
          : ((MediaQuery.of(context).size.width - (widget.edgeToEdgeImages ? 0 : 24)) * View.of(context).devicePixelRatio.ceil()).toInt(),
      loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            _controller.reset();
            return Container();
          case LoadState.completed:
            if (state.wasSynchronouslyLoaded) return state.completedWidget;

            _controller.forward();
            return FadeTransition(opacity: _controller, child: state.completedWidget);
          case LoadState.failed:
            _controller.reset();

            state.imageProvider.evict();

            if (widget.viewMode == ViewMode.compact) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.secondary.withOpacity(0.2),
                ),
                child: InkWell(
                  child: const Icon(Icons.error_outline_sharp),
                  onTap: () {
                    handleLink(context, url: widget.postViewMedia.postView.post.url ?? '');
                  },
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.secondary.withOpacity(0.4),
              ),
              child: InkWell(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.link),
                      ),
                      Expanded(
                        child: Text(
                          widget.postViewMedia.postView.post.url ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  handleLink(context, url: widget.postViewMedia.postView.post.url ?? '');
                },
              ),
            );
        }
      },
    );
  }
}
