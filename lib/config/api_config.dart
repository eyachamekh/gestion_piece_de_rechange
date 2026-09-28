/// Backend base URL for API calls.
///
/// Set [API_BASE_URL] with --dart-define to use a different backend.
class ApiConfig {
  static const String _hostedBaseUrl =
      'https://gestionpiecederechange-production.up.railway.app';
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    final configuredUrl = _configuredBaseUrl.isNotEmpty
        ? _configuredBaseUrl
        : _hostedBaseUrl;
    return configuredUrl.replaceFirst(RegExp(r'/$'), '');
  }

  static String url(String path) {
    if (!path.startsWith('/')) path = '/$path';
    return '$baseUrl$path';
  }

  static String imageUrl(int partId, int slot) =>
      url('/api/parts/$partId/image/$slot');

  static bool hasImage(Map part, int slot) =>
      slot >= 1 &&
      slot <= 7 &&
      (part['has_image$slot'] == 1 || part['has_image$slot'] == true);

  static String uploadUrl(String filename) => url('/uploads/$filename');
}
