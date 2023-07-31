import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lemmy_api_client/v3.dart';

import 'package:thunder/core/enums/font_scale.dart';
import 'package:thunder/core/models/post_view_media.dart';
import 'package:thunder/post/widgets/comment_card.dart';
import 'package:thunder/core/models/comment_view_tree.dart';
import 'package:thunder/post/widgets/post_view.dart';
import 'package:thunder/thunder/bloc/thunder_bloc.dart';
import 'package:thunder/utils/screen.dart';

import '../bloc/post_bloc.dart';

class CommentSubview extends StatefulWidget {
  final List<CommentViewTree> comments;
  final int level;

  final Function(int, VoteType) onVoteAction;
  final Function(int, bool) onSaveAction;

  final PostViewMedia? postViewMedia;
  final int? selectedCommentId;
  final String? selectedCommentPath;
  final int? moddingCommentId;
  final ScrollController? scrollController;

  final bool hasReachedCommentEnd;
  final bool viewFullCommentsRefreshing;
  final DateTime now;
  final Function(int, bool) onDeleteAction;

  const CommentSubview({
    super.key,
    required this.comments,
    this.level = 0,
    required this.onVoteAction,
    required this.onSaveAction,
    this.postViewMedia,
    this.selectedCommentId,
    this.selectedCommentPath,
    this.moddingCommentId,
    this.scrollController,
    this.hasReachedCommentEnd = false,
    this.viewFullCommentsRefreshing = false,
    required this.now,
    required this.onDeleteAction,
  });

  @override
  State<CommentSubview> createState() => _CommentSubviewState();
}

class _CommentSubviewState extends State<CommentSubview> with SingleTickerProviderStateMixin {
  final GlobalKey _reachedEndKey = GlobalKey();
  Set collapsedCommentSet = {}; // Retains the collapsed state of any comments
  bool _animatingOut = false;
  bool _animatingIn = false;
  bool _removeViewFullCommentsButton = false;

  late final AnimationController _fullCommentsAnimation = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final Animation<Offset> _fullCommentsOffsetAnimation = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0.0, 5),
  ).animate(CurvedAnimation(
    parent: _fullCommentsAnimation,
    curve: Curves.easeInOut,
  ));

  @override
  void initState() {
    super.initState();
    _fullCommentsOffsetAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed && _animatingOut) {
        _animatingOut = false;
        _removeViewFullCommentsButton = true;
        context.read<PostBloc>().add(const GetPostCommentsEvent(commentParentId: null, viewAllCommentsRefresh: true));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ThunderState state = context.read<ThunderBloc>().state;

    if (!widget.viewFullCommentsRefreshing && _removeViewFullCommentsButton) {
      _animatingIn = true;
      _fullCommentsAnimation.reverse();
    }

    return ListView.builder(
        addSemanticIndexes: false,
        controller: widget.scrollController,
        itemCount: getCommentsListLength(),
        itemBuilder: (context, index) {
          if (widget.postViewMedia != null && index == 0) {
            return PostSubview(selectedCommentId: widget.selectedCommentId, useDisplayNames: state.useDisplayNames, postViewMedia: widget.postViewMedia!);
          }
          if (widget.hasReachedCommentEnd == false && widget.comments.isEmpty) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: const CircularProgressIndicator(),
                ),
              ],
            );
          } else {
            return SlideTransition(
                position: _fullCommentsOffsetAnimation,
                child: Column(children: [
                  if (widget.selectedCommentId != null && !_animatingIn && index != widget.comments.length + 1)
                    Center(
                        child: Column(children: [
                      Row(children: [
                        const Padding(padding: EdgeInsets.only(left: 15)),
                        Expanded(
                            child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: theme.colorScheme.primaryContainer,
                            textStyle: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          onPressed: () {
                            _animatingOut = true;
                            _fullCommentsAnimation.forward();
                          },
                          child: const Text('View all comments'),
                        )),
                        const Padding(padding: EdgeInsets.only(right: 15))
                      ]),
                      const Padding(padding: EdgeInsets.only(top: 10)),
                    ])),
                  if (index != widget.comments.length + 1)
                    CommentCard(
                      now: widget.now,
                      selectCommentId: widget.selectedCommentId,
                      selectedCommentPath: widget.selectedCommentPath,
                      moddingCommentId: widget.moddingCommentId,
                      commentViewTree: widget.comments[index - 1],
                      collapsedCommentSet: collapsedCommentSet,
                      collapsed: collapsedCommentSet.contains(widget.comments[index - 1].commentView!.comment.id) || widget.level == 2,
                      onSaveAction: (int commentId, bool save) => widget.onSaveAction(commentId, save),
                      onVoteAction: (int commentId, VoteType voteType) => widget.onVoteAction(commentId, voteType),
                      onCollapseCommentChange: (int commentId, bool collapsed) => onCollapseCommentChange(commentId, collapsed),
                      onDeleteAction: (int commentId, bool deleted) => widget.onDeleteAction(commentId, deleted),
                    ),
                  if (index == widget.comments.length + 1) ...[
                    if (widget.hasReachedCommentEnd == true) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            key: _reachedEndKey,
                            color: theme.dividerColor.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(vertical: 32.0),
                            child: Text(
                              'Hmmm. It seems like you\'ve reached the bottom.',
                              textScaleFactor: state.contentFontSizeScale.textScaleFactor,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          SizedBox(
                            height: _reachedEndKey.currentContext?.findRenderObject() is RenderBox
                                // Subtract the available screen height from the height of the "reached the bottom" widget, so that it's the only thing that shows
                                ? getScreenHeightWithoutOs(context) - (_reachedEndKey.currentContext?.findRenderObject() as RenderBox).size.height
                                : 0,
                          ),
                        ],
                      )
                    ] else ...[
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: const CircularProgressIndicator(),
                          ),
                        ],
                      )
                    ]
                  ]
                ]));
          }
        });
  }

  int getCommentsListLength() {
    if (widget.comments.isEmpty && widget.hasReachedCommentEnd == false) {
      return 2; // Show post and loading indicator since no comments have been fetched yet
    }

    return widget.postViewMedia != null ? widget.comments.length + 2 : widget.comments.length + 1;
  }

  void onCollapseCommentChange(int commentId, bool collapsed) {
    if (collapsed == false && collapsedCommentSet.contains(commentId)) {
      setState(() => collapsedCommentSet.remove(commentId));
    } else if (collapsed == true && !collapsedCommentSet.contains(commentId)) {
      setState(() => collapsedCommentSet.add(commentId));
    }
  }
}
