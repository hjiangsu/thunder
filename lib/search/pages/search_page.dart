import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lemmy_api_client/v3.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thunder/account/bloc/account_bloc.dart';
import 'package:thunder/account/models/account.dart';
import 'package:thunder/community/bloc/anonymous_subscriptions_bloc.dart';
import 'package:thunder/core/auth/bloc/auth_bloc.dart';
import 'package:thunder/core/auth/helpers/fetch_account.dart';
import 'package:thunder/core/singletons/preferences.dart';
import 'package:thunder/feed/utils/utils.dart';
import 'package:thunder/feed/view/feed_page.dart';
import 'package:thunder/search/bloc/search_bloc.dart';
import 'package:thunder/shared/error_message.dart';
import 'package:thunder/shared/snackbar.dart';
import 'package:thunder/shared/sort_picker.dart';
import 'package:thunder/shared/community_icon.dart';
import 'package:thunder/shared/user_avatar.dart';
import 'package:thunder/thunder/bloc/thunder_bloc.dart';
import 'package:thunder/utils/bottom_sheet_list_picker.dart';
import 'package:thunder/utils/constants.dart';
import 'package:thunder/utils/debounce.dart';
import 'package:thunder/utils/global_context.dart';
import 'package:thunder/utils/instance.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with AutomaticKeepAliveClientMixin<SearchPage> {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _controller = TextEditingController();
  final _scrollController = ScrollController(initialScrollOffset: 0);
  // This exists only because it is required by FadingEdgeScrollView
  final ScrollController _searchFiltersScrollController = ScrollController();
  SharedPreferences? prefs;
  SortType sortType = SortType.active;
  IconData? sortTypeIcon;
  String? sortTypeLabel;
  final Set<Community> newAnonymousSubscriptions = {};
  final Set<int> removedSubs = {};
  int _previousFocusSearchId = 0;
  final searchTextFieldFocus = FocusNode();
  int? _previousUserId;

  SearchType _currentSearchType = SearchType.communities;
  ListingType _currentFeedType = ListingType.all;
  IconData? _feedTypeIcon = Icons.grid_view_rounded;
  String? _feedTypeLabel = AppLocalizations.of(GlobalContext.context)!.allPosts;

  @override
  void initState() {
    _scrollController.addListener(_onScroll);
    initPrefs();
    fetchActiveProfileAccount().then((activeProfile) => _previousUserId = activeProfile?.userId);
    context.read<SearchBloc>().add(GetTrendingCommunitiesEvent());
    super.initState();
  }

  Future<void> initPrefs() async {
    prefs = (await UserPreferences.instance).sharedPreferences;
    setState(() {
      sortType = SortType.values.byName(prefs!.getString("search_default_sort_type") ?? DEFAULT_SEARCH_SORT_TYPE.name);
      final sortTypeItem = allSortTypeItems.firstWhere((sortTypeItem) => sortTypeItem.payload == sortType);
      sortTypeIcon = sortTypeItem.icon;
      sortTypeLabel = sortTypeItem.label;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  void deactivate() {
    _saveToDB();
    super.deactivate();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (context.read<SearchBloc>().state.status != SearchStatus.done) {
        context.read<SearchBloc>().add(ContinueSearchEvent(query: _controller.text, sortType: sortType, searchType: _currentSearchType));
      }
    }
  }

  void resetTextField() {
    searchTextFieldFocus.requestFocus();
    _controller.clear(); // Clear the search field
  }

  _onChange(BuildContext context, String value) {
    context.read<SearchBloc>().add(StartSearchEvent(query: value, sortType: sortType, listingType: _currentFeedType, searchType: _currentSearchType));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    super.build(context);

    context.read<AnonymousSubscriptionsBloc>().add(GetSubscribedCommunitiesEvent());

    final bool isUserLoggedIn = context.read<AuthBloc>().state.isLoggedIn;
    final String? accountInstance = context.read<AuthBloc>().state.account?.instance;
    final String currentAnonymousInstance = context.read<ThunderBloc>().state.currentAnonymousInstance;

    return MultiBlocListener(
      listeners: [
        BlocListener<AnonymousSubscriptionsBloc, AnonymousSubscriptionsState>(listener: (context, state) {}),
        BlocListener<SearchBloc, SearchState>(listener: (context, state) {}),
        BlocListener<AccountBloc, AccountState>(listener: (context, state) async {
          final Account? activeProfile = await fetchActiveProfileAccount();

          // When account changes, that means our instance most likely changed, so reset search.
          if (state.status == AccountStatus.success &&
              ((activeProfile?.userId == null && _previousUserId != null) || state.personView?.person.id == activeProfile?.userId && _previousUserId != state.personView?.person.id)) {
            _controller.clear();
            context.read<SearchBloc>().add(ResetSearch());
            setState(() {});
            _previousUserId = activeProfile?.userId;
          }
        }),
        BlocListener<ThunderBloc, ThunderState>(
          listener: (context, state) {
            _controller.clear();
            context.read<SearchBloc>().add(ResetSearch());
            setState(() {});
            _previousUserId = null;
          },
        ),
      ],
      child: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state.focusSearchId > _previousFocusSearchId) {
            searchTextFieldFocus.requestFocus();
            _previousFocusSearchId = state.focusSearchId;
          }

          return Scaffold(
            appBar: AppBar(
                toolbarHeight: 90.0,
                scrolledUnderElevation: 0.0,
                title: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                  elevation: 8,
                  child: Stack(
                    children: [
                      TextField(
                        keyboardType: TextInputType.url,
                        focusNode: searchTextFieldFocus,
                        onChanged: (value) => debounce(const Duration(milliseconds: 300), _onChange, [context, value]),
                        controller: _controller,
                        onTap: () {
                          HapticFeedback.selectionClick();
                        },
                        decoration: InputDecoration(
                          fillColor: Theme.of(context).searchViewTheme.backgroundColor,
                          hintText: l10n.searchInstance((isUserLoggedIn ? accountInstance : currentAnonymousInstance) ?? ''),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: const BorderSide(
                              width: 0,
                              style: BorderStyle.none,
                            ),
                          ),
                          suffixIcon: _controller.text.isNotEmpty
                              ? SizedBox(
                                  width: 50,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          semanticLabel: l10n.clearSearch,
                                        ),
                                        onPressed: () {
                                          resetTextField();
                                          context.read<SearchBloc>().add(ResetSearch());
                                        },
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                          prefixIcon: const Icon(Icons.search_rounded),
                        ),
                      ),
                    ],
                  ),
                )),
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 15, top: 10, right: 15),
                  child: FadingEdgeScrollView.fromSingleChildScrollView(
                    gradientFractionOnStart: 0.1,
                    gradientFractionOnEnd: 0.1,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _searchFiltersScrollController,
                      child: Row(
                        children: [
                          ActionChip(
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(color: theme.dividerColor),
                            label: SizedBox(
                              height: 20,
                              child: Row(
                                children: [
                                  Text(_currentSearchType.name.capitalize),
                                  const Icon(Icons.arrow_drop_down_rounded, size: 20),
                                ],
                              ),
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                showDragHandle: true,
                                builder: (ctx) => BottomSheetListPicker(
                                  title: l10n.selectSearchType,
                                  items: [
                                    ListPickerItem(label: l10n.communities, payload: SearchType.communities, icon: Icons.people_rounded),
                                    ListPickerItem(label: l10n.users, payload: SearchType.users, icon: Icons.person_rounded)
                                  ],
                                  onSelect: (value) {
                                    setState(() => _currentSearchType = value.payload);
                                    if (_controller.text.isNotEmpty) {
                                      context.read<SearchBloc>().add(StartSearchEvent(query: _controller.text, sortType: sortType, listingType: _currentFeedType, searchType: value.payload));
                                    }
                                  },
                                  previouslySelected: _currentSearchType,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          ActionChip(
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(color: theme.dividerColor),
                            label: SizedBox(
                              height: 20,
                              child: Row(
                                children: [
                                  Icon(sortTypeIcon, size: 15),
                                  const SizedBox(width: 5),
                                  Text(sortTypeLabel ?? l10n.sortBy),
                                  const Icon(Icons.arrow_drop_down_rounded, size: 20),
                                ],
                              ),
                            ),
                            onPressed: () => showSortBottomSheet(context),
                          ),
                          const SizedBox(width: 10),
                          ActionChip(
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(color: theme.dividerColor),
                            label: SizedBox(
                              height: 20,
                              child: Row(
                                children: [
                                  Icon(_feedTypeIcon, size: 15),
                                  const SizedBox(width: 5),
                                  Text(_feedTypeLabel ?? l10n.feed),
                                  const Icon(Icons.arrow_drop_down_rounded, size: 20),
                                ],
                              ),
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                showDragHandle: true,
                                builder: (ctx) => BottomSheetListPicker(
                                  title: l10n.selectFeedType,
                                  items: [
                                    ListPickerItem(label: l10n.subscriptions, payload: ListingType.subscribed, icon: Icons.view_list_rounded),
                                    ListPickerItem(label: l10n.localPosts, payload: ListingType.local, icon: Icons.home_rounded),
                                    ListPickerItem(label: l10n.allPosts, payload: ListingType.all, icon: Icons.grid_view_rounded)
                                  ],
                                  onSelect: (value) {
                                    setState(() {
                                      if (value.payload == ListingType.subscribed) {
                                        _feedTypeLabel = l10n.subscriptions;
                                        _feedTypeIcon = Icons.view_list_rounded;
                                      } else if (value.payload == ListingType.local) {
                                        _feedTypeLabel = l10n.localPosts;
                                        _feedTypeIcon = Icons.home_rounded;
                                      } else if (value.payload == ListingType.all) {
                                        _feedTypeLabel = l10n.allPosts;
                                        _feedTypeIcon = Icons.grid_view_rounded;
                                      }
                                      _currentFeedType = value.payload;
                                    });
                                    if (_controller.text.isNotEmpty) {
                                      context.read<SearchBloc>().add(StartSearchEvent(query: _controller.text, sortType: sortType, listingType: value.payload, searchType: _currentSearchType));
                                    }
                                  },
                                  previouslySelected: _currentFeedType,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: _getSearchBody(context, state, isUserLoggedIn, accountInstance, currentAnonymousInstance),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _getSearchBody(BuildContext context, SearchState state, bool isUserLoggedIn, String? accountInstance, String currentAnonymousInstance) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    switch (state.status) {
      case SearchStatus.initial:
      case SearchStatus.trending:
        return AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: state.trendingCommunities?.isNotEmpty == true && _currentSearchType == SearchType.communities ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.search_rounded, size: 80, color: theme.dividerColor),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  switch (_currentSearchType) {
                    SearchType.communities => l10n.searchCommunitiesFederatedWith((isUserLoggedIn ? accountInstance : currentAnonymousInstance) ?? ''),
                    SearchType.users => l10n.searchUsersFederatedWith((isUserLoggedIn ? accountInstance : currentAnonymousInstance) ?? ''),
                    _ => '',
                  },
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.dividerColor),
                ),
              ),
            ],
          ),
          secondChild: state.trendingCommunities?.isNotEmpty == true
              ? SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        child: Text(
                          l10n.trendingCommunities,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.trendingCommunities!.length,
                        itemBuilder: (BuildContext context, int index) {
                          CommunityView communityView = state.trendingCommunities![index];
                          final Set<int> currentSubscriptions = context.read<AnonymousSubscriptionsBloc>().state.ids;
                          return _buildCommunityEntry(communityView, isUserLoggedIn, currentSubscriptions);
                        },
                      ),
                    ],
                  ),
                )
              : Container(),
        );
      case SearchStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case SearchStatus.refreshing:
      case SearchStatus.success:
      case SearchStatus.done:
        if ((_currentSearchType == SearchType.communities && state.communities?.isNotEmpty != true) || (_currentSearchType == SearchType.users && state.users?.isNotEmpty != true)) {
          return Center(
            child: Text(
              switch (_currentSearchType) {
                SearchType.communities => l10n.noCommunitiesFound,
                SearchType.users => l10n.noUsersFound,
                _ => '',
              },
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.dividerColor),
            ),
          );
        }
        if (_currentSearchType == SearchType.communities) {
          return FadingEdgeScrollView.fromScrollView(
            gradientFractionOnEnd: 0,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: state.communities!.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == state.communities!.length) {
                  return state.status == SearchStatus.refreshing
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Container();
                } else {
                  CommunityView communityView = state.communities![index];
                  final Set<int> currentSubscriptions = context.read<AnonymousSubscriptionsBloc>().state.ids;
                  return _buildCommunityEntry(communityView, isUserLoggedIn, currentSubscriptions);
                }
              },
            ),
          );
        } else if (_currentSearchType == SearchType.users) {
          return FadingEdgeScrollView.fromScrollView(
            gradientFractionOnEnd: 0,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: state.users!.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == state.users!.length) {
                  return state.status == SearchStatus.refreshing
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Container();
                } else {
                  PersonView personView = state.users![index];
                  return _buildUserEntry(personView);
                }
              },
            ),
          );
        } else {
          return Container();
        }
      case SearchStatus.empty:
        return Center(child: Text(l10n.empty));
      case SearchStatus.failure:
        return ErrorMessage(
          message: state.errorMessage,
          action: () => {context.read<SearchBloc>().add(StartSearchEvent(query: _controller.value.text, sortType: sortType, listingType: _currentFeedType, searchType: _currentSearchType))},
          actionText: l10n.retry,
        );
    }
  }

  Widget _buildCommunityEntry(CommunityView communityView, bool isUserLoggedIn, Set<int> currentSubscriptions) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Tooltip(
      excludeFromSemantics: true,
      message: '${communityView.community.title}\n${communityView.community.name} · ${fetchInstanceNameFromUrl(communityView.community.actorId)}',
      preferBelow: false,
      child: ListTile(
        leading: CommunityIcon(community: communityView.community, radius: 25),
        title: Text(
          communityView.community.title,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(children: [
          Flexible(
            child: Text(
              '${communityView.community.name} · ${fetchInstanceNameFromUrl(communityView.community.actorId)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            ' · ${communityView.counts.subscribers}',
            semanticsLabel: l10n.countSubscribers(communityView.counts.subscribers),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.people_rounded, size: 16.0),
        ]),
        trailing: IconButton(
          onPressed: () {
            SubscribedType subscriptionStatus = _getCurrentSubscriptionStatus(isUserLoggedIn, communityView, currentSubscriptions);
            _onSubscribeIconPressed(isUserLoggedIn, context, communityView);
            showSnackbar(context, subscriptionStatus == SubscribedType.notSubscribed ? l10n.addedCommunityToSubscriptions : l10n.removedCommunityFromSubscriptions);
            context.read<AccountBloc>().add(GetAccountInformation());
          },
          icon: Icon(
            switch (_getCurrentSubscriptionStatus(isUserLoggedIn, communityView, currentSubscriptions)) {
              SubscribedType.notSubscribed => Icons.add_circle_outline_rounded,
              SubscribedType.pending => Icons.pending_outlined,
              SubscribedType.subscribed => Icons.remove_circle_outline_rounded,
            },
          ),
          tooltip: switch (_getCurrentSubscriptionStatus(isUserLoggedIn, communityView, currentSubscriptions)) {
            SubscribedType.notSubscribed => l10n.subscribe,
            SubscribedType.pending => l10n.unsubscribePending,
            SubscribedType.subscribed => l10n.unsubscribe,
          },
          visualDensity: VisualDensity.compact,
        ),
        onTap: () {
          navigateToFeedPage(context, feedType: FeedType.community, communityId: communityView.community.id);
        },
      ),
    );
  }

  Widget _buildUserEntry(PersonView personView) {
    return Tooltip(
      excludeFromSemantics: true,
      message: '${personView.person.displayName ?? personView.person.name}\n${personView.person.name} · ${fetchInstanceNameFromUrl(personView.person.actorId)}',
      preferBelow: false,
      child: ListTile(
        leading: UserAvatar(person: personView.person, radius: 25),
        title: Text(
          personView.person.displayName ?? personView.person.name,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(children: [
          Flexible(
            child: Text(
              '${personView.person.name} · ${fetchInstanceNameFromUrl(personView.person.actorId)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        onTap: () {
          navigateToFeedPage(context, feedType: FeedType.user, userId: personView.person.id);
        },
      ),
    );
  }

  void showSortBottomSheet(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (builderContext) => SortPicker(
        title: l10n.sortOptions,
        onSelect: (selected) {
          setState(() {
            sortType = selected.payload;
            sortTypeIcon = selected.icon;
            sortTypeLabel = selected.label;
          });

          prefs!.setString("search_default_sort_type", selected.payload.name);

          if (_controller.text.isNotEmpty) {
            context.read<SearchBloc>().add(
                  StartSearchEvent(query: _controller.text, sortType: sortType, listingType: _currentFeedType, searchType: _currentSearchType),
                );
          }
        },
        previouslySelected: sortType,
      ),
    );
  }

  SubscribedType _getCurrentSubscriptionStatus(bool isUserLoggedIn, CommunityView communityView, Set<int> currentSubscriptions) {
    if (isUserLoggedIn) {
      return communityView.subscribed;
    }
    bool isSubscribed = newAnonymousSubscriptions.contains(communityView.community) || (currentSubscriptions.contains(communityView.community.id) && !removedSubs.contains(communityView.community.id));
    return isSubscribed ? SubscribedType.subscribed : SubscribedType.notSubscribed;
  }

  void _onSubscribeIconPressed(bool isUserLoggedIn, BuildContext context, CommunityView communityView) {
    if (isUserLoggedIn) {
      context.read<SearchBloc>().add(ChangeCommunitySubsciptionStatusEvent(
            communityId: communityView.community.id,
            follow: communityView.subscribed == SubscribedType.notSubscribed ? true : false,
            query: _controller.text,
          ));
      return;
    }

    Set<int> currentSubscriptions = context.read<AnonymousSubscriptionsBloc>().state.ids;
    setState(() {
      if (currentSubscriptions.contains(communityView.community.id) && !removedSubs.contains(communityView.community.id)) {
        removedSubs.add(communityView.community.id);
      } else if (newAnonymousSubscriptions.contains(communityView.community)) {
        newAnonymousSubscriptions.remove(communityView.community);
      } else if (removedSubs.contains(communityView.community.id)) {
        removedSubs.remove(communityView.community.id);
      } else {
        newAnonymousSubscriptions.add(communityView.community);
      }
    });
    return;
  }

  void _saveToDB() {
    if (newAnonymousSubscriptions.isNotEmpty) {
      context.read<AnonymousSubscriptionsBloc>().add(AddSubscriptionsEvent(communities: newAnonymousSubscriptions));
    }
    if (removedSubs.isNotEmpty) {
      context.read<AnonymousSubscriptionsBloc>().add(DeleteSubscriptionsEvent(ids: removedSubs));
    }
  }
}
