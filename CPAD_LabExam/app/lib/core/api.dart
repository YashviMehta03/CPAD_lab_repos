import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef Json = Map<String, dynamic>;

class ApiException implements Exception {
  ApiException(this.status, this.message);
  final int status;
  final String message;
  @override
  String toString() => message;
}

/// Thin client for the CampusSphere API. Every request carries the JWT; the backend enforces roles.
class Api {
  Api._();
  static final Api I = Api._();

  /// 10.0.2.2 is the host machine as seen from the Android emulator.
  static const defaultBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:4000/api');

  String baseUrl = defaultBaseUrl;
  String? token;
  void Function()? onUnauthorized;

  Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString('api_url') ?? defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_url', baseUrl);
  }

  /// Photo URLs can be absolute (Supabase signed URL) or relative to the server (local dev storage).
  String absolute(String url) =>
      url.startsWith('http') ? url : baseUrl.replaceFirst(RegExp(r'/api$'), '') + url;

  Map<String, String> get _headers => {
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.toString().isNotEmpty) q[k] = v.toString();
    });
    return Uri.parse('$baseUrl$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  Future<Json> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => http.get(_uri(path, query), headers: _headers));
  Future<Json> post(String path, [Object? body]) =>
      _send(() => http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));
  Future<Json> put(String path, [Object? body]) =>
      _send(() => http.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));
  Future<Json> delete(String path) => _send(() => http.delete(_uri(path), headers: _headers));

  Future<Json> multipart(String path, Map<String, String> fields,
      {List<int>? fileBytes, String? fileName, String fileField = 'photo'}) {
    return _send(() async {
      final req = http.MultipartRequest('POST', _uri(path))..fields.addAll(fields);
      if (token != null) req.headers['authorization'] = 'Bearer $token';
      if (fileBytes != null) {
        final ext = (fileName ?? 'photo.jpg').split('.').last.toLowerCase();
        final sub = ext == 'png' ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');
        req.files.add(http.MultipartFile.fromBytes(fileField, fileBytes,
            filename: fileName ?? 'photo.jpg', contentType: MediaType('image', sub)));
      }
      return http.Response.fromStream(await req.send());
    });
  }

  Future<Json> _send(Future<http.Response> Function() fn) async {
    http.Response res;
    try {
      res = await fn().timeout(const Duration(seconds: 20));
    } catch (_) {
      throw ApiException(0, 'Cannot reach the server at $baseUrl. Is the backend running?');
    }
    Json body;
    try {
      body = res.body.isEmpty ? {} : (jsonDecode(res.body) as Json);
    } catch (_) {
      body = {};
    }
    if (res.statusCode == 401 && token != null) onUnauthorized?.call();
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, body['error']?.toString() ?? 'Request failed (${res.statusCode})');
    }
    return body;
  }
}
