/// Utility formatters for duration and audio specifications.
class Formatters {
  Formatters._();

  /// Formats duration in seconds into `mm:ss` format.
  /// Example: 75 -> "01:15", 305 -> "05:05"
  static String formatDuration(int seconds) {
    if (seconds < 0) seconds = 0;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  /// Formats audio bit-depth and sample rate into human-readable lossless quality label.
  ///
  /// Returns:
  /// - "Hi-Res Lossless • $bitDepth-bit / ${(sampleRate / 1000).toStringAsFixed(1)} kHz" if bitDepth >= 24 or sampleRate > 44100
  /// - "Lossless CD • $bitDepth-bit / ${(sampleRate / 1000).toStringAsFixed(1)} kHz" otherwise
  static String formatAudioQuality(int bitDepth, int sampleRate) {
    final sampleRateKHz = (sampleRate / 1000).toStringAsFixed(1);
    if (bitDepth >= 24 || sampleRate > 44100) {
      return 'Hi-Res Lossless • $bitDepth-bit / $sampleRateKHz kHz';
    } else {
      return 'Lossless CD • $bitDepth-bit / $sampleRateKHz kHz';
    }
  }

  static String audioQualityBadge(int bitDepth, int sampleRate) =>
      formatAudioQuality(bitDepth, sampleRate);
}

// Top-level helper functions for convenient access
String formatDuration(int seconds) => Formatters.formatDuration(seconds);

String formatAudioQuality(int bitDepth, int sampleRate) =>
    Formatters.formatAudioQuality(bitDepth, sampleRate);

String audioQualityBadge(int bitDepth, int sampleRate) =>
    Formatters.audioQualityBadge(bitDepth, sampleRate);
