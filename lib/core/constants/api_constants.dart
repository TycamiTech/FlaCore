/// FlaCore API Constants and URL helper endpoints.
class ApiConstants {
  ApiConstants._();

  /// Default fallback server URL (empty on fresh install)
  static const String defaultBaseUrl = '';

  /// Active base server URL for FlaCore API
  static String _baseUrl = defaultBaseUrl;

  /// Whether the user has actively configured a custom server URL
  static bool isCustomConfigured = false;

  /// Gets the currently active base server URL
  static String get baseUrl => _baseUrl;

  /// Sets the active base server URL dynamically.
  /// Automatically strips trailing slashes and ensures standard protocol (http:// or https://).
  static void setBaseUrl(String url) {
    var cleanUrl = url.trim();
    while (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }
    _baseUrl = cleanUrl;
    isCustomConfigured = true;
  }

  /// Endpoint to fetch all songs
  static String get songsEndpoint => '$_baseUrl/api/songs';

  /// Endpoint to trigger library scan
  static String get scanEndpoint => '$_baseUrl/api/scan';

  /// Generates the direct audio streaming URL for a specific song [id]
  static String streamUrl(String id) => '$_baseUrl/api/stream/$id';

  /// Generates the album cover art URL for a specific song [id]
  static String coverUrl(String id) => '$_baseUrl/api/songs/$id/cover';
}

// Top-level aliases for direct imports if preferred
String get baseUrl => ApiConstants.baseUrl;
String get songsEndpoint => ApiConstants.songsEndpoint;
String get scanEndpoint => ApiConstants.scanEndpoint;
String streamUrl(String id) => ApiConstants.streamUrl(id);
String coverUrl(String id) => ApiConstants.coverUrl(id);
