import 'dart:convert';

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
