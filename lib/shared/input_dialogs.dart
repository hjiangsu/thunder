import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:lemmy_api_client/v3.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:collection/collection.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:thunder/account/models/account.dart';
import 'package:thunder/core/auth/helpers/fetch_account.dart';
import 'package:thunder/core/singletons/lemmy_client.dart';
import 'package:thunder/shared/community_icon.dart';
import 'package:thunder/shared/user_avatar.dart';
import 'package:thunder/utils/instance.dart';

/// Shows a dialog which allows typing/search for a user
void showUserInputDialog(BuildContext context, {required String title, required void Function(PersonView) onUserSelected}) async {
  Future<String?> onSubmitted({PersonView? payload, String? value}) async {
    if (payload != null) {
      onUserSelected(payload);
      Navigator.of(context).pop();
    } else if (value != null) {
      // Normalize the username
      final String? normalizedUsername = await getLemmyUser(value);
      if (normalizedUsername != null) {
        try {
          Account? account = await fetchActiveProfileAccount();
          final GetPersonDetailsResponse getPersonDetailsResponse = await LemmyClient.instance.lemmyApiV3.run(GetPersonDetails(
            auth: account?.jwt,
            username: normalizedUsername,
          ));

          onUserSelected(getPersonDetailsResponse.personView);

          Navigator.of(context).pop();
        } catch (e) {
          return AppLocalizations.of(context)!.unableToFindUser;
        }
      } else {
        return AppLocalizations.of(context)!.unableToFindUser;
      }
    }
    return null;
  }

  showInputDialog<PersonView>(
    context: context,
    title: title,
    inputLabel: AppLocalizations.of(context)!.username,
    onSubmitted: onSubmitted,
    getSuggestions: getUserSuggestions,
    suggestionBuilder: (payload) => buildUserSuggestionWidget(payload),
  );
}

Future<Iterable<PersonView>> getUserSuggestions(String query) async {
  if (query.isNotEmpty != true) {
    return const Iterable.empty();
  }
  Account? account = await fetchActiveProfileAccount();
  final SearchResponse searchResponse = await LemmyClient.instance.lemmyApiV3.run(Search(
    q: query,
    auth: account?.jwt,
    type: SearchType.users,
    limit: 20,
  ));
  return searchResponse.users;
}

Widget buildUserSuggestionWidget(PersonView payload, {void Function(PersonView)? onSelected}) {
  return Tooltip(
    message: '${payload.person.name}@${fetchInstanceNameFromUrl(payload.person.actorId)}',
    preferBelow: false,
    child: InkWell(
      onTap: onSelected == null ? null : () => onSelected(payload),
      child: ListTile(
        leading: UserAvatar(person: payload.person),
        title: Text(
          payload.person.displayName ?? payload.person.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: TextScroll(
          '${payload.person.name}@${fetchInstanceNameFromUrl(payload.person.actorId)}',
          delayBefore: const Duration(seconds: 2),
          pauseBetween: const Duration(seconds: 3),
          velocity: const Velocity(pixelsPerSecond: Offset(50, 0)),
        ),
      ),
    ),
  );
}

/// Shows a dialog which allows typing/search for a community
void showCommunityInputDialog(BuildContext context, {required String title, required void Function(CommunityView) onCommunitySelected, Iterable<CommunityView>? emptySuggestions}) async {
  Future<String?> onSubmitted({CommunityView? payload, String? value}) async {
    if (payload != null) {
      onCommunitySelected(payload);
      Navigator.of(context).pop();
    } else if (value != null) {
      // Normalize the community name
      final String? normalizedCommunity = await getLemmyCommunity(value);
      if (normalizedCommunity != null) {
        try {
          Account? account = await fetchActiveProfileAccount();
          final GetCommunityResponse getCommunityResponse = await LemmyClient.instance.lemmyApiV3.run(GetCommunity(
            auth: account?.jwt,
            name: normalizedCommunity,
          ));

          onCommunitySelected(getCommunityResponse.communityView);

          Navigator.of(context).pop();
        } catch (e) {
          return AppLocalizations.of(context)!.unableToFindCommunity;
        }
      } else {
        return AppLocalizations.of(context)!.unableToFindCommunity;
      }
    }
    return null;
  }

  showInputDialog<CommunityView>(
    context: context,
    title: title,
    inputLabel: AppLocalizations.of(context)!.community,
    onSubmitted: onSubmitted,
    getSuggestions: (query) => getCommunitySuggestions(query, emptySuggestions),
    suggestionBuilder: buildCommunitySuggestionWidget,
  );
}

Future<Iterable<CommunityView>> getCommunitySuggestions(String query, Iterable<CommunityView>? emptySuggestions) async {
  if (query.isNotEmpty != true) {
    return emptySuggestions ?? const Iterable.empty();
  }
  Account? account = await fetchActiveProfileAccount();
  final SearchResponse searchResponse = await LemmyClient.instance.lemmyApiV3.run(Search(
    q: query,
    auth: account?.jwt,
    type: SearchType.communities,
    limit: 20,
    sort: SortType.topAll,
  ));
  return searchResponse.communities;
}

Widget buildCommunitySuggestionWidget(payload, {void Function(CommunityView)? onSelected}) {
  return Tooltip(
    message: '${payload.community.name}@${fetchInstanceNameFromUrl(payload.community.actorId)}',
    preferBelow: false,
    child: InkWell(
      onTap: onSelected == null ? null : () => onSelected(payload),
      child: ListTile(
        leading: CommunityIcon(community: payload.community),
        title: Text(
          payload.community.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: TextScroll(
          '${payload.community.name}@${fetchInstanceNameFromUrl(payload.community.actorId)}',
          delayBefore: const Duration(seconds: 2),
          pauseBetween: const Duration(seconds: 3),
          velocity: const Velocity(pixelsPerSecond: Offset(50, 0)),
        ),
      ),
    ),
  );
}

/// Shows a dialog which allows typing/search for an instance
void showInstanceInputDialog(BuildContext context, {required String title, required void Function(Instance) onInstanceSelected, Iterable<Instance>? emptySuggestions}) async {
  Account? account = await fetchActiveProfileAccount();

  GetFederatedInstancesResponse getFederatedInstancesResponse = await LemmyClient.instance.lemmyApiV3.run(
    GetFederatedInstances(
      auth: account?.jwt,
    ),
  );

  Future<String?> onSubmitted({Instance? payload, String? value}) async {
    if (payload != null) {
      onInstanceSelected(payload);
      Navigator.of(context).pop();
    } else if (value != null) {
      final Instance? instance = getFederatedInstancesResponse.federatedInstances?.linked.firstWhereOrNull((Instance instance) => instance.domain == value);

      if (instance != null) {
        onInstanceSelected(instance);
        Navigator.of(context).pop();
      } else {
        return AppLocalizations.of(context)!.unableToFindInstance;
      }
    }

    return null;
  }

  if (context.mounted) {
    showInputDialog<Instance>(
      context: context,
      title: title,
      inputLabel: AppLocalizations.of(context)!.instance,
      onSubmitted: onSubmitted,
      getSuggestions: (query) => getInstanceSuggestions(query, getFederatedInstancesResponse.federatedInstances?.linked),
      suggestionBuilder: (payload) => buildInstanceSuggestionWidget(payload, context: context),
    );
  }
}

Future<Iterable<Instance>> getInstanceSuggestions(String query, Iterable<Instance>? emptySuggestions) async {
  if (query.isEmpty) {
    return const Iterable.empty();
  }

  Iterable<Instance> filteredInstances = emptySuggestions?.where((Instance instance) => instance.domain.contains(query)) ?? const Iterable.empty();
  return filteredInstances;
}

Widget buildInstanceSuggestionWidget(payload, {void Function(Instance)? onSelected, BuildContext? context}) {
  final theme = Theme.of(context!);

  return Tooltip(
    message: '${payload.domain}',
    preferBelow: false,
    child: InkWell(
      onTap: onSelected == null ? null : () => onSelected(payload),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          maxRadius: 16.0,
          child: Text(
            payload.domain[0].toUpperCase(),
            semanticsLabel: '',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
        ),
        title: Text(
          payload.domain,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  );
}

/// Shows a dialog which takes input and offers suggestions
void showInputDialog<T>({
  required BuildContext context,
  required String title,
  required String inputLabel,
  required Future<String?> Function({T? payload, String? value}) onSubmitted,
  required Future<Iterable<T>> Function(String query) getSuggestions,
  required Widget Function(T payload) suggestionBuilder,
}) async {
  final textController = TextEditingController();

  await showDialog(
    context: context,
    builder: (context) {
      bool okEnabled = false;
      String? error;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: min(MediaQuery.of(context).size.width, 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TypeAheadField<T>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: textController,
                      onChanged: (value) => setState(() {
                        okEnabled = value.isNotEmpty;
                        error = null;
                      }),
                      autofocus: true,
                      decoration: InputDecoration(
                        isDense: true,
                        border: const OutlineInputBorder(),
                        labelText: inputLabel,
                        errorText: error,
                      ),
                      onSubmitted: (text) async {
                        setState(() => okEnabled = false);
                        final String? submitError = await onSubmitted(value: text);
                        setState(() => error = submitError);
                      },
                    ),
                    suggestionsCallback: getSuggestions,
                    itemBuilder: (context, payload) => suggestionBuilder(payload),
                    onSuggestionSelected: (payload) async {
                      setState(() => okEnabled = false);
                      final String? submitError = await onSubmitted(payload: payload);
                      setState(() => error = submitError);
                    },
                    hideOnEmpty: true,
                    hideOnLoading: true,
                    hideOnError: true,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      const SizedBox(width: 5),
                      FilledButton(
                        onPressed: okEnabled
                            ? () async {
                                setState(() => okEnabled = false);
                                final String? submitError = await onSubmitted(value: textController.text);
                                setState(() => error = submitError);
                              }
                            : null,
                        child: Text(AppLocalizations.of(context)!.ok),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
