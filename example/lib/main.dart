import 'package:chat_kit/chat_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Minimal host app showing how to embed `chat_kit`.
///
/// Setup steps before running:
///  1. `flutter create .` inside this `example/` folder to generate platform
///     projects (android/, ios/, ...).
///  2. Add your Firebase config (`flutterfire configure`, or drop in
///     `google-services.json` / `GoogleService-Info.plist`).
///  3. Enable Anonymous sign-in (or your real provider) in the Firebase
///     console, plus Firestore, Realtime Database, and Storage.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ExampleApp());
}

/// Passed to both MaterialApp and ChatConfig so notification taps can navigate.
final navigatorKey = GlobalKey<NavigatorState>();

/// Root widget of the example host app.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'chat_kit example',
      navigatorKey: navigatorKey,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF075E54)),
      home: const _Gate(),
    );
  }
}

/// In a real app this is *your* login screen. Here we sign in anonymously, then
/// configure the chat package and hand off to [ConversationsScreen].
class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  late final Future<void> _ready = _bootstrap();

  Future<void> _bootstrap() async {
    // 1) Authenticate with Firebase Auth (your app does this its own way).
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    // 2) Configure the chat package once.
    ChatKit.configure(
      ChatConfig(
        theme: ChatTheme.whatsapp(),
        // Your app owns the user directory — wire these to it. The demo returns
        // a couple of placeholder contacts.
        fetchContacts: () async => const [
          ChatUser(id: 'demo-user-1', name: 'Alice'),
          ChatUser(id: 'demo-user-2', name: 'Bob'),
        ],
        resolveUser: (uid) async => ChatUser(id: uid, name: 'User $uid'),
        // Let the package open the tapped chat using the app's navigator.
        navigatorKey: navigatorKey,
      ),
    );

    // 3) Begin presence + push tracking after sign-in.
    await ChatKit.instance.startPresence();
    await ChatKit.instance.initPushNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Startup failed: ${snapshot.error}')),
          );
        }
        return const ConversationsScreen();
      },
    );
  }
}
