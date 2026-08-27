import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/api_config.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _tokenKey = 'qopcha_vps_token';
  String? _token;
  Future<void>? _loading;

  Future<void> _ensureLoaded() {
    return _loading ??= () async {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
    }();
  }

  Future<void> setToken(String? token) async {
    await _ensureLoaded();
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  Future<String?> get token async {
    await _ensureLoaded();
    return _token;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
  }

  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = _token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    }     on SocketException {
      throw Exception(
        'پەیوەندی سێرڤەر شکستی هێنا — دڵنیابەرەوە مۆبایل و کۆمپیوتەر لەسەر هەمان وایفاین و API کار دەکات (${ApiConfig.baseUrl})',
      );
    } on http.ClientException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('refused') ||
          msg.contains('failed host') ||
          msg.contains('connection')) {
        throw Exception(
          'پەیوەندی سێرڤەر شکستی هێنا — دڵنیابەرەوە مۆبایل و کۆمپیوتەر لەسەر هەمان وایفاین و API کار دەکات (${ApiConfig.baseUrl})',
        );
      }
      throw Exception(e.message);
    } on TimeoutException {
      throw Exception('کاتی پەیوەندی بەسەرچوو — دووبارە هەوڵ بدەرەوە');
    }
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    await _ensureLoaded();
    return _guard(() async {
      final res = await http.get(_uri(path, query), headers: _headers(json: false));
      return _decode(res);
    });
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic>? body,
  ) async {
    await _ensureLoaded();
    return _guard(() async {
      final res = await http.post(
        _uri(path),
        headers: _headers(),
        body: jsonEncode(body ?? const {}),
      );
      return _decode(res);
    });
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    await _ensureLoaded();
    return _guard(() async {
      final res = await http.patch(
        _uri(path),
        headers: _headers(),
        body: jsonEncode(body),
      );
      return _decode(res);
    });
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    await _ensureLoaded();
    return _guard(() async {
      final res = await http.put(
        _uri(path),
        headers: _headers(),
        body: jsonEncode(body),
      );
      return _decode(res);
    });
  }

  Future<void> delete(String path) async {
    await _ensureLoaded();
    await _guard(() async {
      final res = await http.delete(_uri(path), headers: _headers(json: false));
      _decode(res);
    });
  }

  Future<String> uploadBytes(Uint8List bytes, {String filename = 'image.jpg'}) async {
    await _ensureLoaded();
    return _guard(() async {
      final req = http.MultipartRequest('POST', _uri('/api/upload'));
      req.headers['Authorization'] = 'Bearer ${_token ?? ''}';
      req.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      final data = _decode(res);
      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('نەتوانرا وێنە هەڵبژێردرێت');
      }
      return url;
    });
  }

  Stream<T> poll<T>(Future<T> Function() fetch) async* {
    yield await fetch();
    yield* Stream.periodic(ApiConfig.pollInterval).asyncMap((_) => fetch());
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> data = const {};
    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {}
    }
    if (res.statusCode >= 400) {
      throw Exception(data['error'] as String? ?? 'هەڵەیەک ڕوویدا');
    }
    return data;
  }
}
