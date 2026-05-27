import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static const _baseUrl = 'http://localhost:8080';
  static const _tokenKey = 'access_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
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

  static Future<dynamic> get(String path, {bool auth = true, Map<String, String>? query}) async {
    var uri = Uri.parse('$_baseUrl$path');
    if (query != null) uri = uri.replace(queryParameters: query);
    final res = await http.get(uri, headers: await _headers(auth: auth));
    return _parse(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http.post(uri, headers: await _headers(auth: auth), body: jsonEncode(body));
    return _parse(res);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http.put(uri, headers: await _headers(auth: auth), body: jsonEncode(body));
    return _parse(res);
  }

  static Future<dynamic> delete(String path, {bool auth = true}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http.delete(uri, headers: await _headers(auth: auth));
    return _parse(res);
  }
}