import '../../core/constants/api_constants.dart';
import '../../core/utils/formatters.dart';

/// Represents a lossless audio track in the FlaCore catalog.
class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final int duration;
  final int bitDepth;
  final int sampleRate;
  final int bitrate;
  final String filePath;
  final bool hasCover;
  final DateTime? createdAt;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.bitDepth,
    required this.sampleRate,
    required this.bitrate,
    required this.filePath,
    required this.hasCover,
    this.createdAt,
  });

  /// Factory constructor to parse JSON data from backend.
  /// Example JSON:
  /// {
  ///   "id": "...",
  ///   "title": "...",
  ///   "artist": "IVE, Saweetie",
  ///   "album": "...",
  ///   "duration": 198,
  ///   "bit_depth": 24,
  ///   "sample_rate": 96000,
  ///   "bitrate": 3154,
  ///   "file_path": "...",
  ///   "has_cover": true,
  ///   "created_at": "..."
  /// }
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown Title',
      artist: json['artist'] as String? ?? 'Unknown Artist',
      album: json['album'] as String? ?? 'Unknown Album',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      bitDepth: (json['bit_depth'] as num?)?.toInt() ?? 16,
      sampleRate: (json['sample_rate'] as num?)?.toInt() ?? 44100,
      bitrate: (json['bitrate'] as num?)?.toInt() ?? 0,
      filePath: json['file_path'] as String? ?? '',
      hasCover: json['has_cover'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Converts this Song instance to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'bit_depth': bitDepth,
      'sample_rate': sampleRate,
      'bitrate': bitrate,
      'file_path': filePath,
      'has_cover': hasCover,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Splits collaboration artists by comma `, ` so each artist can be indexed cleanly.
  /// Example: "IVE, Saweetie" -> ["IVE", "Saweetie"]
  List<String> get artistList {
    if (artist.trim().isEmpty) return const ['Unknown Artist'];
    final artists = artist
        .split(RegExp(r',\s*'))
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
    return artists.isEmpty ? const ['Unknown Artist'] : artists;
  }

  /// Checks if track is Hi-Res Lossless (bit depth >= 24 or sample rate > 44.1kHz).
  bool get isHiRes => bitDepth >= 24 || sampleRate > 44100;

  /// Direct streaming endpoint URL for this song.
  String get streamUrl => ApiConstants.streamUrl(id);

  /// Direct cover art endpoint URL for this song.
  String get coverUrl => ApiConstants.coverUrl(id);

  /// Formatted duration string (mm:ss).
  String get formattedDuration => Formatters.formatDuration(duration);

  /// Formatted audio quality badge text (e.g. "Hi-Res Lossless • 24-bit / 96.0 kHz").
  String get audioQualityLabel =>
      Formatters.formatAudioQuality(bitDepth, sampleRate);

  /// Creates a copy of this Song with specified fields replaced.
  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    int? duration,
    int? bitDepth,
    int? sampleRate,
    int? bitrate,
    String? filePath,
    bool? hasCover,
    DateTime? createdAt,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      bitDepth: bitDepth ?? this.bitDepth,
      sampleRate: sampleRate ?? this.sampleRate,
      bitrate: bitrate ?? this.bitrate,
      filePath: filePath ?? this.filePath,
      hasCover: hasCover ?? this.hasCover,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Song(id: $id, title: $title, artist: $artist, album: $album, bitDepth: $bitDepth, sampleRate: $sampleRate)';
  }
}
