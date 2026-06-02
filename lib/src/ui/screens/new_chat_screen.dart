import 'dart:async';

import 'package:chat_kit/src/chat_kit_base.dart';
import 'package:chat_kit/src/config/chat_config.dart' show ChatConfig;
import 'package:chat_kit/src/models/chat_user.dart';
import 'package:chat_kit/src/ui/screens/chat_screen.dart';
import 'package:chat_kit/src/ui/screens/group_create_screen.dart';
import 'package:chat_kit/src/ui/theme/chat_theme.dart';
import 'package:chat_kit/src/ui/widgets/avatar.dart';
import 'package:flutter/material.dart';

/// Pick a contact to start a 1-on-1 chat, or head into group creation.
/// Contacts come from [ChatConfig.fetchContacts].
class NewChatScreen extends StatefulWidget {
  /// Creates the new-chat screen.
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  late Future<List<ChatUser>> _contactsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final fetch = ChatKit.instance.config.fetchContacts;
    _contactsFuture = fetch?.call() ?? Future.value(const []);
  }

  Future<void> _startDirectChat(ChatUser other) async {
    final services = ChatKit.instance.services;
    final me = await services.auth.currentUser();
    final convo = await services.chats.openDirectChat(me: me, other: other);
    if (!mounted) return;
    // Replace this screen so back returns to the conversations list.
    unawaited(
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(conversation: convo),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChatKit.instance.config.theme;
    return ChatThemeProvider(
      theme: theme,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.appBarColor,
          foregroundColor: theme.appBarForeground,
          title: const Text('New chat'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search contacts',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.primary,
                child: const Icon(Icons.group_add, color: Colors.white),
              ),
              title: const Text('New group'),
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => const GroupCreateScreen(),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<ChatUser>>(
                future: _contactsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final me = ChatKit.instance.services.auth;
                  final contacts = (snapshot.data ?? const [])
                      .where((c) => c.id != me.currentUid)
                      .where((c) => c.name.toLowerCase().contains(_query))
                      .toList();
                  if (contacts.isEmpty) {
                    return const Center(child: Text('No contacts found.'));
                  }
                  return ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, i) {
                      final c = contacts[i];
                      return ListTile(
                        leading: Avatar(
                          name: c.name,
                          photoUrl: c.photoUrl,
                          radius: 22,
                        ),
                        title: Text(c.name),
                        subtitle: c.email != null ? Text(c.email!) : null,
                        onTap: () => _startDirectChat(c),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
