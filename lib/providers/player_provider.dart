import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants/api_constants.dart';
import '../data/models/song_model.dart';
import '../data/services/flacore_audio_handler.dart';
import '../data/services/lyrics_service.dart';

/// Provider responsible for audio playback engine, queue management, lyrics sync, and background controls.
class PlayerProvider extends ChangeNotifier {
  final FlaCoreAudioHandler _audioHandler;
  final AudioPlayer _player;
  final LyricsService _lyricsService;
  final List<StreamSubscription> _subscriptions = [];

  Song? _currentSong;
  List<Song> _playlist = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isBuffering = false;

  // Synced Lyrics state
  List<LyricLine>? _currentLyrics;
  int _currentLyricIndex = -1;
  bool _showLyrics = false;
  bool _isLoadingLyrics = false;
  String? _lyricsSongId;

  // Current MediaItem pushed to the OS notification
  MediaItem? _activeMediaItem;

  PlayerProvider({
    FlaCoreAudioHandler? audioHandler,
    LyricsService? lyricsService,
  }) : this._internal(
          audioHandler ?? FlaCoreAudioHandler(),
          lyricsService,
        );

  PlayerProvider._internal(
    FlaCoreAudioHandler handler,
    LyricsService? lyricsService,
  )   : _audioHandler = handler,
        _player = handler.player,
        _lyricsService = lyricsService ?? LyricsService() {
    // Wire lock screen / notification skip callbacks back to this provider
    _audioHandler.onSkipToNext = () => next();
    _audioHandler.onSkipToPrevious = () => previous();
    _initStreams();
  }

  // ===========================================================================
  // Getters
  // ===========================================================================

  /// Currently loaded or active song
  Song? get currentSong => _currentSong;

  /// Current queue / playlist
  List<Song> get playlist => List.unmodifiable(_playlist);

  /// Current song index in playlist
  int get currentIndex => _currentIndex;

  /// Playback playing state
  bool get isPlaying => _isPlaying;

  /// Current playback position
  Duration get position => _position;

  /// Total duration of currently active track
  Duration get duration => _duration;

  /// Buffering / loading state
  bool get isBuffering => _isBuffering;

  /// Convenience check whether an active song is loaded
  bool get hasCurrentSong => _currentSong != null;

  /// Whether there is a next track in queue
  bool get hasNext =>
      _currentIndex >= 0 && _currentIndex < _playlist.length - 1;

  /// Whether there is a previous track in queue
  bool get hasPrevious => _currentIndex > 0;

  /// Synced lyrics for the current track
  List<LyricLine>? get currentLyrics => _currentLyrics;

  /// Currently active lyric line index (-1 if none or before first lyric)
  int get currentLyricIndex => _currentLyricIndex;

  /// Whether lyrics view is toggled on
  bool get showLyrics => _showLyrics;

  /// Whether lyrics are actively being fetched from LRCLIB
  bool get isLoadingLyrics => _isLoadingLyrics;

  /// Toggles between Vinyl Turntable deck and Lyrics view
  void toggleLyricsView() {
    _showLyrics = !_showLyrics;
    notifyListeners();
  }

  /// Sets lyrics view explicitly
  void setLyricsView(bool show) {
    if (_showLyrics != show) {
      _showLyrics = show;
      notifyListeners();
    }
  }

  /// Normalized playback progress [0.0 - 1.0]
  double get progress {
    if (_duration.inMilliseconds <= 0) return 0.0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  // ===========================================================================
  // Streams Initialization
  // ===========================================================================

  int _lastNotifiedSecond = -1;

  void _initStreams() {
    // Listen to position changes and synchronize active lyric line
    _subscriptions.add(
      _player.positionStream.listen((pos) {
        _position = pos;
        final lyricChanged = _syncLyricIndex(pos);
        final currentSecond = pos.inSeconds;
        final secondChanged = currentSecond != _lastNotifiedSecond;
        if (secondChanged) {
          _lastNotifiedSecond = currentSecond;
        }

        // Only notify when second changes or when active lyric line changes.
        // This stops high-frequency 50-200ms rebuild loops across the app.
        if (lyricChanged || secondChanged) {
          notifyListeners();
        }
      }),
    );

    // Listen to duration updates — also update MediaItem duration in notification seekbar
    _subscriptions.add(
      _player.durationStream.listen((dur) {
        _duration = dur ?? Duration.zero;

        // Update notification seekbar with actual stream duration
        if (dur != null && _activeMediaItem != null) {
          final currentDur = _activeMediaItem!.duration;
          if (currentDur == null || currentDur == Duration.zero) {
            _activeMediaItem = _activeMediaItem!.copyWith(duration: dur);
            _audioHandler.updateActiveMediaItem(_activeMediaItem!);
          }
        }

        notifyListeners();
      }),
    );

    // Listen to player state (playing and buffering)
    _subscriptions.add(
      _player.playerStateStream.listen((state) {
        _isPlaying = state.playing;
        _isBuffering = state.processingState == ProcessingState.buffering ||
            state.processingState == ProcessingState.loading;
        notifyListeners();
      }),
    );

    // Listen to processing state to handle track completion
    _subscriptions.add(
      _player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          // Auto-advance to next track, or stop at end of queue
          if (hasNext) {
            next();
          } else {
            _player.pause();
            _player.seek(Duration.zero);
          }
        }
      }),
    );
  }

  /// Synchronizes active lyric line with the given [pos]. Returns true if active index changed.
  bool _syncLyricIndex(Duration pos) {
    final lyrics = _currentLyrics;
    if (lyrics == null || lyrics.isEmpty) {
      if (_currentLyricIndex != -1) {
        _currentLyricIndex = -1;
        return true;
      }
      return false;
    }

    int matchedIndex = -1;
    for (int i = 0; i < lyrics.length; i++) {
      if (pos >= lyrics[i].timestamp) {
        matchedIndex = i;
      } else {
        break; // Chronologically sorted
      }
    }

    if (matchedIndex != _currentLyricIndex) {
      _currentLyricIndex = matchedIndex;
      return true;
    }
    return false;
  }

  /// Background lyrics fetcher via LRCLIB with concurrency guard.
  Future<void> _fetchLyricsForSong(Song song) async {
    final songId = song.id;
    try {
      final lyrics = await _lyricsService.fetchLyrics(
        song.title,
        song.artist,
        duration: song.duration > 0 ? song.duration : null,
      );

      // Verify current song hasn't changed while network request was active
      if (_lyricsSongId == songId) {
        _currentLyrics = lyrics;
        _isLoadingLyrics = false;
        _syncLyricIndex(_position);
        notifyListeners();
      }
    } catch (_) {
      if (_lyricsSongId == songId) {
        _currentLyrics = null;
        _isLoadingLyrics = false;
        notifyListeners();
      }
    }
  }

  // ===========================================================================
  // Playback Controls
  // ===========================================================================

  /// Builds a MediaItem for the OS notification / lock screen from a Song model.
  MediaItem _buildMediaItem(Song song) {
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist.isNotEmpty ? song.artist : 'Unknown Artist',
      album: song.album.isNotEmpty ? song.album : 'FlaCore Lossless',
      duration: song.duration > 0 ? Duration(seconds: song.duration) : null,
      artUri: song.hasCover ? Uri.tryParse(ApiConstants.coverUrl(song.id)) : null,
    );
  }

  /// Loads and plays a [song].
  /// If a [queue] is provided, replaces current playlist with [queue].
  Future<void> playSong(Song song, {List<Song>? queue}) async {
    // Ensure POST_NOTIFICATIONS is requested on Android 13+ before playback starts
    try {
      final notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted) {
        await Permission.notification.request();
      }
    } catch (_) {}

    if (queue != null) {
      _playlist = List<Song>.from(queue);
      _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
      if (_currentIndex == -1) {
        _playlist.insert(0, song);
        _currentIndex = 0;
      }
    } else {
      if (_playlist.isEmpty) {
        _playlist = [song];
        _currentIndex = 0;
      } else {
        final idx = _playlist.indexWhere((s) => s.id == song.id);
        if (idx != -1) {
          _currentIndex = idx;
        } else {
          _playlist.add(song);
          _currentIndex = _playlist.length - 1;
        }
      }
    }

    _currentSong = song;
    _position = Duration.zero;
    _lastNotifiedSecond = -1;

    // Reset lyrics state and trigger background fetch from LRCLIB
    _currentLyrics = null;
    _currentLyricIndex = -1;
    _isLoadingLyrics = true;
    _lyricsSongId = song.id;
    notifyListeners();

    _fetchLyricsForSong(song);

    // Build and push MediaItem to OS notification BEFORE loading audio source
    _activeMediaItem = _buildMediaItem(song);
    await _audioHandler.updateActiveMediaItem(_activeMediaItem!);

    try {
      final audioSource = AudioSource.uri(
        Uri.parse(ApiConstants.streamUrl(song.id)),
      );
      await _player.setAudioSource(audioSource);

      // Re-push MediaItem after source is loaded (ensures notification is visible)
      await _audioHandler.updateActiveMediaItem(_activeMediaItem!);

      await _player.play();
    } catch (e) {
      debugPrint('FlaCore AudioPlayer Error: $e');
    }
  }

  /// Toggles between play and pause.
  Future<void> togglePlayPause() async {
    if (_currentSong == null) {
      if (_playlist.isNotEmpty) {
        await playSong(_playlist.first);
      }
      return;
    }

    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  /// Pauses playback.
  Future<void> pause() async {
    await _player.pause();
  }

  /// Resumes playback.
  Future<void> play() async {
    await _player.play();
  }

  /// Seeks to a specific [pos] in track.
  Future<void> seek(Duration pos) async {
    _position = pos;
    _syncLyricIndex(pos);
    notifyListeners();
    await _player.seek(pos);
  }

  /// Skips to the next song in the playlist.
  Future<void> next() async {
    if (_currentIndex + 1 < _playlist.length) {
      await playSong(_playlist[_currentIndex + 1]);
    }
  }

  /// Skips to the previous song, or restarts the track if past 3 seconds.
  Future<void> previous() async {
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (_currentIndex - 1 >= 0) {
      await playSong(_playlist[_currentIndex - 1]);
    } else {
      await seek(Duration.zero);
    }
  }

  /// Stops playback and resets active track state.
  Future<void> stop() async {
    await _player.stop();
    _currentSong = null;
    _activeMediaItem = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _isPlaying = false;
    _lastNotifiedSecond = -1;
    _currentLyrics = null;
    _currentLyricIndex = -1;
    _isLoadingLyrics = false;
    _lyricsSongId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _player.dispose();
    super.dispose();
  }
}
