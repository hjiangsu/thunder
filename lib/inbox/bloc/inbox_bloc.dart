import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:lemmy_api_client/v3.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:thunder/account/models/account.dart';
import 'package:thunder/core/auth/helpers/fetch_account.dart';
import 'package:thunder/core/singletons/lemmy_client.dart';

import '../../utils/comment.dart';

part 'inbox_event.dart';

part 'inbox_state.dart';

const throttleDuration = Duration(seconds: 1);
const timeout = Duration(seconds: 5);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) => droppable<E>().call(events.throttle(duration), mapper);
}

class InboxBloc extends Bloc<InboxEvent, InboxState> {
  InboxBloc() : super(const InboxState()) {
    on<GetInboxEvent>(
      _getInboxEvent,
      transformer: throttleDroppable(throttleDuration),
    );
    on<MarkReplyAsReadEvent>(
      _markReplyAsReadEvent,
      transformer: throttleDroppable(throttleDuration),
    );
    on<MarkMentionAsReadEvent>(
      _markMentionAsReadEvent,
      transformer: throttleDroppable(throttleDuration),
    );
    on<CreateInboxCommentReplyEvent>(
      _createCommentEvent,
      transformer: throttleDroppable(throttleDuration),
    );
    on<MarkAllAsReadEvent>(
      _markAllAsRead,
      transformer: throttleDroppable(throttleDuration),
    );
  }

  Future<void> _getInboxEvent(GetInboxEvent event, emit) async {
    int attemptCount = 0;
    int limit = 20;

    try {
      var exception;

      Account? account = await fetchActiveProfileAccount();

      while (attemptCount < 2) {
        try {
          LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

          if (event.reset) {
            emit(state.copyWith(status: InboxStatus.loading));
            // Fetch all the things
            List<PrivateMessageView> privateMessageViews = await lemmy.run(
              GetPrivateMessages(
                auth: account!.jwt!,
                unreadOnly: !event.showAll,
                limit: limit,
                page: 1,
              ),
            );

            List<PersonMentionView> personMentionViews = await lemmy.run(
              GetPersonMentions(
                auth: account.jwt!,
                unreadOnly: !event.showAll,
                sort: SortType.new_,
                limit: limit,
                page: 1,
              ),
            );

            List<CommentView> commentViews = await lemmy.run(
              GetReplies(
                auth: account.jwt!,
                unreadOnly: !event.showAll,
                limit: limit,
                sort: SortType.new_,
                page: 1,
              ),
            );

            int totalUnreadCount = getUnreadCount(privateMessageViews, personMentionViews, commentViews);

            return emit(
              state.copyWith(
                status: InboxStatus.success,
                privateMessages: cleanDeletedMessages(privateMessageViews),
                mentions: cleanDeletedMentions(personMentionViews),
                replies: cleanDeletedReplies(commentViews),
                showUnreadOnly: !event.showAll,
                inboxMentionPage: 2,
                inboxReplyPage: 2,
                inboxPrivateMessagePage: 2,
                totalUnreadCount: totalUnreadCount,
                hasReachedInboxReplyEnd: commentViews.isEmpty || commentViews.length < limit,
                hasReachedInboxMentionEnd: personMentionViews.isEmpty || personMentionViews.length < limit,
                hasReachedInboxPrivateMessageEnd: privateMessageViews.isEmpty || privateMessageViews.length < limit,
              ),
            );
          }

          // Prevent duplicate requests if we're done fetching
          if (state.hasReachedInboxReplyEnd && state.hasReachedInboxMentionEnd && state.hasReachedInboxPrivateMessageEnd) return;
          emit(state.copyWith(status: InboxStatus.refreshing));

          // Fetch all the things
          List<PrivateMessageView> privateMessageViews = await lemmy.run(
            GetPrivateMessages(
              auth: account!.jwt!,
              unreadOnly: !event.showAll,
              limit: limit,
              page: state.inboxPrivateMessagePage,
            ),
          );

          List<PersonMentionView> personMentionViews = await lemmy.run(
            GetPersonMentions(
              auth: account.jwt!,
              unreadOnly: !event.showAll,
              sort: SortType.new_,
              limit: limit,
              page: state.inboxMentionPage,
            ),
          );

          List<CommentView> commentViews = await lemmy.run(
            GetReplies(
              auth: account.jwt!,
              unreadOnly: !event.showAll,
              limit: limit,
              sort: SortType.new_,
              page: state.inboxReplyPage,
            ),
          );

          List<CommentView> replies = List.from(state.replies)..addAll(commentViews);
          List<PersonMentionView> mentions = List.from(state.mentions)..addAll(personMentionViews);
          List<PrivateMessageView> privateMessages = List.from(state.privateMessages)..addAll(privateMessageViews);

          return emit(
            state.copyWith(
              status: InboxStatus.success,
              privateMessages: cleanDeletedMessages(privateMessages),
              mentions: cleanDeletedMentions(mentions),
              replies: cleanDeletedReplies(replies),
              showUnreadOnly: state.showUnreadOnly,
              inboxMentionPage: state.inboxMentionPage + 1,
              inboxReplyPage: state.inboxReplyPage + 1,
              inboxPrivateMessagePage: state.inboxPrivateMessagePage + 1,
              hasReachedInboxReplyEnd: commentViews.isEmpty || commentViews.length < limit,
              hasReachedInboxMentionEnd: personMentionViews.isEmpty || personMentionViews.length < limit,
              hasReachedInboxPrivateMessageEnd: privateMessageViews.isEmpty || privateMessageViews.length < limit,
            ),
          );
        } catch (e) {
          exception = e;
          attemptCount++;
        }
      }

      emit(state.copyWith(status: InboxStatus.failure, errorMessage: exception.toString(), totalUnreadCount: 0));
    } catch (e) {
      emit(state.copyWith(status: InboxStatus.failure, errorMessage: e.toString(), totalUnreadCount: 0));
    }
  }

  Future<void> _markReplyAsReadEvent(MarkReplyAsReadEvent event, emit) async {
    try {
      emit(state.copyWith(status: InboxStatus.refreshing));

      Account? account = await fetchActiveProfileAccount();
      LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

      if (account?.jwt == null) {
        return emit(state.copyWith(status: InboxStatus.success));
      }

      FullCommentReplyView response = await lemmy.run(MarkCommentAsRead(
        auth: account!.jwt!,
        commentReplyId: event.commentReplyId,
        read: event.read,
      ));

      // Remove the post from the current reply list, or just mark it as read
      List<CommentView> replies = List.from(state.replies);
      bool matchMarkedComment(CommentView commentView) => commentView.commentReply?.id == response.commentReplyView.commentReply.id;
      if (event.showAll) {
        final CommentView markedComment = replies.firstWhere(matchMarkedComment);
        final int index = replies.indexOf(markedComment);
        replies[index] = markedComment.copyWith(commentReply: markedComment.commentReply?.copyWith(read: true));
      } else {
        replies.removeWhere(matchMarkedComment);
      }

      int totalUnreadCount = getUnreadCount(state.privateMessages, state.mentions, replies);

      emit(state.copyWith(
        status: InboxStatus.success,
        replies: replies,
        totalUnreadCount: totalUnreadCount,
      ));
    } catch (e) {
      return emit(state.copyWith(status: InboxStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _markMentionAsReadEvent(MarkMentionAsReadEvent event, emit) async {
    try {
      emit(state.copyWith(
        status: InboxStatus.loading,
        privateMessages: state.privateMessages,
        mentions: state.mentions,
        replies: state.replies,
      ));

      Account? account = await fetchActiveProfileAccount();
      LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

      if (account?.jwt == null) {
        return emit(state.copyWith(status: InboxStatus.success));
      }

      PersonMentionView personMentionView = await lemmy.run(MarkPersonMentionAsRead(
        auth: account!.jwt!,
        personMentionId: event.personMentionId,
        read: event.read,
      ));

      add(GetInboxEvent(showAll: !state.showUnreadOnly));
    } catch (e) {
      return emit(state.copyWith(status: InboxStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _createCommentEvent(CreateInboxCommentReplyEvent event, Emitter<InboxState> emit) async {
    try {
      emit(state.copyWith(status: InboxStatus.refreshing));

      Account? account = await fetchActiveProfileAccount();
      LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

      if (account?.jwt == null) {
        return emit(state.copyWith(status: InboxStatus.failure, errorMessage: 'You are not logged in. Cannot create a comment'));
      }

      FullCommentView fullCommentView = await lemmy.run(CreateComment(
        auth: account!.jwt!,
        content: event.content,
        postId: event.postId,
        parentId: event.parentCommentId,
      ));

      add(GetInboxEvent(showAll: !state.showUnreadOnly));
      return emit(state.copyWith(status: InboxStatus.success));
    } catch (e) {
      return emit(state.copyWith(status: InboxStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _markAllAsRead(MarkAllAsReadEvent event, emit) async {
    try {
      emit(state.copyWith(
        status: InboxStatus.refreshing,
      ));
      Account? account = await fetchActiveProfileAccount();
      LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

      if (account?.jwt == null) {
        return emit(state.copyWith(status: InboxStatus.success));
      }
      await lemmy.run(MarkAllAsRead(
        auth: account!.jwt!,
      ));

      add(GetInboxEvent(reset: true, showAll: !state.showUnreadOnly));
    } catch (e) {
      emit(state.copyWith(
        status: InboxStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  List<PrivateMessageView> cleanDeletedMessages(List<PrivateMessageView> messages) {
    List<PrivateMessageView> cleanMessages = [];

    for (PrivateMessageView message in messages) {
      cleanMessages.add(cleanDeletedPrivateMessage(message));
    }

    return cleanMessages;
  }

  List<PersonMentionView> cleanDeletedMentions(List<PersonMentionView> mentions) {
    List<PersonMentionView> cleanedMentions = [];

    for (PersonMentionView mention in mentions) {
      cleanedMentions.add(cleanDeletedMention(mention));
    }

    return cleanedMentions;
  }

  List<CommentView> cleanDeletedReplies(List<CommentView> replies) {
    List<CommentView> cleanedReplies = [];

    for (CommentView reply in replies) {
      cleanedReplies.add(cleanDeletedCommentView(reply));
    }

    return cleanedReplies;
  }

  PrivateMessageView cleanDeletedPrivateMessage(PrivateMessageView message) {
    if (!message.privateMessage.deleted) {
      return message;
    }

    PrivateMessage privateMessage = PrivateMessage(
        id: message.privateMessage.id,
        creatorId: message.privateMessage.creatorId,
        recipientId: message.privateMessage.recipientId,
        content: "_deleted by creator_",
        deleted: message.privateMessage.deleted,
        read: message.privateMessage.read,
        published: message.privateMessage.published,
        apId: message.privateMessage.apId,
        local: message.privateMessage.local,
        instanceHost: message.privateMessage.instanceHost);

    return PrivateMessageView(privateMessage: privateMessage, creator: message.creator, recipient: message.recipient, instanceHost: message.instanceHost);
  }

  PersonMentionView cleanDeletedMention(PersonMentionView mention) {
    if (!mention.comment.deleted) {
      return mention;
    }

    Comment deletedComment = convertToDeletedComment(mention.comment);

    return PersonMentionView(
        personMention: mention.personMention,
        comment: deletedComment,
        creator: mention.creator,
        post: mention.post,
        community: mention.community,
        recipient: mention.recipient,
        counts: mention.counts,
        creatorBannedFromCommunity: mention.creatorBannedFromCommunity,
        saved: mention.saved,
        creatorBlocked: mention.creatorBlocked,
        instanceHost: mention.instanceHost);
  }

  int getUnreadCount(List<PrivateMessageView> privateMessageViews, List<PersonMentionView> personMentionViews, List<CommentView> commentViews) {
    // Tally up how many unread messages/mentions/replies there are so far
    // This will only tally up at most 20 for each type for a total of 60 unread counts
    int totalUnreadCount = 0;

    for (PrivateMessageView privateMessageView in privateMessageViews) {
      if (privateMessageView.privateMessage.read == false) totalUnreadCount++;
    }

    for (PersonMentionView personMentionView in personMentionViews) {
      if (personMentionView.personMention.read == false) totalUnreadCount++;
    }

    for (CommentView commentView in commentViews) {
      if (commentView.commentReply?.read == false) totalUnreadCount++;
    }

    return totalUnreadCount;
  }
}
