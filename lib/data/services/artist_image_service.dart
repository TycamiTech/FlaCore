import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for fetching artist profile pictures using Deezer Public API
/// with exact normalized string matching and fan count prioritization,
/// persistent local caching via SharedPreferences, and fast in-memory cache.
class ArtistImageService {
  final http.Client _client;
  static const String _cachePrefix = 'artist_img_v4_';

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

  /// Helper to normalize artist names by removing spaces, dashes, underscores, and dots,
  /// as well as converting to lowercase.
  static String _cleanName(String str) {
    return str
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-_\.]+'), '')
        .trim();
  }

  /// Fetches the official profile picture URL for [artistName].
  ///
  /// Checks local cache (`SharedPreferences` and memory) first using `artist_img_v4_${targetClean}`.
  /// If not found in cache, sends a GET request to:
  /// `https://api.deezer.com/search/artist?q=${Uri.encodeComponent(artistName.trim())}&limit=15`
  ///
  /// Selection Logic:
  /// 1. Cleans target name: `_cleanName(artistName)`.
  /// 2. Filters `data` strictly for candidates where `_cleanName(candidate['name']) == targetClean`.
  /// 3. If exact matches exist: sorts them by `nb_fan` descending and takes the top candidate.
  /// 4. If no exact match exists: falls back to sorting all candidates by `nb_fan` descending.
  /// 5. Extracts `picture_big` (fallback to `picture_medium`).
  ///
  /// Caches the resulting URL in `SharedPreferences` and returns it.
  /// Wrapped with try-catch to return `null` on network errors, timeouts, or empty results.
  Future<String?> getArtistImageUrl(String artistName) async {
    final targetClean = _cleanName(artistName);
    if (targetClean.isEmpty) return null;

    final cacheKey = '$_cachePrefix$targetClean';

    // 1. Instant check in memory cache
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }

    // 2. Prevent duplicate parallel HTTP requests for the same artist
    if (_inFlightRequests.containsKey(cacheKey)) {
      return await _inFlightRequests[cacheKey];
    }

    final future = _fetchAndCache(cacheKey, artistName.trim(), targetClean);
    _inFlightRequests[cacheKey] = future;

    try {
      return await future;
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  Future<String?> _fetchAndCache(
    String cacheKey,
    String queryArtistName,
    String targetClean,
  ) async {
    try {
      // 1. Check local SharedPreferences cache
      final prefs = await SharedPreferences.getInstance();
      final cachedUrl = prefs.getString(cacheKey);
      if (cachedUrl != null && cachedUrl.isNotEmpty) {
        _memoryCache[cacheKey] = cachedUrl;
        return cachedUrl;
      }

      // 2. Fetch up to 15 results from Deezer Public API
      final uri = Uri.parse(
        'https://api.deezer.com/search/artist?q=${Uri.encodeComponent(queryArtistName)}&limit=15',
      );

      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final dynamic decoded = jsonDecode(decodedBody);
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          final rawList = decoded['data'] as List;
          final candidates = rawList.whereType<Map<String, dynamic>>().toList();

          if (candidates.isNotEmpty) {
            // Filter strictly for exact normalized matches (NO .contains())
            final exactCandidates = candidates.where((candidate) {
              final candidateClean =
                  _cleanName(candidate['name']?.toString() ?? '');
              return candidateClean == targetClean;
            }).toList();

            final Map<String, dynamic> selectedCandidate;

            if (exactCandidates.isNotEmpty) {
              // Sort exact matches by number of fans (nb_fan) descending
              exactCandidates.sort((a, b) {
                final fansA = (a['nb_fan'] as num?)?.toInt() ?? 0;
                final fansB = (b['nb_fan'] as num?)?.toInt() ?? 0;
                return fansB.compareTo(fansA);
              });
              selectedCandidate = exactCandidates.first;
            } else {
              // If no exact match exists, fall back to sorting all candidates by nb_fan descending
              candidates.sort((a, b) {
                final fansA = (a['nb_fan'] as num?)?.toInt() ?? 0;
                final fansB = (b['nb_fan'] as num?)?.toInt() ?? 0;
                return fansB.compareTo(fansA);
              });
              selectedCandidate = candidates.first;
            }

            final dynamic big = selectedCandidate['picture_big'];
            final dynamic medium = selectedCandidate['picture_medium'];
            final imageUrl = (big ?? medium) as String?;

            if (imageUrl != null && imageUrl.isNotEmpty) {
              // Save to local cache
              await prefs.setString(cacheKey, imageUrl);
              _memoryCache[cacheKey] = imageUrl;
              return imageUrl;
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
