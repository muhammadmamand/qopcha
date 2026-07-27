import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class ImageStorageService {
  static const _uuid = Uuid();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a picked local image to Firebase Storage and returns its download URL.
  Future<String> persistPickedImage(String sourcePath) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw Exception('وێنە نەدۆزرایەوە');
    }

    final ext = _extensionOf(sourcePath);
    final objectPath =
        'product_images/${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}$ext';
    final ref = _storage.ref().child(objectPath);

    final snapshot = await ref.putFile(
      file,
      SettableMetadata(contentType: _contentType(ext)),
    );
    return snapshot.ref.getDownloadURL();
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    if (ext.length > 5) return '.jpg';
    return ext;
  }

  String _contentType(String ext) {
    return switch (ext) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }
}
