import 'package:flutter/material.dart';
import 'package:lemmy_api_client/v3.dart';
import 'package:thunder/core/singletons/lemmy_client.dart';
import 'package:thunder/shared/picker_item.dart';
import 'package:thunder/utils/bottom_sheet_list_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:thunder/utils/global_context.dart';

List<ListPickerItem<SortType>> topSortTypeItems = [
  ListPickerItem(
    payload: SortType.topHour,
    icon: Icons.check_box_outline_blank,
    label: AppLocalizations.of(GlobalContext.context)!.topHour,
  ),
  ListPickerItem(
    payload: SortType.topSixHour,
    icon: Icons.calendar_view_month,
    label: AppLocalizations.of(GlobalContext.context)!.topSixHour,
  ),
  ListPickerItem(
    payload: SortType.topTwelveHour,
    icon: Icons.calendar_view_week,
    label: AppLocalizations.of(GlobalContext.context)!.topTwelveHour,
  ),
  ListPickerItem(
    payload: SortType.topDay,
    icon: Icons.today,
    label: AppLocalizations.of(GlobalContext.context)!.topDay,
  ),
  ListPickerItem(
    payload: SortType.topWeek,
    icon: Icons.view_week_sharp,
    label: AppLocalizations.of(GlobalContext.context)!.topWeek,
  ),
  ListPickerItem(
    payload: SortType.topMonth,
    icon: Icons.calendar_month,
    label: AppLocalizations.of(GlobalContext.context)!.topMonth,
  ),
  ListPickerItem(
    payload: SortType.topThreeMonths,
    icon: Icons.calendar_month_outlined,
    label: AppLocalizations.of(GlobalContext.context)!.topThreeMonths,
  ),
  ListPickerItem(
    payload: SortType.topSixMonths,
    icon: Icons.calendar_today_outlined,
    label: AppLocalizations.of(GlobalContext.context)!.topSixMonths,
  ),
  ListPickerItem(
    payload: SortType.topNineMonths,
    icon: Icons.calendar_view_day_outlined,
    label: AppLocalizations.of(GlobalContext.context)!.topNineMonths,
  ),
  ListPickerItem(
    payload: SortType.topYear,
    icon: Icons.calendar_today,
    label: AppLocalizations.of(GlobalContext.context)!.topYear,
  ),
  ListPickerItem(
    payload: SortType.topAll,
    icon: Icons.military_tech,
    label: AppLocalizations.of(GlobalContext.context)!.topAll,
  ),
];

List<ListPickerItem<SortType>> allSortTypeItems = [...SortPicker.getDefaultSortTypeItems(includeVersionSpecificFeature: IncludeVersionSpecificFeature.always), ...topSortTypeItems];

class SortPicker extends BottomSheetListPicker<SortType> {
  final IncludeVersionSpecificFeature includeVersionSpecificFeature;

  static List<ListPickerItem<SortType>> getDefaultSortTypeItems({IncludeVersionSpecificFeature includeVersionSpecificFeature = IncludeVersionSpecificFeature.ifSupported}) => [
        ListPickerItem(
          payload: SortType.hot,
          icon: Icons.local_fire_department_rounded,
          label: AppLocalizations.of(GlobalContext.context)!.hot,
        ),
        ListPickerItem(
          payload: SortType.active,
          icon: Icons.rocket_launch_rounded,
          label: AppLocalizations.of(GlobalContext.context)!.active,
        ),
        if (includeVersionSpecificFeature == IncludeVersionSpecificFeature.always ||
            (includeVersionSpecificFeature == IncludeVersionSpecificFeature.ifSupported && LemmyClient.instance.supportsFeature(LemmyFeature.sortTypeScaled)))
          ListPickerItem(
            payload: SortType.scaled,
            icon: Icons.line_weight_rounded,
            label: AppLocalizations.of(GlobalContext.context)!.scaled,
          ),
        if (includeVersionSpecificFeature == IncludeVersionSpecificFeature.always ||
            (includeVersionSpecificFeature == IncludeVersionSpecificFeature.ifSupported && LemmyClient.instance.supportsFeature(LemmyFeature.sortTypeControversial)))
          ListPickerItem(
            payload: SortType.controversial,
            icon: Icons.warning_rounded,
            label: AppLocalizations.of(GlobalContext.context)!.controversial,
          ),
        ListPickerItem(
          payload: SortType.new_,
          icon: Icons.auto_awesome_rounded,
          label: AppLocalizations.of(GlobalContext.context)!.new_,
        ),
        ListPickerItem(
          payload: SortType.old,
          icon: Icons.access_time_outlined,
          label: AppLocalizations.of(GlobalContext.context)!.old,
        ),
        ListPickerItem(
          payload: SortType.mostComments,
          icon: Icons.comment_bank_rounded,
          label: AppLocalizations.of(GlobalContext.context)!.mostComments,
        ),
        ListPickerItem(
          payload: SortType.newComments,
          icon: Icons.add_comment_rounded,
          label: AppLocalizations.of(GlobalContext.context)!.newComments,
        ),
      ];

  SortPicker(
      {super.key,
      required super.onSelect,
      required super.title,
      List<ListPickerItem<SortType>>? items,
      super.previouslySelected,
      this.includeVersionSpecificFeature = IncludeVersionSpecificFeature.ifSupported})
      : super(items: items ?? getDefaultSortTypeItems(includeVersionSpecificFeature: includeVersionSpecificFeature));

  @override
  State<StatefulWidget> createState() => _SortPickerState();
}

class _SortPickerState extends State<SortPicker> {
  bool topSelected = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: topSelected ? topSortPicker() : defaultSortPicker(widget.includeVersionSpecificFeature),
      ),
    );
  }

  Widget defaultSortPicker(IncludeVersionSpecificFeature includeVersionSpecificFeature) {
    final theme = Theme.of(context);

    return Column(
      key: ValueKey<bool>(topSelected),
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0, left: 26.0, right: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.title,
              style: theme.textTheme.titleLarge!.copyWith(),
            ),
          ),
        ),
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ..._generateList(SortPicker.getDefaultSortTypeItems(includeVersionSpecificFeature: widget.includeVersionSpecificFeature), theme),
            PickerItem(
              label: AppLocalizations.of(GlobalContext.context)!.top,
              icon: Icons.military_tech,
              onSelected: () {
                setState(() {
                  topSelected = true;
                });
              },
              isSelected: topSortTypeItems.map((item) => item.payload).contains(widget.previouslySelected),
              trailingIcon: Icons.chevron_right,
            )
          ],
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget topSortPicker() {
    final theme = Theme.of(context);

    return Column(
      key: ValueKey<bool>(topSelected),
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Semantics(
          label: '${AppLocalizations.of(context)!.sortByTop},${AppLocalizations.of(context)!.backButton}',
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Material(
              borderRadius: BorderRadius.circular(50),
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () {
                  setState(() {
                    topSelected = false;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 10, 16.0, 10.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chevron_left,
                          size: 30,
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Semantics(
                          excludeSemantics: true,
                          child: Text(
                            AppLocalizations.of(context)!.sortByTop,
                            style: theme.textTheme.titleLarge!.copyWith(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ..._generateList(topSortTypeItems, theme),
          ],
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  List<Widget> _generateList(List<ListPickerItem<SortType>> items, ThemeData theme) {
    return items
        .map((item) => PickerItem(
            label: item.label,
            icon: item.icon,
            onSelected: () {
              Navigator.of(context).pop();
              widget.onSelect(item);
            },
            isSelected: widget.previouslySelected == item.payload))
        .toList();
  }
}
