/// A drop-in, WhatsApp-style chat package backed by Firebase.
///
/// Assumes the host app has already initialized Firebase and signed the user in
/// with Firebase Auth. Configure once, then navigate to [ConversationsScreen]:
///
/// ```dart
/// ChatKit.configure(ChatConfig(
///   theme: ChatTheme.whatsapp(),
///   resolveUser: (uid) => myDirectory.user(uid),
///   fetchContacts: () => myDirectory.contacts(),
/// ));
/// await ChatKit.instance.startPresence();
/// Navigator.push(context,
///     MaterialPageRoute(builder: (_) => const ConversationsScreen()));
/// ```
library;

import 'package:chat_kit/src/ui/screens/conversations_screen.dart'
    show ConversationsScreen;

export 'src/chat_kit_base.dart';
export 'src/config/chat_config.dart';
export 'src/controllers/chat_controller.dart';
export 'src/controllers/conversation_list_controller.dart';
export 'src/models/chat_message.dart';
export 'src/models/chat_user.dart';
export 'src/models/conversation.dart';
export 'src/models/message_status.dart';
export 'src/models/message_type.dart';
export 'src/models/presence.dart';
export 'src/repositories/auth_repository.dart';
export 'src/repositories/chat_repository.dart';
export 'src/repositories/media_repository.dart';
export 'src/repositories/message_repository.dart';
export 'src/repositories/presence_repository.dart';
export 'src/repositories/push_repository.dart';
export 'src/repositories/typing_repository.dart';
export 'src/services/chat_services.dart';
export 'src/services/firebase_refs.dart';
export 'src/ui/screens/chat_info_screen.dart';
export 'src/ui/screens/chat_screen.dart';
export 'src/ui/screens/conversations_screen.dart';
export 'src/ui/screens/group_create_screen.dart';
export 'src/ui/screens/new_chat_screen.dart';
export 'src/ui/theme/chat_theme.dart';
