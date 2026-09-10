import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:gestion_piece_de_rechange/config/api_config.dart';

Map<String, String> authHeaders(String token, {bool json = false}) {
  final headers = <String, String>{'Authorization': 'Bearer $token'};
  if (json) {
    headers['Content-Type'] = 'application/json';
  }
  return headers;
}

Future<List> fetchParts(String token) async {
  final res = await http.get(
    Uri.parse(ApiConfig.url('/api/parts')),
    headers: authHeaders(token),
  );
  if (res.statusCode == 200) return jsonDecode(res.body);
  throw Exception('Failed to load parts: ${res.statusCode}');
}

Future<Map<String, dynamic>> login(String email, String password) async {
  final res = await http.post(
    Uri.parse(ApiConfig.url('/api/login')),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  return jsonDecode(res.body) as Map<String, dynamic>;
}

/// Search parts by reference using the backend GET /api/parts/search-reference?reference=...
/// Returns a map { 'exact': bool, 'results': [partObjects] }
Future<Map<String, dynamic>> searchPartsByReference(
  String token,
  String reference,
) async {
  final uri = Uri.parse(
    ApiConfig.url(
      '/api/parts/search-reference?reference=${Uri.encodeComponent(reference)}',
    ),
  );
  debugPrint('========== DATABASE MATCH ==========');
  debugPrint('Database query: GET ${uri.path}?${uri.query}');
  debugPrint('OCR candidate: $reference');
  final res = await http.get(uri, headers: authHeaders(token));
  if (res.statusCode == 200) {
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final results = decoded['results'] as List? ?? const [];
    debugPrint(
      'Database results: ${results.length} '
      'matchType=${decoded['exact'] == true ? 'EXACT_REFERENCE' : results.isEmpty ? 'NO_REFERENCE_MATCH' : 'NORMALIZED_REFERENCE'}',
    );
    for (final result in results) {
      if (result is Map) {
        debugPrint(
          'ID: ${result['id']} Reference: ${result['reference']} '
          'Name: ${result['piece'] ?? result['name'] ?? ''}',
        );
      }
    }
    debugPrint('====================================');
    return decoded;
  }
  throw Exception('Reference search failed: ${res.statusCode}');
}
