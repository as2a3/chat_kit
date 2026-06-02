import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_kit/src/models/chat_message.dart';
import 'package:chat_kit/src/models/message_type.dart';
import 'package:chat_kit/src/ui/theme/chat_theme.dart';
import 'package:chat_kit/src/utils/formatters.dart';
import 'package:flutter/material.dart';

/// Renders the media portion of a [ChatMessage] inside a bubble: an image
/// preview, a video placeholder, a voice/audio row, or a file card.
class MediaMessage extends StatelessWidget {
  /// Creates the media view for [message].
  const MediaMessage({
    required this.message,
    required this.isMine,
    super.key,
    this.uploadProgress,
    this.onTap,
  });

  /// The message whose media is rendered.
  final ChatMessage message;

  /// Whether the message was sent by the current user.
  final bool isMine;

  /// 0..1 while uploading, null once complete.
  final double? uploadProgress;

  /// Called when the media is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return _image(context);
      case MessageType.video:
        return _video(context);
      case MessageType.audio:
        return _audio(context);
      case MessageType.file:
        return _file(context);
      case MessageType.text:
      case MessageType.system:
        return const SizedBox.shrink();
    }
  }

  Widget _uploadingOverlay() {
    if (uploadProgress == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: Container(
        color: Colors.black38,
        alignment: Alignment.center,
        child: CircularProgressIndicator(
          value: uploadProgress == 0 ? null : uploadProgress,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _image(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, minWidth: 200),
              child: message.mediaUrl == null
                  ? const SizedBox(height: 200, width: 200)
                  : CachedNetworkImage(
                      imageUrl: message.mediaUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const SizedBox(
                        height: 200,
                        width: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.broken_image, size: 48),
                    ),
            ),
            _uploadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _video(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 200,
              width: 240,
              color: Colors.black87,
              child: message.mediaThumbUrl != null
                  ? CachedNetworkImage(
                      imageUrl: message.mediaThumbUrl!,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            const CircleAvatar(
              backgroundColor: Colors.black54,
              child: Icon(Icons.play_arrow, color: Colors.white, size: 32),
            ),
            _uploadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _audio(BuildContext context) {
    final theme = ChatTheme.of(context);
    return SizedBox(
      width: 220,
      child: Row(
        children: [
          Icon(Icons.play_circle_fill, size: 36, color: theme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: theme.metaText.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            message.durationMs != null
                ? ChatFormatters.duration(message.durationMs!)
                : '0:00',
            style: TextStyle(color: theme.metaText, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _file(BuildContext context) {
    final theme = ChatTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 230,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.primary.withValues(alpha: 0.15),
              child: Icon(Icons.insert_drive_file, color: theme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? 'File',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (message.fileSize != null)
                    Text(
                      ChatFormatters.fileSize(message.fileSize!),
                      style: TextStyle(color: theme.metaText, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
