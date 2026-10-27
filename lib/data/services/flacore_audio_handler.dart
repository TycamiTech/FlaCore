import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Explicit BaseAudioHandler implementation for FlaCore.
/// Manages MediaSession, media notification, lock screen controls,
/// and Bluetooth/headset media button events directly.
class FlaCoreAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer player = AudioPlayer();

  /// Callbacks wired by PlayerProvider for queue navigation from lock screen / notification
  VoidCallback? onSkipToNext;
  VoidCallback? onSkipToPrevious;

  FlaCoreAudioHandler() {
    // Broadcast playback state on every playback event change
    player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object e) {
        debugPrint('FlaCore playbackEventStream error: $e');
      },
    );

    // Re-broadcast when playing state toggles (play/pause from player)
    player.playingStream.listen((_) {
      _broadcastState(player.playbackEvent);
    });

    // Re-broadcast when processing state changes (loading, buffering, completed)
    player.processingStateStream.listen((_) {
      _broadcastState(player.playbackEvent);
    });
  }

  /// Maps just_audio ProcessingState to audio_service AudioProcessingState
  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  /// Broadcasts the current PlaybackState to the OS MediaSession.
  /// This is what drives the notification controls, lock screen, and Bluetooth AVRCP.
  void _broadcastState(PlaybackEvent event) {
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _mapProcessingState(player.processingState),
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  /// Explicitly pushes a MediaItem to the OS notification / lock screen.
  /// Called by PlayerProvider whenever the active track changes.
  Future<void> updateActiveMediaItem(MediaItem item) async {
    mediaItem.add(item);
    _broadcastState(player.playbackEvent);
  }

  // ===========================================================================
  // BaseAudioHandler overrides — these respond to OS / Lock Screen / Bluetooth
  // ===========================================================================

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (onSkipToNext != null) onSkipToNext!();
  }

  @override
  Future<void> skipToPrevious() async {
    if (onSkipToPrevious != null) onSkipToPrevious!();
  }
}
