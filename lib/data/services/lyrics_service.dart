import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Represents a single synchronized lyric line with timestamp and text.
class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine({
    required this.timestamp,
    required this.text,
  });

  @override
  String toString() => '[${timestamp.inMilliseconds}ms] $text';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricLine &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          text == other.text;

  @override
  int get hashCode => timestamp.hashCode ^ text.hashCode;
}

/// Service responsible for fetching real-time synced lyrics from LRCLIB API.
class LyricsService {
  final http.Client _client;

  LyricsService({http.Client? client}) : _client = client ?? http.Client();

  /// Cleans track titles to maximize API match rates.
  /// Removes parentheses/brackets like (feat. ...), [Remix], and suffixes after dashes.
  static String sanitizeTitle(String title) {
    var cleaned = title;

    // 1. Remove parenthesized/bracketed content: (feat. ...), [Live], (Remix), etc.
    cleaned = cleaned.replaceAll(RegExp(r'\s*[\(\[][^\)\]]*[\)\]]'), '');

    // 2. Remove album/version suffixes after dashes: " - The 3rd Mini Album", " - Remastered"
    final dashMatch = RegExp(r'\s+[-–—]\s+.*$').firstMatch(cleaned);
    if (dashMatch != null) {
      cleaned = cleaned.substring(0, dashMatch.start);
    }

    // 3. Trim extra spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isNotEmpty ? cleaned : title.trim();
  }

  /// Cleans artist names, taking the primary artist before commas or feature tags.
  static String sanitizeArtist(String artist) {
    var cleaned = artist;

    // 1. Take first artist before comma (e.g. "IVE, Saweetie" -> "IVE")
    if (cleaned.contains(',')) {
      cleaned = cleaned.split(',').first;
    }

    // 2. Remove feat/ft tags
    if (cleaned.toLowerCase().contains(' feat. ')) {
      cleaned = cleaned.split(RegExp(r'\s+feat\.\s+', caseSensitive: false)).first;
    }
    if (cleaned.toLowerCase().contains(' ft. ')) {
      cleaned = cleaned.split(RegExp(r'\s+ft\.\s+', caseSensitive: false)).first;
    }

    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isNotEmpty ? cleaned : artist.trim();
  }

  /// Parses standard .lrc format lyrics text into a chronological list of [LyricLine].
  /// Handles formats like [mm:ss.xx] and [mm:ss.xxx].
  static List<LyricLine> parseLrc(String lrcContent) {
    final lines = <LyricLine>[];
    final timestampRegex = RegExp(r'\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]');

    for (final rawLine in lrcContent.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final matches = timestampRegex.allMatches(line).toList();
      if (matches.isEmpty) continue;

      // Extract text after all timestamp tags
      final text = line.replaceAll(timestampRegex, '').trim();

      for (final match in matches) {
        final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
        final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
        final fractionStr = match.group(3);

        int milliseconds = 0;
        if (fractionStr != null) {
          if (fractionStr.length == 1) {
            milliseconds = (int.tryParse(fractionStr) ?? 0) * 100;
          } else if (fractionStr.length == 2) {
            milliseconds = (int.tryParse(fractionStr) ?? 0) * 10;
          } else {
            milliseconds = int.tryParse(fractionStr.padRight(3, '0').substring(0, 3)) ?? 0;
          }
        }

        final timestamp = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );

        lines.add(LyricLine(timestamp: timestamp, text: text));
      }
    }

    // Sort chronologically by timestamp
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }

  /// Fetches synchronized lyrics from LRCLIB API.
  /// Returns null if status != 200, syncedLyrics is empty, or on timeout/exception.
  Future<List<LyricLine>?> fetchLyrics(
    String title,
    String artist, {
    int? duration,
  }) async {
    final cleanTitle = sanitizeTitle(title);
    final cleanArtist = sanitizeArtist(artist);
    if (cleanTitle.isEmpty || cleanArtist.isEmpty) return null;

    final queryParams = <String, String>{
      'track_name': cleanTitle,
      'artist_name': cleanArtist,
    };
    if (duration != null && duration > 0) {
      queryParams['duration'] = duration.toString();
    }

    try {
      final uri = Uri.https('lrclib.net', '/api/get', queryParams);
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'FlaCore-App/1.0 (https://github.com/flacore)',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic>) {
          final syncedLyrics = data['syncedLyrics'] as String?;
          if (syncedLyrics != null && syncedLyrics.trim().isNotEmpty) {
            final parsed = parseLrc(syncedLyrics);
            if (parsed.isNotEmpty) {
              return parsed;
            }
          }
        }
      }
      return null;
    } catch (_) {
      // Passive error handling: never throw, return null
      return null;
    }
  }
}
