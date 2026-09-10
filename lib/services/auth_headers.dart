Map<String, String> makeAuthHeaders(String token, {bool json = false}) {
  final headers = <String, String>{'Authorization': 'Bearer $token'};
  if (json) headers['Content-Type'] = 'application/json';
  return headers;
}
