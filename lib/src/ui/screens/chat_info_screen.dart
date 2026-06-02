import 'package:chat_kit/src/chat_kit_base.dart';
import 'package:chat_kit/src/models/conversation.dart';
import 'package:chat_kit/src/ui/theme/chat_theme.dart';
import 'package:chat_kit/src/ui/widgets/avatar.dart';
import 'package:flutter/material.dart';

/// Conversation details: participants, and (for groups the user administers)
/// admin actions — rename, promote/demote, remove, and leave.
class ChatInfoScreen extends StatelessWidget {
  /// Creates the info screen for the given [conversation].
  const ChatInfoScreen({required this.conversation, super.key});

  /// The conversation whose details are displayed.
  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final theme = ChatKit.instance.config.theme;
    return ChatThemeProvider(
      theme: theme,
      child: StreamBuilder<Conversation>(
        // Live so admin actions reflect immediately.
        stream: ChatKit.instance.services.chats.watchConversation(
          conversation.id,
        ),
        initialData: conversation,
        builder: (context, snapshot) {
          final convo = snapshot.data ?? conversation;
          return _InfoBody(convo: convo, theme: theme);
        },
      ),
    );
  }
}

class _InfoBody extends StatelessWidget {
  const _InfoBody({required this.convo, required this.theme});

  final Conversation convo;
  final ChatTheme theme;

  @override
  Widget build(BuildContext context) {
    final services = ChatKit.instance.services;
    final me = services.auth.currentUid;
    final iAmAdmin = convo.isAdmin(me);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.appBarColor,
        foregroundColor: theme.appBarForeground,
        title: Text(convo.isGroup ? 'Group info' : 'Contact info'),
        actions: [
          if (convo.isGroup && iAmAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _rename(context),
            ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: Avatar(
              name: convo.titleFor(me),
              photoUrl: convo.avatarFor(me),
              isGroup: convo.isGroup,
              radius: 48,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              convo.titleFor(me),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            secondary: Icon(
              convo.isMutedFor(me)
                  ? Icons.notifications_off
                  : Icons.notifications,
              color: theme.primary,
            ),
            title: const Text('Mute notifications'),
            subtitle: Text(
              convo.isMutedFor(me)
                  ? "You won't get pushes for this chat"
                  : 'Notifications are on',
              style: TextStyle(color: theme.metaText, fontSize: 12),
            ),
            value: convo.isMutedFor(me),
            activeThumbColor: theme.primary,
            onChanged: (muted) => services.chats.setMuted(convo.id, me, muted),
          ),
          const Divider(height: 1),
          if (convo.isGroup) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${convo.participants.length} members',
                style: TextStyle(
                  color: theme.metaText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...convo.participants.map(
              (uid) => _memberTile(context, uid, me, iAmAdmin),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              title: const Text(
                'Leave group',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () => _leave(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _memberTile(
    BuildContext context,
    String uid,
    String me,
    bool iAmAdmin,
  ) {
    final services = ChatKit.instance.services;
    final user = convo.participantInfo[uid];
    final isThisAdmin = convo.isAdmin(uid);
    final isMe = uid == me;

    return ListTile(
      leading: Avatar(
        name: user?.name ?? uid,
        photoUrl: user?.photoUrl,
        radius: 22,
      ),
      title: Text(isMe ? 'You' : (user?.name ?? uid)),
      subtitle: isThisAdmin
          ? Text('Admin', style: TextStyle(color: theme.primary))
          : null,
      trailing: (iAmAdmin && !isMe)
          ? PopupMenuButton<String>(
              onSelected: (action) async {
                switch (action) {
                  case 'promote':
                    await services.chats.setAdmin(convo.id, uid, true);
                  case 'demote':
                    await services.chats.setAdmin(convo.id, uid, false);
                  case 'remove':
                    await services.chats.removeMember(convo.id, uid);
                }
              },
              itemBuilder: (_) => [
                if (!isThisAdmin)
                  const PopupMenuItem(
                    value: 'promote',
                    child: Text('Make admin'),
                  ),
                if (isThisAdmin)
                  const PopupMenuItem(
                    value: 'demote',
                    child: Text('Dismiss as admin'),
                  ),
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
            )
          : null,
    );
  }

  Future<void> _rename(BuildContext context) async {
    final controller = TextEditingController(text: convo.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename group'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ChatKit.instance.services.chats.renameGroup(convo.id, name);
    }
  }

  Future<void> _leave(BuildContext context) async {
    final services = ChatKit.instance.services;
    final me = services.auth.currentUid;
    final navigator = Navigator.of(context);
    await services.chats.leaveGroup(convo.id, me);
    // Pop back to the conversations list (info + chat screens).
    navigator
      ..pop()
      ..pop();
  }
}
