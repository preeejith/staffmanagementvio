import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AppException implements Exception {
  final String message;
  AppException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  final String? token;
  ApiService({this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final uri =
        Uri.parse('$apiBaseUrl$path').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    return _handle(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: _headers,
      body: jsonEncode(body ?? {}),
    );
    return _handle(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final response = await http.put(
      Uri.parse('$apiBaseUrl$path'),
      headers: _headers,
      body: jsonEncode(body ?? {}),
    );
    return _handle(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      Uri.parse('$apiBaseUrl$path'),
      headers: _headers,
      body: jsonEncode(body ?? {}),
    );
    return _handle(response);
  }

  dynamic _handle(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final msg = decoded['error'] ?? 'Request failed (${response.statusCode})';
    throw AppException(msg);
  }
}
