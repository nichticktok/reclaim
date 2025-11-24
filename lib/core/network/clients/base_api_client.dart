import 'dart:convert';

import 'package:http/http.dart' as http;

import '../service_registry.dart';

class BaseApiClient {
  BaseApiClient(this._registry, this._serviceId, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final ServiceRegistry _registry;
  final ServiceId _serviceId;
  final http.Client _http;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final response = await _http.get(
      _buildUri(path, queryParameters),
      headers: _composeHeaders(headers),
    );
    _throwOnError(response);
    return _decode(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final response = await _http.post(
      _buildUri(path, null),
      headers: _composeHeaders({
        'Content-Type': 'application/json',
        ...?headers,
      }),
      body: body == null ? null : jsonEncode(body),
    );
    _throwOnError(response);
    return _decode(response);
  }

  Uri _buildUri(String path, Map<String, String>? queryParameters) {
    final endpoint = _registry.endpoint(_serviceId);
    return endpoint.baseUri.replace(
      path: '${endpoint.baseUri.path}$path',
      queryParameters: queryParameters,
    );
  }

  Map<String, String> _composeHeaders(Map<String, String>? headers) {
    final endpoint = _registry.endpoint(_serviceId);
    return {...endpoint.defaultHeaders, ...?headers};
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return const {};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return {'data': decoded};
  }

  void _throwOnError(http.Response response) {
    if (response.statusCode >= 400) {
      throw ApiException(
        response.statusCode,
        response.body.isNotEmpty ? response.body : 'Unknown error',
      );
    }
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
