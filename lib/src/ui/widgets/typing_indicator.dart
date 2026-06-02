import 'package:chat_kit/src/ui/theme/chat_theme.dart';
import 'package:flutter/material.dart';

/// Animated three-dot "typing…" bubble shown at the bottom of the thread.
class TypingIndicator extends StatefulWidget {
  /// Creates the animated typing indicator.
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.incomingBubble,
          borderRadius: BorderRadius.circular(theme.bubbleRadius),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = (_controller.value + i * 0.2) % 1.0;
                final opacity = (0.3 + 0.7 * (1 - (t - 0.5).abs() * 2)).clamp(
                  0.3,
                  1.0,
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Opacity(
                    opacity: opacity,
                    child: CircleAvatar(
                      radius: 3.5,
                      backgroundColor: theme.metaText,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
