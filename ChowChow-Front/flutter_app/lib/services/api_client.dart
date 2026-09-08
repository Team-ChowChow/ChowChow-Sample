import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static const _serverUrl = 'http://35.78.87.150:8080';

  static String get _baseUrl {
    return _serverUrl;
  }
  static const _tokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // 401 받으면 refresh token으로 재발급 후 true 반환. 실패하면 false.
  static Future<bool> _tryRefresh() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final uri = Uri.parse('$_baseUrl/api/auth/refresh');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final newAccess = body['accessToken'] as String?;
        final newRefresh = body['refreshToken'] as String?;
        if (newAccess != null) await saveToken(newAccess);
        if (newRefresh != null) await saveRefreshToken(newRefresh);
        return newAccess != null;
      }
    } catch (_) {}
    return false;
  }

  static dynamic _parse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    String msg;
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      msg = body['message'] ?? body['error'] ?? res.reasonPhrase ?? 'Error';
    } catch (_) {
      msg = res.reasonPhrase ?? 'Error';
    }
    throw ApiException(res.statusCode, msg);
  }

  static const _timeout = Duration(seconds: 15);

  static Future<dynamic> get(String path, {bool auth = true, Map<String, String>? query}) async {
    var uri = Uri.parse('$_baseUrl$path');
    if (query != null) uri = uri.replace(queryParameters: query);
    var res = await http.get(uri, headers: await _headers(auth: auth)).timeout(_timeout);
    if (res.statusCode == 401 && auth) {
      if (await _tryRefresh()) {
        res = await http.get(uri, headers: await _headers(auth: auth)).timeout(_timeout);
      }
    }
    return _parse(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true, Duration? timeout}) async {
    final t = timeout ?? _timeout;
    final uri = Uri.parse('$_baseUrl$path');
    var res = await http.post(uri, headers: await _headers(auth: auth), body: jsonEncode(body)).timeout(t);
    if (res.statusCode == 401 && auth) {
      if (await _tryRefresh()) {
        res = await http.post(uri, headers: await _headers(auth: auth), body: jsonEncode(body)).timeout(t);
      }
    }
    return _parse(res);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final uri = Uri.parse('$_baseUrl$path');
    var res = await http.put(uri, headers: await _headers(auth: auth), body: jsonEncode(body)).timeout(_timeout);
    if (res.statusCode == 401 && auth) {
      if (await _tryRefresh()) {
        res = await http.put(uri, headers: await _headers(auth: auth), body: jsonEncode(body)).timeout(_timeout);
      }
    }
    return _parse(res);
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final uri = Uri.parse('$_baseUrl$path');
    var res = await http.patch(uri, headers: await _headers(auth: auth), body: jsonEncode(body)).timeout(_timeout);
    if (res.statusCode == 401 && auth) {
      if (await _tryRefresh()) {
        res = await http.patch(uri, headers: await _headers(auth: auth), body: jsonEncode(body)).timeout(_timeout);
      }
    }
    return _parse(res);
  }

  static Future<dynamic> delete(String path, {bool auth = true}) async {
    final uri = Uri.parse('$_baseUrl$path');
    var res = await http.delete(uri, headers: await _headers(auth: auth)).timeout(_timeout);
    if (res.statusCode == 401 && auth) {
      if (await _tryRefresh()) {
        res = await http.delete(uri, headers: await _headers(auth: auth)).timeout(_timeout);
      }
    }
    return _parse(res);
  }

  static Future<String> uploadImage(File file, {String type = 'recipe'}) async {
    final token = await getToken();
    final uri = Uri.parse('$_baseUrl/api/common/upload?type=$type');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    final contentType = MediaType.parse(_imageContentType(file.path));
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: contentType,
      ),
    );
    var streamed = await request.send();
    // 401 → refresh & retry once
    if (streamed.statusCode == 401) {
      if (await _tryRefresh()) {
        final newToken = await getToken();
        final retryReq = http.MultipartRequest('POST', uri);
        if (newToken != null) retryReq.headers['Authorization'] = 'Bearer $newToken';
        retryReq.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            contentType: contentType,
          ),
        );
        streamed = await retryReq.send();
      }
    }
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      return (jsonDecode(body) as Map<String, dynamic>)['url'] as String;
    }
    throw ApiException(streamed.statusCode, 'Upload failed: $body');
  }

  static Future<String> uploadImageBytes(
    Uint8List bytes, {
    required String filename,
    String type = 'recipe',
  }) async {
    final uri = Uri.parse('$_baseUrl/api/common/upload?type=$type');
    final contentType = MediaType.parse(
      _imageContentType(filename, bytes: bytes),
    );

    Future<http.StreamedResponse> send(String? token) async {
      final request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: contentType,
        ),
      );
      return request.send();
    }

    var streamed = await send(await getToken());
    if (streamed.statusCode == 401 && await _tryRefresh()) {
      streamed = await send(await getToken());
    }

    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      return (jsonDecode(body) as Map<String, dynamic>)['url'] as String;
    }
    throw ApiException(streamed.statusCode, 'Upload failed: $body');
  }

  static String _imageContentType(String filename, {Uint8List? bytes}) {
    if (bytes != null) {
      if (bytes.length >= 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'image/png';
      }
      if (bytes.length >= 3 &&
          bytes[0] == 0xFF &&
          bytes[1] == 0xD8 &&
          bytes[2] == 0xFF) {
        return 'image/jpeg';
      }
      if (bytes.length >= 6) {
        final signature = String.fromCharCodes(bytes.take(6));
        if (signature == 'GIF87a' || signature == 'GIF89a') {
          return 'image/gif';
        }
      }
      if (bytes.length >= 12 &&
          String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
          String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP') {
        return 'image/webp';
      }
    }

    final normalizedName = filename.toLowerCase();
    if (normalizedName.endsWith('.jpg') ||
        normalizedName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (normalizedName.endsWith('.gif')) return 'image/gif';
    if (normalizedName.endsWith('.webp')) return 'image/webp';
    return 'image/png';
  }
}
