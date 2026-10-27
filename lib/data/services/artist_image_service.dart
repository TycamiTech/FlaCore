import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for fetching artist profile pictures using Deezer Public API
/// with persistent local caching via SharedPreferences and fast in-memory cache.
class ArtistImageService {
  final http.Client _client;
  static const String _cachePrefix = 'artist_image_url_';

  // In-memory cache to avoid repeated disk reads during the same session
  static final Map<String, String> _memoryCache = {};
  static final Map<String, Future<String?>> _inFlightRequests = {};

  ArtistImageService({http.Client? client}) : _client = client ?? http.Client();

  /// Singleton instance for shared usage across UI widgets
  static final ArtistImageService instance = ArtistImageService();

  /// Clears in-memory cache, primarily for unit testing.
  @visibleForTesting
  static void clearMemoryCache() {
    _memoryCache.clear();
    _inFlightRequests.clear();
  }

  /// Fetches the official profile picture URL for [artistName].
  ///
  /// Checks local cache (`SharedPreferences` and memory) first.
  /// If not found in cache, sends a GET request to:
  /// `https://api.deezer.com/search/artist?q=${Uri.encodeComponent(artistName)}&limit=1`
  /// and extracts `picture_medium` (or `picture_big`) from the first data item.
  ///
  /// Caches the resulting URL in `SharedPreferences` and returns it.
  /// Wrapped with try-catch to return `null` on network errors, timeouts, or empty results.
  Future<String?> getArtistImageUrl(String artistName) async {
    final cleanName = artistName.trim();
    if (cleanName.isEmpty) return null;

    final cacheKey = '$_cachePrefix${cleanName.toLowerCase()}';

    // 1. Instant check in memory cache
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }

    // 2. Prevent duplicate parallel HTTP requests for the same artist
    if (_inFlightRequests.containsKey(cacheKey)) {
      return await _inFlightRequests[cacheKey];
    }

    final future = _fetchAndCache(cacheKey, cleanName);
    _inFlightRequests[cacheKey] = future;

    try {
      return await future;
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  Future<String?> _fetchAndCache(String cacheKey, String artistName) async {
    try {
      // 1. Check local SharedPreferences cache
      final prefs = await SharedPreferences.getInstance();
      final cachedUrl = prefs.getString(cacheKey);
      if (cachedUrl != null && cachedUrl.isNotEmpty) {
        _memoryCache[cacheKey] = cachedUrl;
        return cachedUrl;
      }

      // 2. Fetch from Deezer Public API
      final uri = Uri.parse(
        'https://api.deezer.com/search/artist?q=${Uri.encodeComponent(artistName)}&limit=1',
      );

      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          final data = decoded['data'] as List;
          if (data.isNotEmpty) {
            final firstArtist = data.first;
            if (firstArtist is Map<String, dynamic>) {
              final dynamic medium = firstArtist['picture_medium'];
              final dynamic big = firstArtist['picture_big'];
              final imageUrl = (medium ?? big) as String?;

              if (imageUrl != null && imageUrl.isNotEmpty) {
                // Save to local cache
                await prefs.setString(cacheKey, imageUrl);
                _memoryCache[cacheKey] = imageUrl;
                return imageUrl;
              }
            }
          }
        }
      }

      return null;
    } catch (_) {
      // Gracefully return null if offline, timeout, or parsing error occurs
      return null;
    }
  }

  /// Closes client resources when no longer needed.
  void dispose() {
    _client.close();
  }
}
