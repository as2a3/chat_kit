import 'dart:async';

import 'package:chat_kit/src/chat_kit_base.dart';
import 'package:chat_kit/src/models/chat_user.dart';
import 'package:chat_kit/src/ui/screens/chat_screen.dart';
import 'package:chat_kit/src/ui/theme/chat_theme.dart';
import 'package:chat_kit/src/ui/widgets/avatar.dart';
import 'package:flutter/material.dart';

/// Two-step group creation: pick members, then name the group.
class GroupCreateScreen extends StatefulWidget {
  /// Creates the group-creation screen.
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  late Future<List<ChatUser>> _contactsFuture;
  final Set<ChatUser> _selected = {};
  final _nameController = TextEditingController();
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    final fetch = ChatKit.instance.config.fetchContacts;
    _contactsFuture = fetch?.call() ?? Future.value(const []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selected.isEmpty) return;
    setState(() => _creating = true);
    try {
      final services = ChatKit.instance.services;
      final creator = await services.auth.currentUser();
      final chatId = await services.chats.createGroup(
        creator: creator,
        members: _selected.toList(),
        name: name,
      );
      final convo = await services.chats.getConversation(chatId);
      if (!mounted || convo == null) return;
      unawaited(
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ChatScreen(conversation: convo),
          ),
        ),
      );
    } on Object catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not create group: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChatKit.instance.config.theme;
    final canCreate =
        _selected.isNotEmpty && _nameController.text.trim().isNotEmpty;
    return ChatThemeProvider(
      theme: theme,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.appBarColor,
          foregroundColor: theme.appBarForeground,
          title: const Text('New group'),
        ),
        floatingActionButton: canCreate
            ? FloatingActionButton(
                backgroundColor: theme.primary,
                onPressed: _creating ? null : _create,
                child: _creating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.check, color: Colors.white),
              )
            : null,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (_selected.isNotEmpty)
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: _selected
                      .map(
                        (u) => Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            children: [
                              Avatar(
                                name: u.name,
                                photoUrl: u.photoUrl,
                                radius: 22,
                              ),
                              SizedBox(
                                width: 56,
                                child: Text(
                                  u.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
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
                  final me = ChatKit.instance.services.auth.currentUid;
                  final contacts = (snapshot.data ?? const [])
                      .where((c) => c.id != me)
                      .toList();
                  return ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, i) {
                      final c = contacts[i];
                      final selected = _selected.contains(c);
                      return CheckboxListTile(
                        value: selected,
                        secondary: Avatar(
                          name: c.name,
                          photoUrl: c.photoUrl,
                          radius: 22,
                        ),
                        title: Text(c.name),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selected.add(c);
                          } else {
                            _selected.remove(c);
                          }
                        }),
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
