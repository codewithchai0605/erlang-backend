import 'package:dio/dio.dart';

/// Error from the HTTP API (JSON endpoints only; chat traffic uses the WebSocket).
class ApiException implements Exception {
  const ApiException({required this.code, required this.message, this.status});
  final String code; // e.g. unauthenticated, conflict, invalid_argument, network
  final String message;
  final int? status;

  bool get isNetwork => code == 'network';

  factory ApiException.from(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      return ApiException(
        code: '${err['code']}',
        message: '${err['message']}',
        status: e.response?.statusCode,
      );
    }
    if (e.response != null) {
      return ApiException(code: 'http_error', message: 'Unexpected server response', status: e.response!.statusCode);
    }
    return const ApiException(code: 'network', message: 'Cannot reach the server. Check your connection.');
  }

  @override
  String toString() => 'ApiException($code, $message)';
}

class PublicUser {
  const PublicUser({required this.id, required this.username, required this.displayName});
  final String id;
  final String username;
  final String displayName;

  factory PublicUser.fromJson(Map<String, dynamic> j) =>
      PublicUser(id: j['id'] as String, username: j['username'] as String, displayName: j['display_name'] as String);
}

typedef TokenProvider = Future<String?> Function();
typedef RefreshCallback = Future<bool> Function();

/// Authenticated JSON client: attaches the access token and, on a 401, refreshes once and retries.
class ApiClient {
  ApiClient({required this._dio, required TokenProvider tokenProvider, required RefreshCallback refresh}) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenProvider();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) async {
        final retried = e.requestOptions.extra['retried'] == true;
        if (e.response?.statusCode == 401 && !retried && await refresh()) {
          e.requestOptions.extra['retried'] = true;
          try {
            handler.resolve(await _dio.fetch<dynamic>(e.requestOptions));
            return;
          } on DioException catch (e2) {
            handler.next(e2);
            return;
          }
        }
        handler.next(e);
      },
    ));
  }

  final Dio _dio;

  Future<PublicUser> lookupUser(String username) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/api/v1/users/lookup', queryParameters: {'username': username});
      return PublicUser.fromJson(r.data!['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('/api/v1/auth/logout');
    } on DioException {
      // best effort: local sign-out proceeds regardless
    }
  }
}

Dio newDio(String baseUrl) => Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ));
