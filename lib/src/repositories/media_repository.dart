import 'dart:io';

import 'package:chat_kit/src/config/chat_config.dart';
import 'package:chat_kit/src/models/chat_message.dart' show ChatMessage;
import 'package:chat_kit/src/models/message_type.dart';
import 'package:chat_kit/src/services/firebase_refs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// The result of picking + uploading a piece of media, ready to be attached to
/// a [ChatMessage].
class UploadedMedia {
  /// Creates an [UploadedMedia] describing a successfully uploaded file.
  const UploadedMedia({
    required this.url,
    required this.type,
    required this.fileName,
    required this.fileSize,
    this.contentType,
  });

  /// The public download URL of the uploaded file.
  final String url;

  /// The kind of media this file represents.
  final MessageType type;

  /// The original file name.
  final String fileName;

  /// The uploaded file's size in bytes.
  final int fileSize;

  /// The detected MIME content type, if known.
  final String? contentType;
}

/// A locally-picked file before upload, so callers can show an optimistic
/// preview while the upload runs.
class PickedMedia {
  /// Creates a [PickedMedia] wrapping a locally-picked [file].
  const PickedMedia({
    required this.file,
    required this.type,
    required this.fileName,
  });

  /// The local file that was picked.
  final File file;

  /// The kind of media this file represents.
  final MessageType type;

  /// The picked file's name.
  final String fileName;

  /// The picked file's size in bytes.
  int get sizeBytes => file.lengthSync();
}

/// Picks media from the device and uploads it to Firebase Storage under
/// `chat_media/{chatId}/{messageId}/{fileName}`.
class MediaRepository {
  /// Creates a [MediaRepository] from the given Firebase [refs] and [config].
  MediaRepository({required this.refs, required this.config});

  /// Typed Firebase references used to store uploaded media.
  final FirebaseRefs refs;

  /// The chat configuration (e.g. the maximum allowed media size).
  final ChatConfig config;
  final ImagePicker _imagePicker = ImagePicker();

  /// Picks an image from the camera ([fromCamera] = true) or gallery.
  Future<PickedMedia?> pickImage({bool fromCamera = false}) async {
    final picked = await _imagePicker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return null;
    return PickedMedia(
      file: File(picked.path),
      type: MessageType.image,
      fileName: picked.name,
    );
  }

  /// Picks a video from the camera ([fromCamera] = true) or gallery.
  Future<PickedMedia?> pickVideo({bool fromCamera = false}) async {
    final picked = await _imagePicker.pickVideo(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (picked == null) return null;
    return PickedMedia(
      file: File(picked.path),
      type: MessageType.video,
      fileName: picked.name,
    );
  }

  /// Picks an arbitrary file from the device's file browser.
  Future<PickedMedia?> pickFile() async {
    final result = await FilePicker.pickFiles();
    final path = result?.files.single.path;
    if (path == null) return null;
    return PickedMedia(
      file: File(path),
      type: MessageType.file,
      fileName: result!.files.single.name,
    );
  }

  /// Uploads [media] for [messageId] in [chatId]. Throws
  /// [MediaTooLargeException] when the file exceeds
  /// [ChatConfig.maxMediaBytes]. [onProgress] reports 0.0–1.0 as bytes
  /// transfer.
  Future<UploadedMedia> upload({
    required String chatId,
    required String messageId,
    required PickedMedia media,
    void Function(double progress)? onProgress,
  }) async {
    final size = media.sizeBytes;
    if (size > config.maxMediaBytes) {
      throw MediaTooLargeException(size, config.maxMediaBytes);
    }

    final ref = refs.media(chatId, messageId, media.fileName);
    final task = ref.putFile(media.file);
    if (onProgress != null) {
      task.snapshotEvents.listen((s) {
        if (s.totalBytes > 0) {
          onProgress(s.bytesTransferred / s.totalBytes);
        }
      });
    }
    final snapshot = await task;
    final url = await snapshot.ref.getDownloadURL();
    return UploadedMedia(
      url: url,
      type: media.type,
      fileName: media.fileName,
      fileSize: size,
      contentType: snapshot.metadata?.contentType,
    );
  }
}

/// Thrown when a picked file is larger than the configured limit.
class MediaTooLargeException implements Exception {
  /// Creates a [MediaTooLargeException] for an [actualBytes] file that exceeds
  /// the allowed [limitBytes].
  const MediaTooLargeException(this.actualBytes, this.limitBytes);

  /// The size of the rejected file, in bytes.
  final int actualBytes;

  /// The configured maximum allowed size, in bytes.
  final int limitBytes;

  @override
  String toString() =>
      'MediaTooLargeException: $actualBytes bytes exceeds limit $limitBytes';
}
