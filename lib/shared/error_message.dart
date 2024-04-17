import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ErrorMessage extends StatelessWidget {
  final String? title;
  final String? message;
  final List<({String text, void Function() action, bool loading})>? actions;

  const ErrorMessage({
    super.key,
    this.title,
    this.message,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.warning_rounded, size: 100, color: Colors.red.shade300),
            const SizedBox(height: 32.0),
            Text(
              title ?? AppLocalizations.of(context)!.somethingWentWrong,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              message ?? AppLocalizations.of(context)!.missingErrorMessage,
              style: theme.textTheme.labelLarge?.copyWith(color: theme.dividerColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32.0),
            if (actions?.isNotEmpty == true)
              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    onPressed: actions![0].loading == true ? null : () => actions![0].action.call(),
                    child: actions![0].loading == true
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(),
                          )
                        : Text(actions![0].text),
                  ),
                  if (actions!.length > 1) ...[
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        for (var action in actions!.skip(1)) ...[
                          if (actions!.indexOf(action) > 1) const SizedBox(width: 10),
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                              onPressed: action.loading == true ? null : () => action.action.call(),
                              child: action.loading == true
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(),
                                    )
                                  : Text(action.text),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ],
              )
          ],
        ),
      ),
    );
  }
}
