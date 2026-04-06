import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart' show kApiBaseUrl, kApiDefaultPort;
import '../models/article_category.dart';
import '../models/poi.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Express uses the same contract as the old PHP API: `/index.php?action=...`
  Uri _uri(String action, [Map<String, String>? query]) {
    final base = kApiBaseUrl.endsWith('/') ? kApiBaseUrl.substring(0, kApiBaseUrl.length - 1) : kApiBaseUrl;
    return Uri.parse('$base/index.php').replace(queryParameters: {
      'action': action,
      ...?query,
    });
  }

  Map<String, String> _headers({String? token}) {
    final h = <String, String>{'Content-Type': 'application/json; charset=utf-8'};
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Map<String, String> _multipartHeaders({String? token}) {
    final h = <String, String>{};
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    // Do NOT set Content-Type; the http library will set it automatically with boundary
    return h;
  }

  /// Full URL of the API base for error messages.
  String get _apiBaseUrl {
    final base = kApiBaseUrl.endsWith('/') ? kApiBaseUrl.substring(0, kApiBaseUrl.length - 1) : kApiBaseUrl;
    return base;
  }

  String _networkHelpMessage() {
    final base = kApiBaseUrl.endsWith('/') ? kApiBaseUrl.substring(0, kApiBaseUrl.length - 1) : kApiBaseUrl;
    final emuUrl = 'http://10.0.2.2:$kApiDefaultPort';
    final webUrl = 'http://localhost:$kApiDefaultPort';
    return 'Cannot reach the API at:\n$_apiBaseUrl\n\n'
        'Use the "server" folder only (not "backend").\n'
        '1) cd server\n'
        '   npm install\n'
        '   npm start\n'
        '2) In a browser open: $_apiBaseUrl/health\n'
        '   If that fails, the API is not running or PORT is wrong.\n'
        '   In server/.env set PORT=3001 (or change API_BASE_URL in Flutter).\n'
        '3) Import database/discover_jakarta.sql into MySQL.\n'
        '4) Android emulator: flutter run --dart-define=API_BASE_URL=$emuUrl\n'
        '5) Web (note two dashes): flutter run --dart-define=API_BASE_URL=$webUrl';
  }

  bool _looksLikeNetworkFailure(Object e) {
    final s = e.toString();
    return s.contains('Failed host lookup') ||
        s.contains('Connection refused') ||
        s.contains('Network is unreachable') ||
        s.contains('SocketException') ||
        s.contains('ClientException') ||
        s.contains('XMLHttpRequest error'); // Flutter web
  }

  Future<http.Response> _request(Future<http.Response> Function() send) async {
    try {
      return await send();
    } catch (e) {
      if (_looksLikeNetworkFailure(e)) {
        throw ApiException(_networkHelpMessage());
      }
      rethrow;
    }
  }

  Future<List<ArticleCategory>> fetchCategories() async {
    final res = await _request(() => _client.get(_uri('categories')));
    _throwIfBad(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>? ?? [];
    return list.map((e) => ArticleCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Poi>> fetchPois({
    required String locationSlug,
    String? categoryId,
    String searchQuery = '',
  }) async {
    final q = <String, String>{
      'location': locationSlug,
      if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
      if (searchQuery.trim().isNotEmpty) 'q': searchQuery.trim(),
    };
    final res = await _request(() => _client.get(_uri('pois', q)));
    _throwIfBad(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>? ?? [];
    return list.map((e) => Poi.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Poi> fetchPoi(int id) async {
    final res = await _request(() => _client.get(_uri('poi', {'id': id.toString()})));
    _throwIfBad(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return Poi.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<String> login(String username, String password) async {
    final res = await _request(
      () => _client.post(
        _uri('login'),
        headers: _headers(),
        body: jsonEncode({'username': username, 'password': password}),
      ),
    );
    if (res.statusCode == 401) {
      throw ApiException('Invalid credentials', 401);
    }
    _throwIfBad(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final token = body['token'] as String?;
    if (token == null || token.isEmpty) {
      throw ApiException('Invalid response');
    }
    return token;
  }

  Future<void> logout(String token) async {
    await _request(() => _client.post(_uri('logout'), headers: _headers(token: token)));
  }

  Future<http.MultipartFile> _multipartFileFromXFile(XFile file) async {
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final filename = file.name;
      final extension = filename.split('.').last.toLowerCase();
      final mimeType = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'application/octet-stream',
      };
      final parts = mimeType.split('/');
      return http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename,
        contentType: MediaType(parts[0], parts[1]),
      );
    }
    return await http.MultipartFile.fromPath('image', file.path);
  }

  Future<int> createPoi({
    required String token,
    required String locationSlug,
    required int categoryId,
    required String title,
    required String description,
    required String address,
    XFile? imageFile,
  }) async {
    final request = http.MultipartRequest('POST', _uri('poi'));
    request.headers.addAll(_multipartHeaders(token: token));
    request.fields['access_token'] = token;
    request.fields['location_slug'] = locationSlug;
    request.fields['category_id'] = categoryId.toString();
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['address'] = address;
    if (imageFile != null) {
      request.files.add(await _multipartFileFromXFile(imageFile));
    }
    try {
      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);
      _throwIfBad(res);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['id'] as num).toInt();
    } on ApiException {
      rethrow;
    } catch (e) {
      if (_looksLikeNetworkFailure(e)) {
        throw ApiException(_networkHelpMessage());
      }
      throw ApiException('Create failed: ${e.toString()}');
    }
  }

  Future<void> updatePoi({
    required String token,
    required int id,
    required int categoryId,
    required String title,
    required String description,
    required String address,
    XFile? imageFile,
  }) async {
    final request = http.MultipartRequest('POST', _uri('poi'));
    request.headers.addAll(_multipartHeaders(token: token));
    request.fields['access_token'] = token;
    request.fields['id'] = id.toString();
    request.fields['category_id'] = categoryId.toString();
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['address'] = address;
    if (imageFile != null) {
      request.files.add(await _multipartFileFromXFile(imageFile));
    }
    try {
      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);
      _throwIfBad(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      if (_looksLikeNetworkFailure(e)) {
        throw ApiException(_networkHelpMessage());
      }
      throw ApiException('Update failed: ${e.toString()}');
    }
  }

  Future<void> deletePoi({required String token, required int id}) async {
    final res = await _request(
      () => _client.delete(
        _uri('poi', {'id': id.toString()}),
        headers: _headers(token: token),
      ),
    );
    _throwIfBad(res);
  }

  void _throwIfBad(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        final err = decoded['error'] as String? ?? 'Request failed';
        throw ApiException(err, res.statusCode);
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      // Non-JSON body
    }
    throw ApiException('Request failed (${res.statusCode})', res.statusCode);
  }

  void dispose() {
    _client.close();
  }
}

/// Shared API client for the app.
final ApiService apiService = ApiService();
