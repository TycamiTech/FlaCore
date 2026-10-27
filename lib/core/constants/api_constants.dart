/// FlaCore API Constants and URL helper endpoints.
class ApiConstants {
  ApiConstants._();

  /// Base server URL for FlaCore API.
  ///
  /// ⚠️ PENTING / IMPORTANT:
  /// Ganti nilai ini dengan URL domain atau IP server FlaCore Anda sendiri.
  /// Contoh:
  /// - Domain Publik: 'https://flacore.yourdomain.com'
  /// - IP Jaringan Lokal: 'http://192.168.1.100:3000'
  ///
  /// Catatan:
  /// - JANGAN tambahkan tanda garis miring (trailing slash '/') di akhir URL.
  /// - Bisa juga ditentukan saat build menggunakan argumen:
  ///   `--dart-define=FLACORE_BASE_URL=https://your-server.com`
  static const String baseUrl = String.fromEnvironment(
    'FLACORE_BASE_URL',
    defaultValue: 'https://your-flacore-server.example.com',
  );

  /// Endpoint to fetch all songs
  static const String songsEndpoint = '$baseUrl/api/songs';

  /// Endpoint to trigger library scan
  static const String scanEndpoint = '$baseUrl/api/scan';

  /// Generates the direct audio streaming URL for a specific song [id]
  static String streamUrl(String id) => '$baseUrl/api/stream/$id';

  /// Generates the album cover art URL for a specific song [id]
  static String coverUrl(String id) => '$baseUrl/api/songs/$id/cover';
}

// Top-level aliases for direct imports if preferred
const String baseUrl = ApiConstants.baseUrl;
const String songsEndpoint = ApiConstants.songsEndpoint;
const String scanEndpoint = ApiConstants.scanEndpoint;
String streamUrl(String id) => ApiConstants.streamUrl(id);
String coverUrl(String id) => ApiConstants.coverUrl(id);
