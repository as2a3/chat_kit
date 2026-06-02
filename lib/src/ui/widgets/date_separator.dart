import 'package:chat_kit/src/ui/theme/chat_theme.dart';
import 'package:flutter/material.dart';

/// The little centered "Today / Yesterday / date" pill between message groups.
class DateSeparator extends StatelessWidget {
  /// Creates a date separator showing [label].
  const DateSeparator({required this.label, super.key});

  /// The text shown inside the pill (e.g. "Today", "Yesterday", a date).
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: theme.dateSeparatorBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: theme.dateSeparatorText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
