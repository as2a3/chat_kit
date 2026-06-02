import 'dart:async';

import 'package:chat_kit/src/chat_kit_base.dart';
import 'package:chat_kit/src/controllers/chat_controller.dart';
import 'package:chat_kit/src/models/conversation.dart';
import 'package:chat_kit/src/repositories/media_repository.dart';
import 'package:chat_kit/src/ui/screens/chat_info_screen.dart';
import 'package:chat_kit/src/ui/theme/chat_theme.dart';
import 'package:chat_kit/src/ui/widgets/avatar.dart';
import 'package:chat_kit/src/ui/widgets/date_separator.dart';
import 'package:chat_kit/src/ui/widgets/message_bubble.dart';
import 'package:chat_kit/src/ui/widgets/message_input_bar.dart';
import 'package:chat_kit/src/ui/widgets/typing_indicator.dart';
import 'package:chat_kit/src/utils/formatters.dart';
import 'package:flutter/material.dart';

/// The message thread for one [Conversation]: header with presence/typing,
/// scrollable bubbles with date separators, and the input bar.
class ChatScreen extends StatefulWidget {
  /// Creates a chat screen for the given [conversation].
  const ChatScreen({required this.conversation, super.key});

  /// The conversation whose message thread is displayed.
  final Conversation conversation;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController _controller = ChatController(
    services: ChatKit.instance.services,
    conversation: widget.conversation,
  );

  @override
  void initState() {
    super.initState();
    // Suppress push notifications for the chat currently on screen.
    ChatKit.instance.setActiveChat(widget.conversation.id);
  }

  @override
  void dispose() {
    ChatKit.instance.setActiveChat(null);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleAttach(AttachmentKind kind) async {
    final media = ChatKit.instance.services.media;
    PickedMedia? picked;
    try {
      picked = switch (kind) {
        AttachmentKind.gallery => await media.pickImage(),
        AttachmentKind.camera => await media.pickImage(fromCamera: true),
        AttachmentKind.video => await media.pickVideo(),
        AttachmentKind.file => await media.pickFile(),
      };
    } on Object catch (e) {
      _showError('Could not pick file: $e');
      return;
    }
    if (picked == null) return;
    try {
      await _controller.sendMedia(picked);
    } on Object catch (e) {
      _showError('Upload failed: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChatKit.instance.config.theme;
    return ChatThemeProvider(
      theme: theme,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: _buildAppBar(theme),
        body: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  if (_controller.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _buildMessageList();
                },
              ),
            ),
            MessageInputBar(
              onSendText: (text) => _controller.sendText(text),
              onAttach: _handleAttach,
              onChanged: (_) => _controller.onUserTyping(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatTheme theme) {
    final convo = widget.conversation;
    final me = _controller.currentUid;
    return AppBar(
      backgroundColor: theme.appBarColor,
      foregroundColor: theme.appBarForeground,
      titleSpacing: 0,
      title: InkWell(
        onTap: _openInfo,
        child: Row(
          children: [
            Avatar(
              name: convo.titleFor(me),
              photoUrl: convo.avatarFor(me),
              isGroup: convo.isGroup,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    convo.titleFor(me),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17),
                  ),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final subtitle = _subtitle();
                      if (subtitle == null) return const SizedBox.shrink();
                      return Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.info_outline), onPressed: _openInfo),
      ],
    );
  }

  /// Header subtitle: "typing…" > online/last-seen (direct) > member count
  /// (group).
  String? _subtitle() {
    final convo = widget.conversation;
    if (_controller.someoneTyping) {
      if (convo.isGroup) {
        final names = _controller.typingUids
            .map((u) => convo.participantInfo[u]?.name ?? 'Someone')
            .join(', ');
        return '$names typing…';
      }
      return 'typing…';
    }
    if (convo.isGroup) {
      return '${convo.participants.length} members';
    }
    final presence = _controller.peerPresence;
    if (presence == null) return null;
    if (presence.online) return 'online';
    if (presence.lastSeen != null) {
      return ChatFormatters.lastSeen(presence.lastSeen!);
    }
    return null;
  }

  void _openInfo() {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatInfoScreen(conversation: widget.conversation),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    final messages = _controller.messages;
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Say hi 👋',
          style: TextStyle(color: ChatTheme.of(context).metaText),
        ),
      );
    }

    final convo = widget.conversation;
    final me = _controller.currentUid;

    // messages are newest-first; a reversed ListView renders them bottom-up.
    // Leading slot (index 0) hosts the typing indicator.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _controller.someoneTyping
              ? const TypingIndicator()
              : const SizedBox.shrink();
        }
        final i = index - 1;
        final message = messages[i];
        final isMine = message.senderId == me;

        // A date separator belongs *above* this message (i.e. visually before
        // it) when the next-older message is on a different day, or when this
        // is the oldest message.
        final older = i + 1 < messages.length ? messages[i + 1] : null;
        final showSeparator =
            message.timestamp != null &&
            (older?.timestamp == null ||
                ChatFormatters.isDifferentDay(
                  message.timestamp!,
                  older!.timestamp!,
                ));

        final bubble = MessageBubble(
          message: message,
          isMine: isMine,
          otherParticipants: convo.participants.where((u) => u != me),
          showSenderName: convo.isGroup,
          senderName: convo.participantInfo[message.senderId]?.name,
          uploadProgress: _controller.uploads[message.id],
        );

        if (!showSeparator) return bubble;
        return Column(
          children: [
            DateSeparator(
              label: ChatFormatters.daySeparator(message.timestamp!),
            ),
            bubble,
          ],
        );
      },
    );
  }
}
