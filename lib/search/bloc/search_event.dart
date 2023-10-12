part of 'search_bloc.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

class StartSearchEvent extends SearchEvent {
  final String query;
  final SortType sortType;

  const StartSearchEvent({required this.query, required this.sortType});
}

class ChangeCommunitySubsciptionStatusEvent extends SearchEvent {
  final int communityId;
  final bool follow;
  final String query;

  const ChangeCommunitySubsciptionStatusEvent({required this.communityId, required this.follow, required this.query});
}

class ResetSearch extends SearchEvent {}

class ContinueSearchEvent extends SearchEvent {
  final String query;
  final SortType sortType;

  const ContinueSearchEvent({required this.query, required this.sortType});
}

class FocusSearchEvent extends SearchEvent {}

class GetTrendingCommunitiesEvent extends SearchEvent {}
