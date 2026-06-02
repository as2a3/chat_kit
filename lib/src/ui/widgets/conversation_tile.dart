import 'package:chat_kit/src/models/conversation.dart';
import 'package:chat_kit/src/ui/theme/chat_theme.dart';
import 'package:chat_kit/src/ui/widgets/avatar.dart';
import 'package:chat_kit/src/ui/widgets/presence_dot.dart';
import 'package:chat_kit/src/utils/formatters.dart';
import 'package:flutter/material.dart';

/// A single row in the conversations list: avatar (+ presence), title, last
/// message preview, timestamp and unread badge — WhatsApp home style.
class ConversationTile extends StatelessWidget {
  /// Creates a conversation row for [conversation] from [currentUid]'s view.
  const ConversationTile({
    required this.conversation,
    required this.currentUid,
    required this.onTap,
    super.key,
    this.onLongPress,
    this.peerOnline = false,
  });

  /// The conversation to render.
  final Conversation conversation;

  /// Uid of the current user, used to resolve titles and unread counts.
  final String currentUid;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  /// Called when the tile is long-pressed.
  final VoidCallback? onLongPress;

  /// Whether the peer is online (shows a presence dot in 1:1 chats).
  final bool peerOnline;

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    final unread = conversation.unreadFor(currentUid);
    final last = conversation.lastMessage;
    final hasUnread = unread > 0;

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Avatar(
            name: conversation.titleFor(currentUid),
            photoUrl: conversation.avatarFor(currentUid),
            isGroup: conversation.isGroup,
            radius: 26,
          ),
          if (!conversation.isGroup && peerOnline)
            const Positioned(
              right: 0,
              bottom: 0,
              child: PresenceDot(online: true),
            ),
        ],
      ),
      title: Text(
        conversation.titleFor(currentUid),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: last == null
          ? null
          : Row(
              children: [
                if (last.senderId == currentUid) ...[
                  Icon(Icons.done_all, size: 16, color: theme.metaText),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    _previewText(last),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasUnread ? theme.incomingText : theme.metaText,
                    ),
                  ),
                ),
              ],
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (last?.timestamp != null)
            Text(
              ChatFormatters.relativeStamp(last!.timestamp!),
              style: TextStyle(
                fontSize: 12,
                color: hasUnread ? theme.primary : theme.metaText,
              ),
            ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (conversation.isMutedFor(currentUid)) ...[
                Icon(Icons.notifications_off, size: 16, color: theme.metaText),
                const SizedBox(width: 4),
              ],
              if (hasUnread)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.onlineColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(minWidth: 20),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const SizedBox(height: 18),
            ],
          ),
        ],
      ),
    );
  }

  String _previewText(LastMessagePreview last) {
    // `last.text` already holds the display preview (with a media emoji for
    // non-text messages). For group chats, prefix the sender's name.
    final prefix = conversation.isGroup && last.senderId != currentUid
        ? '${conversation.participantInfo[last.senderId]?.name ?? ''}: '
        : '';
    return '$prefix${last.text}';
  }
}
