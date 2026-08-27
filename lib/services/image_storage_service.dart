import 'dart:io';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import 'api_client.dart';

class ImageStorageService {
  static const _uuid = Uuid();
  final _api = ApiClient.instance;

  Future<String> persistPickedImage(
    String sourcePath, {
    String folder = 'product_images',
  }) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw Exception('وێنە نەدۆزرایەوە');
    }
    final bytes = await file.readAsBytes();
    final ext = _extensionOf(sourcePath);
    return _api.uploadBytes(
      bytes,
      filename: '${folder}_${_uuid.v4()}$ext',
    );
  }

  Future<String> persistImageBytes(
    Uint8List bytes, {
    String folder = 'banner_images',
    String ext = '.jpg',
  }) async {
    return _api.uploadBytes(
      bytes,
      filename: '${folder}_${_uuid.v4()}$ext',
    );
  }

  Future<String> persistXFilePathOrBytes({
    String? path,
    Uint8List? bytes,
    String folder = 'product_images',
  }) async {
    if (bytes != null) {
      return persistImageBytes(bytes, folder: folder);
    }
    if (path != null && path.isNotEmpty) {
      return persistPickedImage(path, folder: folder);
    }
    throw Exception('وێنە نەدۆزرایەوە');
  }

  String _extensionOf(String path) {
    final i = path.lastIndexOf('.');
    if (i < 0) return '.jpg';
    final ext = path.substring(i).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.webp', '.gif'].contains(ext)) return ext;
    return '.jpg';
  }
}
