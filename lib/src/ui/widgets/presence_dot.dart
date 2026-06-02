import 'package:chat_kit/src/ui/theme/chat_theme.dart';
import 'package:chat_kit/src/ui/widgets/avatar.dart' show Avatar;
import 'package:flutter/material.dart';

/// Small status dot, typically overlaid on an [Avatar], shown only when online.
class PresenceDot extends StatelessWidget {
  /// Creates a presence dot that renders only when [online] is true.
  const PresenceDot({
    required this.online,
    super.key,
    this.size = 14,
    this.borderColor,
  });

  /// Whether the user is online; the dot is hidden when false.
  final bool online;

  /// Diameter of the dot in logical pixels.
  final double size;

  /// Color of the surrounding border; defaults to the theme background.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    if (!online) return const SizedBox.shrink();
    final theme = ChatTheme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.onlineColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? theme.background,
          width: 2,
        ),
      ),
    );
  }
}
