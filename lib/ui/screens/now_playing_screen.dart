import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/song_model.dart';
import '../../providers/player_provider.dart';

/// Now Playing Screen with Vinyl Turntable deck, interactive waveform seekbar,
/// minimalist lossless audio quality badge, and Neumorphic playback controls in a curved dock.
class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _vinylController;

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
  }

  @override
  void dispose() {
    _vinylController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;

    if (song == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.music_off_rounded,
                size: 48,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 12),
              const Text('No track loaded'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Sync turntable rotation with player playback state
    if (player.isPlaying) {
      if (!_vinylController.isAnimating) {
        _vinylController.repeat();
      }
    } else {
      if (_vinylController.isAnimating) {
        _vinylController.stop();
      }
    }

    final durationSeconds = player.duration.inSeconds > 0
        ? player.duration.inSeconds
        : (song.duration > 0 ? song.duration : 1);
    final positionSeconds = player.position.inSeconds.clamp(0, durationSeconds);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 10.0),
          child: Column(
            children: [
              // 1. Top Minimalist AppBar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NeumorphicIconButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    size: 44,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Column(
                    children: [
                      Text(
                        'NOW PLAYING',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2.2,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.album.isNotEmpty ? song.album : 'FlaCore Hi-Res Deck',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(width: 44, height: 44),
                ],
              ),

              const Spacer(flex: 2),

              // 2. Vinyl Turntable Deck Widget or Synced Lyrics View (AnimatedSwitcher)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: player.showLyrics
                    ? _LyricsDeck(
                        key: const ValueKey('lyrics_deck'),
                        song: song,
                      )
                    : GestureDetector(
                        key: const ValueKey('turntable_deck'),
                        onTap: () => player.toggleLyricsView(),
                        behavior: HitTestBehavior.opaque,
                        child: _VinylTurntableDeck(
                          song: song,
                          rotationAnimation: _vinylController,
                          isPlaying: player.isPlaying,
                        ),
                      ),
              ),

              const Spacer(flex: 2),

              // 3. Song Information: Title & Artist
              Column(
                children: [
                  Text(
                    song.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.6,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    song.artist,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 4. Audio Waveform (monochrome soft gray) & Seekbar
              _WaveformSeekbar(
                currentSeconds: positionSeconds,
                totalSeconds: durationSeconds,
                onSeek: (seconds) {
                  player.seek(Duration(seconds: seconds));
                },
              ),

              const SizedBox(height: 8),

              // Digital minimalist duration text 0:32 / 2:48
              Text(
                '${formatDuration(positionSeconds)} / ${formatDuration(durationSeconds)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: Color(0xFF7E8695),
                ),
              ),

              const SizedBox(height: 12),

              // 5. Ultra-minimalist Gray Lossless Badge Capsule & Lyrics Toggle Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LosslessBadgeCapsule(song: song),
                  const SizedBox(width: 10),
                  _NeumorphicLyricsButton(
                    isActive: player.showLyrics,
                    onTap: () => player.toggleLyricsView(),
                  ),
                ],
              ),

              const Spacer(flex: 2),

              // 6. Bottom Neumorphic Playback Controls inside a Curved Capsule Dock
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: AppTheme.neumorphicConvex(
                  borderRadius: 48,
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Previous Button
                    _NeumorphicIconButton(
                      icon: Icons.skip_previous_rounded,
                      size: 52,
                      iconSize: 26,
                      onTap: () => player.previous(),
                    ),

                    const SizedBox(width: 24),

                    // Large Circular Neumorphic White Play/Pause Button
                    GestureDetector(
                      onTap: () => player.togglePlayPause(),
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: AppTheme.neumorphicConvex(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Icon(
                            player.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 38,
                            color: const Color(0xFF1C1F26),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Next Button
                    _NeumorphicIconButton(
                      icon: Icons.skip_next_rounded,
                      size: 52,
                      iconSize: 26,
                      onTap: () => player.next(),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    ),
  );
}
}

/// The Vinyl Turntable deck featuring a raised Neumorphic white box, rotating grooved vinyl record,
/// and a tonearm needle ornament.
class _VinylTurntableDeck extends StatelessWidget {
  final Song song;
  final Animation<double> rotationAnimation;
  final bool isPlaying;

  const _VinylTurntableDeck({
    required this.song,
    required this.rotationAnimation,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deckSize = (screenWidth * 0.78).clamp(260.0, 310.0);
    final vinylSize = deckSize * 0.76;

    return Center(
      child: Container(
        width: deckSize,
        height: deckSize,
        decoration: AppTheme.neumorphicConvex(
          borderRadius: 28,
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Platter recessed bed
            Container(
              width: vinylSize + 14,
              height: vinylSize + 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEFF1F5),
                border: Border.all(
                  color: const Color(0x33CED4DE),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F7A859E),
                    offset: Offset(1.5, 1.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),

            // The Vinyl Record (Spins with RotationTransition, isolated with RepaintBoundary)
            RepaintBoundary(
              child: RotationTransition(
                turns: rotationAnimation,
                child: Container(
                width: vinylSize,
                height: vinylSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF1E222B),
                      Color(0xFF11141A),
                      Color(0xFF1A1D24),
                      Color(0xFF0D0F14),
                    ],
                    stops: [0.35, 0.65, 0.85, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40000000),
                      offset: Offset(0, 6),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Vinyl Grooves (Thin concentric circles)
                    ..._buildGrooveRings(vinylSize),

                    // Center Album Cover Label
                    Container(
                      width: vinylSize * 0.42,
                      height: vinylSize * 0.42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0x55FFFFFF),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: song.hasCover
                            ? CachedNetworkImage(
                                imageUrl: song.coverUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 250,
                                memCacheHeight: 250,
                                placeholder: (context, url) => Container(
                                  color: const Color(0xFFE2E6EF),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: const Color(0xFFE2E6EF),
                                  child: const Icon(
                                    Icons.album_rounded,
                                    size: 32,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              )
                            : Container(
                                color: const Color(0xFFE2E6EF),
                                child: const Icon(
                                  Icons.album_rounded,
                                  size: 32,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                      ),
                    ),

                    // Center Spindle Hole
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0F1218),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFFFFFF),
                            offset: Offset(-1, -1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),

            // Tonearm Needle Ornament (Top-Right of Deck)
            Positioned(
              top: 10,
              right: 14,
              child: _TonearmWidget(isPlaying: isPlaying),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGrooveRings(double size) {
    final ringFractions = [0.55, 0.65, 0.74, 0.83, 0.91];
    return ringFractions.map((fraction) {
      return Container(
        width: size * fraction,
        height: size * fraction,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
      );
    }).toList();
  }
}

/// Tonearm needle ornament with metallic pivot and stylus head.
class _TonearmWidget extends StatelessWidget {
  final bool isPlaying;

  const _TonearmWidget({required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      turns: isPlaying ? 0.045 : 0.0,
      alignment: Alignment.topRight,
      child: SizedBox(
        width: 60,
        height: 105,
        child: Stack(
          children: [
            // Pivot Base (Top-right chrome cylinder)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE2E8F0),
                      Color(0xFF94A3B8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      offset: Offset(1, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),

            // Metal Arm Rod
            Positioned(
              top: 14,
              right: 10,
              child: Transform.rotate(
                angle: -0.22,
                alignment: Alignment.topCenter,
                child: Container(
                  width: 3.5,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFFCBD5E1),
                        Color(0xFF64748B),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Cartridge / Needle Head
            Positioned(
              bottom: 12,
              left: 4,
              child: Transform.rotate(
                angle: 0.12,
                child: Container(
                  width: 9,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: const Color(0xFF1E293B),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        offset: Offset(1, 2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Interactive Waveform Seekbar displaying vertical monochromatic gray amplitude bars (#CED4DE to #A3ACBA).
class _WaveformSeekbar extends StatelessWidget {
  final int currentSeconds;
  final int totalSeconds;
  final ValueChanged<int> onSeek;

  const _WaveformSeekbar({
    required this.currentSeconds,
    required this.totalSeconds,
    required this.onSeek,
  });

  // Pre-calculated relative bar heights for smooth organic audio waveform
  static const List<double> _barAmplitudes = [
    0.28, 0.45, 0.70, 0.52, 0.85, 0.95, 0.60, 0.40,
    0.78, 0.90, 0.65, 0.45, 0.88, 1.00, 0.72, 0.50,
    0.68, 0.82, 0.92, 0.58, 0.38, 0.75, 0.85, 0.62,
    0.42, 0.80, 0.96, 0.70, 0.52, 0.76, 0.88, 0.64,
    0.48, 0.74, 0.90, 0.60, 0.35, 0.55, 0.78, 0.50,
  ];

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0
        ? (currentSeconds / totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) {
            final localX = details.localPosition.dx.clamp(0.0, totalWidth);
            final ratio = localX / totalWidth;
            final targetSeconds = (ratio * totalSeconds).toInt();
            onSeek(targetSeconds);
          },
          onTapDown: (details) {
            final localX = details.localPosition.dx.clamp(0.0, totalWidth);
            final ratio = localX / totalWidth;
            final targetSeconds = (ratio * totalSeconds).toInt();
            onSeek(targetSeconds);
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(_barAmplitudes.length, (index) {
                final barRatio = index / _barAmplitudes.length;
                final isPassed = barRatio <= progress;
                final barHeight = 12.0 + (_barAmplitudes[index] * 28.0);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 3.5,
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.5),
                    gradient: isPassed
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFCED4DE),
                              Color(0xFFA3ACBA),
                            ],
                          )
                        : null,
                    color: isPassed ? null : const Color(0xFFE2E7EE),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

/// Minimalist gray lossless capsule badge (neutral gray #7E8695, faint transparent gray bg, no orange star icon).
class _LosslessBadgeCapsule extends StatelessWidget {
  final Song song;

  const _LosslessBadgeCapsule({required this.song});

  @override
  Widget build(BuildContext context) {
    final qualityText = song.isHiRes
        ? 'Hi-Res Lossless • ${song.bitDepth}-bit / ${(song.sampleRate / 1000).toStringAsFixed(1)} kHz'
        : 'Lossless CD • ${song.bitDepth}-bit / ${(song.sampleRate / 1000).toStringAsFixed(1)} kHz';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x0F000000), // faint transparent gray
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x14000000),
          width: 1,
        ),
      ),
      child: Text(
        qualityText,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: Color(0xFF7E8695), // neutral gray #7E8695
        ),
      ),
    );
  }
}

/// Circular Neumorphic button helper for playback controls and header bar.
class _NeumorphicIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const _NeumorphicIconButton({
    required this.icon,
    required this.onTap,
    this.size = 46,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: AppTheme.neumorphicConvex(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: const Color(0xFF1C1F26),
          ),
        ),
      ),
    );
  }
}

/// Minimalist Neumorphic toggle button for real-time Synced Lyrics view.
class _NeumorphicLyricsButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _NeumorphicLyricsButton({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E232E) : const Color(0x0F000000),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF1E232E) : const Color(0x14000000),
            width: 1,
          ),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Color(0x281E232E),
                    offset: Offset(0, 3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lyrics_rounded,
              size: 13,
              color: isActive ? Colors.white : const Color(0xFF7E8695),
            ),
            const SizedBox(width: 5),
            Text(
              'LYRICS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isActive ? Colors.white : const Color(0xFF7E8695),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Synced Lyrics deck widget replacing the Vinyl Turntable deck.
/// Features smooth auto-scrolling to the active lyric line, karaoke-style highlighting,
/// and edge fade shaders.
class _LyricsDeck extends StatefulWidget {
  final Song song;

  const _LyricsDeck({
    super.key,
    required this.song,
  });

  @override
  State<_LyricsDeck> createState() => _LyricsDeckState();
}

class _LyricsDeckState extends State<_LyricsDeck> {
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _lyricKeys = [];
  int _lastActiveIndex = -1;
  String? _lastSongId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final player = context.read<PlayerProvider>();
        if (player.currentLyricIndex >= 0) {
          _scrollToActiveIndex(player.currentLyricIndex);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveIndex(int activeIndex) {
    if (activeIndex < 0 || activeIndex >= _lyricKeys.length) return;
    final keyContext = _lyricKeys[activeIndex].currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        alignment: 0.5, // 0.5 locks item in exact vertical center
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else if (_scrollController.hasClients) {
      const approxItemHeight = 44.0;
      final target = (activeIndex * approxItemHeight).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(target);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || activeIndex >= _lyricKeys.length) return;
        final retryContext = _lyricKeys[activeIndex].currentContext;
        if (retryContext != null) {
          Scrollable.ensureVisible(
            retryContext,
            alignment: 0.5,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final deckSize = (screenWidth * 0.78).clamp(260.0, 310.0);
    final lyrics = player.currentLyrics;
    final activeIndex = player.currentLyricIndex;

    // Maintain GlobalKey list matching current lyrics length
    if (lyrics != null) {
      if (_lyricKeys.length != lyrics.length || widget.song.id != _lastSongId) {
        _lastSongId = widget.song.id;
        _lyricKeys = List.generate(lyrics.length, (_) => GlobalKey());
        _lastActiveIndex = -1;
      }
    } else {
      _lyricKeys = [];
      _lastSongId = widget.song.id;
    }

    // Trigger auto-scroll on active lyric line change
    if (activeIndex != _lastActiveIndex && lyrics != null && lyrics.isNotEmpty) {
      _lastActiveIndex = activeIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToActiveIndex(activeIndex);
      });
    }

    Widget content;

    if (player.isLoadingLyrics) {
      content = const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Color(0xFF1E232E),
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Mencari lirik...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8C93A0),
              ),
            ),
          ],
        ),
      );
    } else if (lyrics == null || lyrics.isEmpty) {
      content = const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.subtitles_off_rounded,
              size: 40,
              color: Color(0xFFA3ACBA),
            ),
            SizedBox(height: 10),
            Text(
              'Lirik tidak tersedia',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8C93A0),
              ),
            ),
          ],
        ),
      );
    } else {
      content = ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0.0, 0.14, 0.86, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
            vertical: 140,
            horizontal: 24,
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: lyrics.length,
          itemBuilder: (context, index) {
            final line = lyrics[index];
            final isActive = index == activeIndex;

            return GestureDetector(
              key: _lyricKeys[index],
              onTap: () => player.seek(line.timestamp),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                child: Text(
                  line.text.isNotEmpty ? line.text : '•••',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isActive ? 18 : 15,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                    color: isActive
                        ? const Color(0xFF1E232E)
                        : const Color(0xFFA3ACBA),
                    height: 1.35,
                    letterSpacing: isActive ? -0.2 : 0.0,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Container(
      width: deckSize,
      height: deckSize,
      decoration: AppTheme.neumorphicConvex(
        borderRadius: 28,
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(12),
      child: content,
    );
  }
}
