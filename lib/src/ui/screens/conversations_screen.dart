import 'dart:async';

import 'package:chat_kit/src/chat_kit_base.dart';
import 'package:chat_kit/src/controllers/conversation_list_controller.dart';
import 'package:chat_kit/src/models/conversation.dart';
import 'package:chat_kit/src/ui/screens/chat_screen.dart';
import 'package:chat_kit/src/ui/screens/new_chat_screen.dart';
import 'package:chat_kit/src/ui/theme/chat_theme.dart';
import 'package:chat_kit/src/ui/widgets/conversation_tile.dart';
import 'package:flutter/material.dart';

/// The drop-in home screen: the signed-in user's list of conversations.
/// This is the only screen the host app needs to navigate to.
class ConversationsScreen extends StatefulWidget {
  /// Creates the conversations home screen with an optional app bar [title].
  const ConversationsScreen({super.key, this.title = 'Chats'});

  /// Title shown in the app bar.
  final String title;

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late final ConversationListController _controller =
      ConversationListController(ChatKit.instance.services);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openChat(Conversation conversation) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(conversation: conversation),
        ),
      ),
    );
  }

  /// Long-press action sheet: mute/unmute, mark as read, and delete.
  Future<void> _showActions(Conversation conversation) async {
    final me = _controller.currentUid;
    final chats = _controller.services.chats;
    final muted = conversation.isMutedFor(me);
    final hasUnread = conversation.unreadFor(me) > 0;

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            if (hasUnread)
              ListTile(
                leading: const Icon(Icons.mark_chat_read),
                title: const Text('Mark as read'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(chats.markConversationRead(conversation.id, me));
                },
              ),
            ListTile(
              leading: Icon(
                muted ? Icons.notifications_active : Icons.notifications_off,
              ),
              title: Text(
                muted ? 'Unmute notifications' : 'Mute notifications',
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(chats.setMuted(conversation.id, me, !muted));
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Delete chat',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(_confirmDelete(conversation));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Conversation conversation) async {
    final me = _controller.currentUid;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete chat?'),
        content: Text(
          'This removes "${conversation.titleFor(me)}" from your list. '
          'It reappears if a new message arrives.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _controller.services.chats.deleteChatForUser(conversation.id, me);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChatKit.instance.config.theme;
    return ChatThemeProvider(
      theme: theme,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          backgroundColor: theme.appBarColor,
          foregroundColor: theme.appBarForeground,
          title: Text(widget.title),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: theme.primary,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const NewChatScreen()),
          ),
          child: const Icon(Icons.chat, color: Colors.white),
        ),
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_controller.error != null) {
              return _ErrorView(error: _controller.error!);
            }
            final items = _controller.conversations;
            if (items.isEmpty) return const _EmptyView();
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 84),
              itemBuilder: (context, i) {
                final c = items[i];
                return ConversationTile(
                  conversation: c,
                  currentUid: _controller.currentUid,
                  onTap: () => _openChat(c),
                  onLongPress: () => _showActions(c),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: theme.metaText),
          const SizedBox(height: 12),
          Text(
            'No conversations yet.\nTap the button to start chatting.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.metaText),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text('Could not load chats.\n$error', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
