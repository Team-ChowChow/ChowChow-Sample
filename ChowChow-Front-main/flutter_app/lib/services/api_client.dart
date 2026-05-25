import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // Android 에뮬레이터에서 호스트 머신 localhost는 10.0.2.2
  static const String baseUrl = 'http://10.0.2.2:8080';

  static const String _tokenKey = 'access_token';

  // ────────────── Token ──────────────

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ────────────── Headers ──────────────

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ────────────── HTTP methods ──────────────

  static const _defaultTimeout = Duration(seconds: 30);

  static Future<Map<String, dynamic>> get(
    String path, {
    bool auth = true,
    Duration timeout = _defaultTimeout,
  }) async {
    final res = await http
        .get(Uri.parse('$baseUrl$path'), headers: await _headers(auth: auth))
        .timeout(timeout);
    return _parse(res);
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
    Duration timeout = _defaultTimeout,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: await _headers(auth: auth),
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _parse(res);
  }

  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
    Duration timeout = _defaultTimeout,
  }) async {
    final res = await http
        .patch(
          Uri.parse('$baseUrl$path'),
          headers: await _headers(auth: auth),
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _parse(res);
  }

  static Future<Map<String, dynamic>> uploadFile(
    String path,
    String filePath, {
    String fieldName = 'file',
    bool auth = true,
  }) async {
    final token = auth ? await getToken() : null;
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final res = await http.Response.fromStream(streamed);
    return _parse(res);
  }

  static Future<void> delete(String path, {bool auth = true}) async {
    await http
        .delete(Uri.parse('$baseUrl$path'), headers: await _headers(auth: auth))
        .timeout(_defaultTimeout);
  }

  // ────────────── Response parser ──────────────

  static Map<String, dynamic> _parse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return {};
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    }
    throw ApiException(res.statusCode, res.body);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
