import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ToggleOption extends StatelessWidget {
  // Appearance
  final IconData? iconEnabled;
  final IconData? iconDisabled;

  // General
  final String description;
  final String? subtitle;
  final String? semanticLabel;
  final bool? value;

  // Callback
  final Function(bool)? onToggle;
  final Function()? onTap;
  final Function()? onLongPress;

  final List<Widget>? additionalWidgets;

  const ToggleOption({
    super.key,
    required this.description,
    this.subtitle,
    this.semanticLabel,
    required this.value,
    this.iconEnabled,
    this.iconDisabled,
    this.onToggle,
    this.additionalWidgets,
    this.onTap,
    this.onLongPress,
  });

  void onTapInkWell() {
    if (onTap == null && value != null) {
      onToggle?.call(!value!);
    }

    onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: semanticLabel ?? description,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(50)),
        onTap: onToggle == null ? null : onTapInkWell,
        onLongPress: onToggle == null ? null : () => onLongPress?.call(),
        child: Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (iconEnabled != null && iconDisabled != null) Icon(value == true ? iconEnabled : iconDisabled),
                  if (iconEnabled != null && iconDisabled != null) const SizedBox(width: 8.0),
                  Column(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 140),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              // We will set semantics at the top widget level
                              // rather than having the Text widget read automatically
                              excludeSemantics: true,
                              child: Text(
                                description,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            if (subtitle != null) Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.8))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (additionalWidgets?.isNotEmpty == true) ...[
                Expanded(
                  child: Container(),
                ),
                ...additionalWidgets!,
                const SizedBox(
                  width: 20,
                ),
              ],
              if (value != null)
                Switch(
                  value: value!,
                  onChanged: onToggle == null
                      ? null
                      : (bool value) {
                          HapticFeedback.lightImpact();
                          onToggle?.call(value);
                        },
                ),
              if (value == null)
                const SizedBox(
                  height: 50,
                  width: 60,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
