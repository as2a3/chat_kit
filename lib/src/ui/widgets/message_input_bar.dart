import 'package:chat_kit/src/ui/theme/chat_theme.dart';
import 'package:flutter/material.dart';

/// The attachment kinds offered by the input bar's "+" sheet.
enum AttachmentKind {
  /// Pick an existing photo from the gallery.
  gallery,

  /// Capture a new photo with the camera.
  camera,

  /// Capture or pick a video.
  video,

  /// Pick an arbitrary document/file.
  file,
}

/// Bottom input bar: text field with an attach button and a send button that
/// morphs based on whether there's text to send.
class MessageInputBar extends StatefulWidget {
  /// Creates the message input bar.
  const MessageInputBar({
    required this.onSendText,
    required this.onAttach,
    super.key,
    this.onChanged,
    this.enabled = true,
  });

  /// Called with the trimmed text when the user taps send.
  final ValueChanged<String> onSendText;

  /// Called when the user picks an attachment kind from the sheet.
  final ValueChanged<AttachmentKind> onAttach;

  /// Called on every text change (drives the typing indicator).
  final ValueChanged<String>? onChanged;

  /// Whether the bar accepts input; when false, send and attach are disabled.
  final bool enabled;

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
      widget.onChanged?.call(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _controller.clear();
  }

  Future<void> _openAttachSheet() async {
    final kind = await showModalBottomSheet<AttachmentKind>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            _attachTile(context, Icons.photo, 'Photo', AttachmentKind.gallery),
            _attachTile(
              context,
              Icons.camera_alt,
              'Camera',
              AttachmentKind.camera,
            ),
            _attachTile(context, Icons.videocam, 'Video', AttachmentKind.video),
            _attachTile(
              context,
              Icons.insert_drive_file,
              'Document',
              AttachmentKind.file,
            ),
          ],
        ),
      ),
    );
    if (kind != null) widget.onAttach(kind);
  }

  Widget _attachTile(
    BuildContext context,
    IconData icon,
    String label,
    AttachmentKind kind,
  ) {
    return ListTile(
      leading: Icon(icon, color: ChatTheme.of(context).primary),
      title: Text(label),
      onTap: () => Navigator.of(context).pop(kind),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: theme.inputBarColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.incomingBubble,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.attach_file, color: theme.metaText),
                      onPressed: widget.enabled ? _openAttachSheet : null,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: widget.enabled,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.primary,
              child: IconButton(
                icon: Icon(
                  _hasText ? Icons.send : Icons.mic,
                  color: Colors.white,
                ),
                onPressed: widget.enabled && _hasText ? _send : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
