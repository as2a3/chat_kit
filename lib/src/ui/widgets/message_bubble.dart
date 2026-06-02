import 'package:chat_kit/src/models/chat_message.dart';
import 'package:chat_kit/src/models/message_status.dart';
import 'package:chat_kit/src/models/message_type.dart';
import 'package:chat_kit/src/ui/theme/chat_theme.dart';
import 'package:chat_kit/src/ui/widgets/media_message.dart';
import 'package:chat_kit/src/utils/formatters.dart';
import 'package:flutter/material.dart';

/// A WhatsApp-style chat bubble. Outgoing (mine) bubbles align right with the
/// outgoing color and show delivery ticks; incoming align left and (in groups)
/// show the sender's name.
class MessageBubble extends StatelessWidget {
  /// Creates a chat bubble for [message].
  const MessageBubble({
    required this.message,
    required this.isMine,
    required this.otherParticipants,
    super.key,
    this.showSenderName = false,
    this.senderName,
    this.uploadProgress,
    this.onMediaTap,
  });

  /// The message to render.
  final ChatMessage message;

  /// Whether the message was sent by the current user.
  final bool isMine;

  /// Other participant uids, used to derive read/delivered status.
  final Iterable<String> otherParticipants;

  /// Whether to show the sender's name above the bubble (group chats).
  final bool showSenderName;

  /// Name of the sender, shown when [showSenderName] is true.
  final String? senderName;

  /// Upload progress (0..1) for outgoing media, null when not uploading.
  final double? uploadProgress;

  /// Called when the media portion of the bubble is tapped.
  final VoidCallback? onMediaTap;

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);

    if (message.type == MessageType.system) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            message.text,
            style: TextStyle(color: theme.metaText, fontSize: 12),
          ),
        ),
      );
    }

    final radius = Radius.circular(theme.bubbleRadius);
    final hasMedia = message.type.isMedia;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: EdgeInsets.all(hasMedia ? 4 : 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isMine ? theme.outgoingBubble : theme.incomingBubble,
          borderRadius: BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft: isMine ? radius : Radius.zero,
            bottomRight: isMine ? Radius.zero : radius,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSenderName && !isMine && senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2, left: 2),
                child: Text(
                  senderName!,
                  style: TextStyle(
                    color: theme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            if (hasMedia)
              MediaMessage(
                message: message,
                isMine: isMine,
                uploadProgress: uploadProgress,
                onTap: onMediaTap,
              ),
            if (message.text.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  top: hasMedia ? 6 : 0,
                  left: hasMedia ? 6 : 0,
                  right: hasMedia ? 6 : 0,
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isMine ? theme.outgoingText : theme.incomingText,
                    fontSize: 15,
                  ),
                ),
              ),
            _meta(theme),
          ],
        ),
      ),
    );
  }

  Widget _meta(ChatTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 6, right: 6, bottom: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            message.isPending ? '⏳' : ChatFormatters.time(message.timestamp!),
            style: TextStyle(color: theme.metaText, fontSize: 11),
          ),
          if (isMine && !message.isPending) ...[
            const SizedBox(width: 4),
            _ticks(theme),
          ],
        ],
      ),
    );
  }

  Widget _ticks(ChatTheme theme) {
    final status = message.statusFor(otherParticipants);
    final icon = status == MessageStatus.sent ? Icons.done : Icons.done_all;
    final color = status == MessageStatus.read
        ? theme.readReceiptColor
        : theme.metaText;
    return Icon(icon, size: 15, color: color);
  }
}
