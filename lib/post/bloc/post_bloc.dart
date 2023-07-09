import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/cupertino.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_transform/stream_transform.dart';

import 'package:lemmy_api_client/v3.dart';

import 'package:thunder/account/models/account.dart';
import 'package:thunder/core/auth/helpers/fetch_account.dart';
import 'package:thunder/core/models/post_view_media.dart';
import 'package:thunder/utils/comment.dart';
import 'package:thunder/core/models/comment_view_tree.dart';
import 'package:thunder/core/singletons/lemmy_client.dart';
import 'package:thunder/utils/network_errors.dart';
import 'package:thunder/utils/post.dart';

import '../../utils/constants.dart';

part 'post_event.dart';
part 'post_state.dart';

const throttleDuration = Duration(seconds: 1);
const timeout = Duration(seconds: 10);
int commentLimit = 50;

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) => droppable<E>().call(events.throttle(duration), mapper);
}

class PostBloc extends Bloc<PostEvent, PostState> {
  PostBloc() : super(const PostState()) {
    on<GetPostEvent>(
      _getPostEvent,
      transformer: throttleDroppable(throttleDuration),
    );
    on<VotePostEvent>(
      _votePostEvent,
      transformer: throttleDroppable(throttleDuration),
    );
    on<SavePostEvent>(
      _savePostEvent,
      transformer: throttleDroppable(throttleDuration),
    );
    on<GetPostCommentsEvent>(
      _getPostCommentsEvent,
      transformer: throttleDroppable(throttleDuration),
    );
    on<VoteCommentEvent>(
      _voteCommentEvent,
      transformer: throttleDroppable(throttleDuration),
    );
    on<SaveCommentEvent>(
      _saveCommentEvent,
      transformer: throttleDroppable(throttleDuration),
    );
    on<CreateCommentEvent>(
      _createCommentEvent,
      transformer: throttleDroppable(throttleDuration),
    );
    on<EditCommentEvent>(
      _editCommentEvent,
      transformer: throttleDroppable(throttleDuration),
    );
  }

  /// Fetches the post, along with the initial set of comments
  Future<void> _getPostEvent(GetPostEvent event, emit) async {
    int attemptCount = 0;

    try {
      var exception;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      CommentSortType defaultSortType = CommentSortType.values.byName(prefs.getString("setting_post_default_comment_sort_type")?.toLowerCase() ?? DEFAULT_COMMENT_SORT_TYPE.name);

      Account? account = await fetchActiveProfileAccount();

      while (attemptCount < 2) {
        try {
          emit(state.copyWith(status: PostStatus.loading));

          LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

          FullPostView? getPostResponse;

          if (event.postId != null) {
            getPostResponse = await lemmy.run(GetPost(id: event.postId!, auth: account?.jwt)).timeout(timeout, onTimeout: () {
              throw Exception('Error: Timeout when attempting to fetch post');
            });
          }

          PostViewMedia? postView = event.postView;

          if (getPostResponse != null) {
            // Parse the posts and add in media information which is used elsewhere in the app
            List<PostViewMedia> posts = await parsePostViews([getPostResponse.postView]);

            postView = posts.first;
          }

          emit(
            state.copyWith(
              status: PostStatus.success,
              postId: postView?.postView.post.id,
              postView: postView,
              communityId: postView?.postView.post.communityId,
            ),
          );

          emit(state.copyWith(status: PostStatus.refreshing));

          CommentSortType sortType = event.sortType ?? (state.sortType ?? defaultSortType);

          List<CommentView> getCommentsResponse = await lemmy
              .run(GetComments(
            page: 1,
            auth: account?.jwt,
            communityId: postView?.postView.post.communityId,
            // maxDepth: 8,
            postId: postView?.postView.post.id,
            sort: sortType,
            limit: commentLimit,
          ))
              .timeout(timeout, onTimeout: () {
            throw Exception('Error: Timeout when attempting to fetch comments');
          });

          // Build the tree view from the flattened comments
          List<CommentViewTree> commentTree = buildCommentViewTree(getCommentsResponse);

          return emit(
            state.copyWith(
                status: PostStatus.success,
                postId: postView?.postView.post.id,
                postView: postView,
                comments: commentTree,
                commentResponseList: getCommentsResponse,
                commentPage: state.commentPage + 1,
                commentCount: getCommentsResponse.length,
                hasReachedCommentEnd: getCommentsResponse.isEmpty || getCommentsResponse.length < commentLimit,
                communityId: postView?.postView.post.communityId,
                sortType: sortType),
          );
        } catch (e, s) {
          exception = e;
          attemptCount++;
          await Sentry.captureException(e, stackTrace: s);
        }
      }
      emit(state.copyWith(status: PostStatus.failure, errorMessage: exception.toString()));
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      emit(state.copyWith(status: PostStatus.failure, errorMessage: e.toString()));
    }
  }

  /// Event to fetch more comments from a post
  Future<void> _getPostCommentsEvent(event, emit) async {
    int attemptCount = 0;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    CommentSortType defaultSortType = CommentSortType.values.byName(prefs.getString("setting_post_default_comment_sort_type")?.toLowerCase() ?? DEFAULT_COMMENT_SORT_TYPE.name);

    CommentSortType sortType = event.sortType ?? (state.sortType ?? defaultSortType);

    try {
      var exception;

      Account? account = await fetchActiveProfileAccount();

      while (attemptCount < 2) {
        try {
          LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

          if (event.reset) {
            emit(state.copyWith(status: PostStatus.loading));

            List<CommentView> getCommentsResponse = await lemmy
                .run(GetComments(
              auth: account?.jwt,
              communityId: state.communityId,
              postId: state.postId,
              sort: sortType,
              limit: commentLimit,
              // maxDepth: 8,
              page: 1,
            ))
                .timeout(timeout, onTimeout: () {
              throw Exception('Error: Timeout when attempting to fetch comments');
            });

            // Build the tree view from the flattened comments
            List<CommentViewTree> commentTree = buildCommentViewTree(getCommentsResponse);

            return emit(
              state.copyWith(
                  status: PostStatus.success,
                  comments: commentTree,
                  commentResponseList: getCommentsResponse,
                  commentPage: 1,
                  commentCount: getCommentsResponse.length,
                  hasReachedCommentEnd: getCommentsResponse.isEmpty || getCommentsResponse.length < commentLimit,
                  sortType: sortType),
            );
          }

          // Prevent duplicate requests if we're done fetching comments
          if (state.commentCount >= state.postView!.postView.counts.comments || state.hasReachedCommentEnd) return;
          emit(state.copyWith(status: PostStatus.refreshing));

          List<CommentView> getCommentsResponse = await lemmy
              .run(GetComments(
            auth: account?.jwt,
            communityId: state.communityId,
            postId: state.postId,
            sort: sortType,
            limit: commentLimit,
            // maxDepth: 8,
            page: state.commentPage,
          ))
              .timeout(timeout, onTimeout: () {
            throw Exception('Error: Timeout when attempting to fetch more comments');
          });

          // Combine all of the previous comments list
          List<CommentView> fullCommentResponseList = List.from(state.commentResponseList)..addAll(getCommentsResponse);

          // Build the tree view from the flattened comments
          List<CommentViewTree> commentViewTree = buildCommentViewTree(fullCommentResponseList);

          // We'll add in a edge case here to stop fetching comments after theres no more comments to be fetched
          return emit(state.copyWith(
            status: PostStatus.success,
            comments: commentViewTree,
            commentResponseList: fullCommentResponseList,
            commentPage: state.commentPage + 1,
            commentCount: fullCommentResponseList.length,
            hasReachedCommentEnd: getCommentsResponse.isEmpty || getCommentsResponse.length < commentLimit,
          ));
        } catch (e, s) {
          exception = e;
          attemptCount++;
          await Sentry.captureException(e, stackTrace: s);
        }
      }

      if (exception != null && is50xError(exception.toString()) != null) {
        emit(state.copyWith(status: PostStatus.failure, errorMessage: 'A server error was encountered when fetching more comments: ${is50xError(exception.toString())}'));
      } else {
        emit(state.copyWith(status: PostStatus.failure, errorMessage: exception.toString()));
      }
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      emit(state.copyWith(status: PostStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _votePostEvent(VotePostEvent event, Emitter<PostState> emit) async {
    try {
      emit(state.copyWith(status: PostStatus.refreshing));

      // Optimistically update the post
      PostView originalPostView = state.postView!.postView;

      PostView updatedPostView = optimisticallyVotePost(state.postView!, event.score);
      state.postView?.postView = updatedPostView;

      // Immediately set the status, and continue
      emit(state.copyWith(status: PostStatus.success));
      emit(state.copyWith(status: PostStatus.refreshing));

      PostView postView = await votePost(event.postId, event.score).timeout(timeout, onTimeout: () {
        state.postView?.postView = originalPostView;
        throw Exception('Error: Timeout when attempting to vote post');
      });

      state.postView?.postView = postView;

      return emit(state.copyWith(status: PostStatus.success));
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      return emit(state.copyWith(status: PostStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _savePostEvent(SavePostEvent event, Emitter<PostState> emit) async {
    try {
      emit(state.copyWith(status: PostStatus.refreshing));

      PostView postView = await savePost(event.postId, event.save).timeout(timeout, onTimeout: () {
        throw Exception('Error: Timeout when attempting to save post');
      });

      state.postView?.postView = postView;

      return emit(state.copyWith(status: PostStatus.success));
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      emit(state.copyWith(status: PostStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _voteCommentEvent(VoteCommentEvent event, Emitter<PostState> emit) async {
    try {
      emit(state.copyWith(status: PostStatus.refreshing));

      List<int> commentIndexes = findCommentIndexesFromCommentViewTree(state.comments, event.commentId);
      CommentViewTree currentTree = state.comments[commentIndexes[0]]; // Get the initial CommentViewTree

      // if (commentIndexes.length == 1) {
      //   currentTree = currentTree.replies.first; // Traverse to the next CommentViewTree
      // }

      for (int i = 1; i < commentIndexes.length; i++) {
        currentTree = currentTree.replies[commentIndexes[i]]; // Traverse to the next CommentViewTree
      }

      // Optimistically update the comment
      CommentView? originalCommentView = currentTree.comment;

      CommentView updatedCommentView = optimisticallyVoteComment(currentTree, event.score);
      currentTree.comment = updatedCommentView;

      // Immediately set the status, and continue
      emit(state.copyWith(status: PostStatus.success));
      emit(state.copyWith(status: PostStatus.refreshing));

      CommentView commentView = await voteComment(event.commentId, event.score).timeout(timeout, onTimeout: () {
        currentTree.comment = originalCommentView; // Reset this on exception
        throw Exception('Error: Timeout when attempting to vote on comment');
      });

      currentTree.comment = commentView;

      return emit(state.copyWith(status: PostStatus.success));
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      return emit(state.copyWith(status: PostStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _saveCommentEvent(SaveCommentEvent event, Emitter<PostState> emit) async {
    try {
      emit(state.copyWith(status: PostStatus.refreshing));

      CommentView commentView = await saveComment(event.commentId, event.save).timeout(timeout, onTimeout: () {
        throw Exception('Error: Timeout when attempting save a comment');
      });

      List<int> commentIndexes = findCommentIndexesFromCommentViewTree(state.comments, event.commentId);
      CommentViewTree currentTree = state.comments[commentIndexes[0]]; // Get the initial CommentViewTree

      for (int i = 1; i < commentIndexes.length; i++) {
        currentTree = currentTree.replies[commentIndexes[i]]; // Traverse to the next CommentViewTree
      }

      currentTree.comment = commentView; // Update the comment's information

      return emit(state.copyWith(status: PostStatus.success));
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      emit(state.copyWith(status: PostStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _createCommentEvent(CreateCommentEvent event, Emitter<PostState> emit) async {
    try {
      emit(state.copyWith(status: PostStatus.refreshing));

      Account? account = await fetchActiveProfileAccount();
      LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

      if (account?.jwt == null) {
        return emit(state.copyWith(status: PostStatus.failure, errorMessage: 'You are not logged in. Cannot create a post.'));
      }

      if (state.postView?.postView.post.id == null) {
        return emit(state.copyWith(status: PostStatus.failure, errorMessage: 'Could not determine post to comment to.'));
      }

      FullCommentView createComment = await lemmy.run(CreateComment(
        auth: account!.jwt!,
        content: event.content,
        postId: state.postView!.postView.post.id,
        parentId: event.parentCommentId,
      ));

      // for now, refresh the post and refetch the comments
      // @todo: insert the new comment in place without requiring a refetch
      add(GetPostEvent(postView: state.postView!));
      return emit(state.copyWith(status: PostStatus.success));
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      return emit(state.copyWith(status: PostStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _editCommentEvent(EditCommentEvent event, Emitter<PostState> emit) async {
    try {
      emit(state.copyWith(status: PostStatus.refreshing));

      Account? account = await fetchActiveProfileAccount();
      LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

      if (account?.jwt == null) {
        return emit(state.copyWith(status: PostStatus.failure, errorMessage: 'You are not logged in. Cannot create a post.'));
      }

      if (state.postView?.postView.post.id == null) {
        return emit(state.copyWith(status: PostStatus.failure, errorMessage: 'Could not determine post to comment to.'));
      }

      FullCommentView editComment = await lemmy.run(EditComment(
        auth: account!.jwt!,
        content: event.content,
        commentId: event.commentId,
      ));

      // for now, refresh the post and refetch the comments
      // @todo: insert the new comment in place without requiring a refetch
      add(GetPostEvent(postView: state.postView!));
      return emit(state.copyWith(status: PostStatus.success));
    } catch (e, s) {
      await Sentry.captureException(e, stackTrace: s);
      return emit(state.copyWith(status: PostStatus.failure, errorMessage: e.toString()));
    }
  }
}
