import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Single source of truth for the Firebase handles the package uses, so paths
/// and collection names live in one place.
///
/// Assumes the host app has already called `Firebase.initializeApp()`.
class FirebaseRefs {
  /// Creates the handles, defaulting each to its singleton instance.
  ///
  /// When [database] is omitted, the Realtime Database instance is resolved
  /// from [databaseUrl] if given — necessary when the RTDB lives outside the
  /// default region or isn't carried by the default Firebase options, where
  /// `FirebaseDatabase.instance` would otherwise have a null URL and every
  /// `ref(...)` would silently fail.
  FirebaseRefs({
    FirebaseFirestore? firestore,
    FirebaseDatabase? database,
    FirebaseStorage? storage,
    String? databaseUrl,
  }) : firestore = firestore ?? FirebaseFirestore.instance,
       database =
           database ??
           (databaseUrl != null
               ? FirebaseDatabase.instanceFor(
                   app: Firebase.app(),
                   databaseURL: databaseUrl,
                 )
               : FirebaseDatabase.instance),
       storage = storage ?? FirebaseStorage.instance;

  /// Firestore instance backing chats and messages.
  final FirebaseFirestore firestore;

  /// Realtime Database instance backing presence and typing.
  final FirebaseDatabase database;

  /// Storage instance backing chat media.
  final FirebaseStorage storage;

  // --- Firestore ---------------------------------------------------------

  /// The `chats` collection.
  CollectionReference<Map<String, dynamic>> get chats =>
      firestore.collection('chats');

  /// The chat document for [chatId].
  DocumentReference<Map<String, dynamic>> chat(String chatId) =>
      chats.doc(chatId);

  /// The `messages` subcollection of chat [chatId].
  CollectionReference<Map<String, dynamic>> messages(String chatId) =>
      chat(chatId).collection('messages');

  /// Per-user FCM registration tokens: `fcm_tokens/{uid}` with a `tokens`
  /// array. Read by the push Cloud Function, written by the client on login.
  DocumentReference<Map<String, dynamic>> fcmTokens(String uid) =>
      firestore.collection('fcm_tokens').doc(uid);

  // --- Realtime Database (presence + typing) -----------------------------

  /// Presence node for user [uid].
  DatabaseReference presence(String uid) => database.ref('presence/$uid');

  /// Typing node for chat [chatId] (all participants).
  DatabaseReference typing(String chatId) => database.ref('typing/$chatId');

  /// Typing node for user [uid] within chat [chatId].
  DatabaseReference typingFor(String chatId, String uid) =>
      database.ref('typing/$chatId/$uid');

  /// RTDB sentinel that flips to false on the server when the client
  /// disconnects — the backbone of presence.
  DatabaseReference get connectedInfo => database.ref('.info/connected');

  // --- Storage -----------------------------------------------------------

  /// Storage location for media [fileName] of message [messageId] in
  /// chat [chatId].
  Reference media(String chatId, String messageId, String fileName) =>
      storage.ref('chat_media/$chatId/$messageId/$fileName');
}
