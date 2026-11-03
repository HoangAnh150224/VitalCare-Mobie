import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'session_store.dart';

/// A decoded answer: the JSON body plus the headers lists need.
class ApiResponse {
  const ApiResponse(this.status, this.body, this.headers);

  final int status;
  final Object? body;
  final Map<String, String> headers;

  /// `X-Total-Count`, which every list endpoint sends.
  int? get totalCount => int.tryParse(headers['x-total-count'] ?? '');
}

/// JSON over HTTP to the VitalCare API.
///
/// Sends `Authorization: Bearer <accessToken>` when a session exists. On a 401
/// it trades the refresh token for a new pair once — concurrent requests share
/// that one refresh, because the server burns a refresh token on use — and
/// retries the request. A refresh the server refuses ends the session and
/// calls [onSessionExpired].
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    SessionStore? store,
    String baseUrl = apiBaseUrl,
    this.timeout = apiTimeout,
  }) : _http = httpClient ?? http.Client(),
       store = store ?? SessionStore(),
       _baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl;

  final http.Client _http;
  final SessionStore store;
  final String _baseUrl;
  final Duration timeout;

  /// Called after a failed refresh has cleared the session.
  void Function()? onSessionExpired;

  Future<Session>? _refreshing;

  String get baseUrl => _baseUrl;

  Uri uri(String path, [Map<String, Object?>? query]) {
    final params = <String, String>{};
    query?.forEach((key, value) {
      if (value != null && '$value'.isNotEmpty) params[key] = '$value';
    });
    final full = Uri.parse('$_baseUrl$path');
    return params.isEmpty ? full : full.replace(queryParameters: params);
  }

  Future<Object?> get(String path, {Map<String, Object?>? query, bool auth = true}) async =>
      (await send('GET', path, query: query, auth: auth)).body;

  Future<Object?> post(String path, {Object? body, bool auth = true}) async =>
      (await send('POST', path, body: body, auth: auth)).body;

  Future<Object?> put(String path, {Object? body}) async =>
      (await send('PUT', path, body: body)).body;

  Future<Object?> delete(String path) async => (await send('DELETE', path)).body;

  /// One request; see the class comment for the 401 handling.
  Future<ApiResponse> send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    bool auth = true,
  }) async {
    final target = uri(path, query);
    final session = auth ? (store.current ?? await store.load()) : null;
    var response = await _raw(method, target, body, session?.accessToken);
    if (response.statusCode == 401 && session != null) {
      final renewed = await _refreshOnce(session);
      response = await _raw(method, target, body, renewed.accessToken);
    }
    return _decode(response);
  }

  /// Headers for loading a protected image with `Image.network`.
  Map<String, String> get authHeaders {
    final token = store.current?.accessToken;
    return token == null ? const {} : {'Authorization': 'Bearer $token'};
  }

  Future<http.Response> _raw(String method, Uri target, Object? body, String? token) async {
    final request = http.Request(method, target)
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    try {
      final streamed = await _http.send(request).timeout(timeout);
      return await http.Response.fromStream(streamed).timeout(timeout);
    } catch (_) {
      throw const ApiException.network();
    }
  }

  Future<Session> _refreshOnce(Session stale) {
    // Another request may already have renewed the pair this one was sent with.
    final current = store.current;
    if (current != null && current.accessToken != stale.accessToken) {
      return Future.value(current);
    }
    return _refreshing ??= _refresh(stale).whenComplete(() => _refreshing = null);
  }

  Future<Session> _refresh(Session stale) async {
    // An unreachable server throws a network error here and keeps the
    // session: the next call may work.
    final response = await _raw('POST', uri('/auth/refresh'), {
      'refreshToken': stale.refreshToken,
    }, null);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = _json(response);
      if (body is Map && body['accessToken'] is String && body['refreshToken'] is String) {
        final renewed = stale.copyWith(
          accessToken: body['accessToken'] as String,
          refreshToken: body['refreshToken'] as String,
        );
        await store.save(renewed);
        return renewed;
      }
    }
    if (response.statusCode >= 500) {
      throw ApiException.fromBody(response.statusCode, _json(response));
    }
    await store.clear();
    onSessionExpired?.call();
    throw const ApiException(ApiException.sessionExpiredMessage, status: 401);
  }

  ApiResponse _decode(http.Response response) {
    final body = _json(response);
    final headers = {
      for (final entry in response.headers.entries) entry.key.toLowerCase(): entry.value,
    };
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse(response.statusCode, body, headers);
    }
    throw ApiException.fromBody(response.statusCode, body);
  }

  Object? _json(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  void close() => _http.close();
}
