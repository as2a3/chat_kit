import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Circular avatar that shows a network image when available, otherwise the
/// user's initials on a color derived deterministically from their name.
class Avatar extends StatelessWidget {
  /// Creates an avatar for [name], optionally backed by [photoUrl].
  const Avatar({
    required this.name,
    super.key,
    this.photoUrl,
    this.radius = 24,
    this.isGroup = false,
  });

  /// Display name used to derive initials and the fallback color.
  final String name;

  /// Optional network image URL; when set and non-empty it is shown.
  final String? photoUrl;

  /// Radius of the circular avatar.
  final double radius;

  /// Whether this avatar represents a group (shows a group icon).
  final bool isGroup;

  static const _palette = [
    Color(0xFF1ABC9C),
    Color(0xFF3498DB),
    Color(0xFF9B59B6),
    Color(0xFFE67E22),
    Color(0xFFE74C3C),
    Color(0xFF2ECC71),
    Color(0xFF34495E),
    Color(0xFFF39C12),
  ];

  Color get _bgColor {
    if (name.isEmpty) return _palette.first;
    return _palette[name.codeUnits.fold(0, (a, b) => a + b) % _palette.length];
  }

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: _bgColor,
        backgroundImage: CachedNetworkImageProvider(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _bgColor,
      child: isGroup
          ? Icon(Icons.group, size: radius, color: Colors.white)
          : Text(
              _initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
