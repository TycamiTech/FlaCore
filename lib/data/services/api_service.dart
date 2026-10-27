import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/song_model.dart';

/// Service responsible for communicating with FlaCore backend endpoints.
class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches the catalog of songs from `GET /api/songs`.
  /// Decodes body with UTF-8 to preserve non-ASCII characters (e.g. Korean / Japanese titles).
  Future<List<Song>> fetchSongs() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConstants.songsEndpoint),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final dynamic data = jsonDecode(decodedBody);

        if (data is List) {
          return data
              .map((item) => Song.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (data is Map<String, dynamic> && data['songs'] is List) {
          return (data['songs'] as List)
              .map((item) => Song.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw const FormatException('Unexpected response format from songs API');
        }
      } else {
        throw HttpException(
          'Server returned status ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      // Re-throw or format descriptive error for caller
      rethrow;
    }
  }

  /// Triggers music directory scan on the server via `POST /api/scan`.
  /// Returns `true` if scan was successfully initiated.
  Future<bool> triggerScan() async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConstants.scanEndpoint),
        headers: {
          'Accept': 'application/json',
        },
      );

      return response.statusCode == 200 || response.statusCode == 202;
    } catch (e) {
      return false;
    }
  }

  /// Closes client resources when no longer needed.
  void dispose() {
    _client.close();
  }
}
