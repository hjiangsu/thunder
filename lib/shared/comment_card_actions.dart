import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lemmy_api_client/v3.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thunder/core/auth/bloc/auth_bloc.dart';
import 'package:thunder/post/utils/comment_action_helpers.dart';

import 'package:thunder/thunder/bloc/thunder_bloc.dart';

class CommentCardActions extends StatelessWidget {
  final CommentView commentView;
  final bool isEdit;
  final double iconSize = 22;

  final Function(int, int) onVoteAction;
  final Function(int, bool) onSaveAction;
  final Function(int, bool) onDeleteAction;
  final Function(CommentView, bool) onReplyEditAction;
  final Function(int) onReportAction;
  final void Function() onViewSourceToggled;
  final bool viewSource;

  const CommentCardActions({
    super.key,
    required this.commentView,
    this.isEdit = false,
    required this.onVoteAction,
    required this.onSaveAction,
    required this.onDeleteAction,
    required this.onReplyEditAction,
    required this.onReportAction,
    required this.onViewSourceToggled,
    required this.viewSource,
  });

  final MaterialColor upVoteColor = Colors.orange;
  final MaterialColor downVoteColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    final int voteType = commentView.myVote ?? 0;
    bool downvotesEnabled = context.read<AuthBloc>().state.downvotesEnabled;

    return BlocBuilder<ThunderBloc, ThunderState>(
      builder: (context, state) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: 28,
              width: 44,
              child: IconButton(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    semanticLabel: 'Actions',
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    showCommentActionBottomModalSheet(
                      context,
                      commentView,
                      onSaveAction,
                      onDeleteAction,
                      onVoteAction,
                      onReplyEditAction,
                      onReportAction,
                      onViewSourceToggled,
                      viewSource,
                    );
                    HapticFeedback.mediumImpact();
                  }),
            ),
            SizedBox(
              height: 28,
              width: 44,
              child: IconButton(
                icon: Icon(isEdit ? Icons.edit_rounded : Icons.reply_rounded, semanticLabel: isEdit ? 'Edit' : 'Reply', size: iconSize),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onReplyEditAction(commentView, isEdit);
                },
              ),
            ),
            SizedBox(
              height: 28,
              width: 44,
              child: IconButton(
                  icon: Icon(
                    Icons.arrow_upward,
                    semanticLabel: voteType == 1 ? 'Upvoted' : 'Upvote',
                    size: iconSize,
                  ),
                  color: voteType == 1 ? upVoteColor : null,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onVoteAction(commentView.comment.id, voteType == 1 ? 0 : 1);
                  }),
            ),
            if (downvotesEnabled)
              SizedBox(
                height: 28,
                width: 44,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_downward,
                    semanticLabel: voteType == -1 ? 'Downvoted' : 'Downvote',
                    size: iconSize,
                  ),
                  color: voteType == -1 ? downVoteColor : null,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onVoteAction(commentView.comment.id, voteType == -1 ? 0 : -1);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
