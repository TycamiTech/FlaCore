import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/song_model.dart';
import '../../providers/player_provider.dart';
import '../widgets/mini_player.dart';
import 'now_playing_screen.dart';

/// Artist Detail Screen featuring the Orbit Curved List specifically for the selected artist's songs.
class ArtistDetailScreen extends StatefulWidget {
  final String artistName;
  final List<Song> songs;

  const ArtistDetailScreen({
    super.key,
    required this.artistName,
    required this.songs,
  });

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _snapController;
  Animation<double>? _snapAnimation;
  late final ValueNotifier<double> _scrollIndexNotifier;

  // Spacing and step angle matching ExploreScreen
  static const double _stepAngle = 0.25;
  static const double _pixelsPerItem = 124.0;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.songs.isNotEmpty
        ? (widget.songs.length ~/ 2)
            .clamp(0, widget.songs.length - 1)
            .toDouble()
        : 0.0;
    _scrollIndexNotifier = ValueNotifier<double>(initialIndex);

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(() {
        if (_snapAnimation != null) {
          _scrollIndexNotifier.value = _snapAnimation!.value;
        }
      });
  }

  @override
  void dispose() {
    _snapController.dispose();
    _scrollIndexNotifier.dispose();
    super.dispose();
  }

  void _animateToIndex(int targetIndex, int totalSongs) {
    if (totalSongs <= 0) return;
    final clamped = targetIndex.clamp(0, totalSongs - 1).toDouble();
    _snapAnimation = Tween<double>(
      begin: _scrollIndexNotifier.value,
      end: clamped,
    ).animate(CurvedAnimation(
      parent: _snapController,
      curve: Curves.easeOutCubic,
    ));
    _snapController.forward(from: 0.0);
  }

  void _onPlaySong(Song song, List<Song> allSongs) {
    final player = context.read<PlayerProvider>();
    player.playSong(song, queue: allSongs);

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const NowPlayingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCurrentSong = context.select<PlayerProvider, bool>(
      (p) => p.hasCurrentSong,
    );
    final songs = widget.songs;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Orbit and Header isolated with RepaintBoundary
              Positioned.fill(
                child: RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                // 1. Header with Neumorphic Back Button aligned with bold Artist Name
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 12.0, 24.0, 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x12000000),
                                offset: Offset(2, 4),
                                blurRadius: 10,
                              ),
                              BoxShadow(
                                color: Color(0xFFFFFFFF),
                                offset: Offset(-2, -2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: Color(0xFF1E232E),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.artistName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E232E),
                            letterSpacing: -0.6,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Orbit Curved List Area for Artist's Songs
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (songs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No tracks found for this artist',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8C93A3),
                            ),
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          final h = constraints.maxHeight;

                          // Orbital Coordinate System matching ExploreScreen
                          final centerX = w * 1.44;
                          final centerY = h * 0.48;
                          final radius = w * 1.25;

                          // Orbit arc line passing behind items right under the Play button
                          final arcRadius = centerX - (w - 74);

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onVerticalDragStart: (_) {
                              _snapController.stop();
                            },
                            onVerticalDragUpdate: (details) {
                              final maxBound = math.max(0, songs.length - 1).toDouble();
                              final next = _scrollIndexNotifier.value -
                                  (details.primaryDelta! / _pixelsPerItem);
                              _scrollIndexNotifier.value = next.clamp(0.0, maxBound);
                            },
                            onVerticalDragEnd: (details) {
                              final velocity = details.primaryVelocity ?? 0.0;
                              final double projectedTarget =
                                  _scrollIndexNotifier.value - (velocity / 750.0);
                              _animateToIndex(
                                projectedTarget.round(),
                                songs.length,
                              );
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // A. Orbit Arc Line (#E5E9F0, strokeWidth 1.5) (RepaintBoundary isolation)
                                Positioned.fill(
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      painter: _OrbitArcPainter(
                                        centerX: centerX,
                                        centerY: centerY,
                                        radius: arcRadius,
                                      ),
                                    ),
                                  ),
                                ),

                                // C. Render visible orbit items isolated with ListenableBuilder & RepaintBoundary
                                Positioned.fill(
                                  child: RepaintBoundary(
                                    child: ListenableBuilder(
                                      listenable: _scrollIndexNotifier,
                                      builder: (context, _) {
                                        final scrollIndex = _scrollIndexNotifier.value;
                                        return Stack(
                                          clipBehavior: Clip.none,
                                          children: _buildOrbitItems(
                                            songs: songs,
                                            scrollIndex: scrollIndex,
                                            w: w,
                                            centerX: centerX,
                                            centerY: centerY,
                                            radius: radius,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Floating Mini Player isolated in RepaintBoundary
        if (hasCurrentSong)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: const RepaintBoundary(
              child: MiniPlayer(isVisible: true),
            ),
          ),
      ],
    ),
      ),
    ),
  );
}

  List<Widget> _buildOrbitItems({
    required List<Song> songs,
    required double scrollIndex,
    required double w,
    required double centerX,
    required double centerY,
    required double radius,
  }) {
    final widgets = <Widget>[];
    final minIdx = math.max(0, (scrollIndex - 4).floor());
    final maxIdx = math.min(songs.length - 1, (scrollIndex + 4).ceil());
    final activeCenterIdx = scrollIndex.round().clamp(0, songs.length - 1);

    // Render inactive items first so active center capsule layers cleanly on top
    for (int i = minIdx; i <= maxIdx; i++) {
      if (i == activeCenterIdx) continue;
      widgets.add(
        _buildSingleOrbitItem(
          index: i,
          scrollIndex: scrollIndex,
          song: songs[i],
          songs: songs,
          w: w,
          centerX: centerX,
          centerY: centerY,
          radius: radius,
          isActive: false,
        ),
      );
    }

    // Render active center item on top
    if (activeCenterIdx >= 0 && activeCenterIdx < songs.length) {
      widgets.add(
        _buildSingleOrbitItem(
          index: activeCenterIdx,
          scrollIndex: scrollIndex,
          song: songs[activeCenterIdx],
          songs: songs,
          w: w,
          centerX: centerX,
          centerY: centerY,
          radius: radius,
          isActive: true,
        ),
      );
    }

    return widgets;
  }

  Widget _buildSingleOrbitItem({
    required int index,
    required double scrollIndex,
    required Song song,
    required List<Song> songs,
    required double w,
    required double centerX,
    required double centerY,
    required double radius,
    required bool isActive,
  }) {
    final deltaIndex = index - scrollIndex;
    final angle = deltaIndex * _stepAngle;

    // Trigonometric coordinates for avatar center along the circle arc
    final avatarCenterX = centerX - (radius * math.cos(angle));
    final avatarCenterY = centerY + (radius * math.sin(angle));

    // Opacity fades out gently towards top and bottom
    final distance = deltaIndex.abs();
    final opacity = (1.0 - (distance * 0.20)).clamp(0.35, 1.0);

    const avatarSize = 92.0;

    // Active Center Item: pure white Neumorphic capsule with FULLY ROUNDED CORNERS (semi-circle on both ends)
    if (isActive && distance < 0.85) {
      const capsuleLeft = 20.0;
      const capsuleRight = 18.0;
      final capsuleWidth = w - capsuleLeft - capsuleRight;
      const capsuleHeight = 108.0;
      final capsuleTop = avatarCenterY - (capsuleHeight / 2);
      const capsuleRadius = capsuleHeight / 2;

      return Positioned(
        left: 0,
        top: 0,
        child: Transform.translate(
          offset: Offset(capsuleLeft, capsuleTop),
          child: RepaintBoundary(
            child: SizedBox(
              width: capsuleWidth,
              height: capsuleHeight,
              child: GestureDetector(
                onTap: () => _onPlaySong(song, songs),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 18, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(capsuleRadius), // FULLY ROUNDED
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        offset: Offset(4, 7),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. CD Disc Avatar 92x92 with white rim & spindle hole
                      _CdDiscAvatar(song: song, size: avatarSize),

                      const SizedBox(width: 16),

                      // 2. Title & Artist (Bold, 100% horizontal, straight, with ellipsis)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E232E),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.artist,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7385),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // 3. Raised Neumorphic "Play" button
                      GestureDetector(
                        onTap: () => _onPlaySong(song, songs),
                        child: Container(
                          width: 66,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(19),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x12000000),
                                offset: Offset(2, 3),
                                blurRadius: 8,
                              ),
                              BoxShadow(
                                color: Color(0xFFFFFFFF),
                                offset: Offset(-2, -2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Play',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E232E),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Inactive Item: Avatar placed exactly on arc, with Text locked 16px to its right (100% horizontal)
    final avatarLeft = avatarCenterX - (avatarSize / 2);
    final avatarTop = avatarCenterY - (avatarSize / 2);
    final rowWidth = (w - avatarLeft - 16).clamp(200.0, 360.0);

    return Positioned(
      left: 0,
      top: 0,
      child: Transform.translate(
        offset: Offset(avatarLeft, avatarTop),
        child: RepaintBoundary(
          child: GestureDetector(
            onTap: () => _animateToIndex(index, songs.length),
            behavior: HitTestBehavior.opaque,
            child: Opacity(
              opacity: opacity,
              child: SizedBox(
                width: rowWidth,
                height: avatarSize,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. CD Disc Avatar 92x92
                    _CdDiscAvatar(song: song, size: avatarSize),

                    const SizedBox(width: 16),

                    // 2. Title & Artist locked horizontally next to avatar
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E232E),
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artist,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7385),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact Disc (CD) Avatar matching ExploreScreen
class _CdDiscAvatar extends StatelessWidget {
  final Song song;
  final double size;

  const _CdDiscAvatar({
    required this.song,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEFF1F5),
        border: Border.all(
          color: Colors.white,
          width: 2.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            offset: Offset(3, 6),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Color(0xFFFFFFFF),
            offset: Offset(-2, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Album Artwork base with memory caching optimization
            Positioned.fill(
              child: song.hasCover
                  ? CachedNetworkImage(
                      imageUrl: song.coverUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 250,
                      memCacheHeight: 250,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFFE2E6EF),
                      ),
                      errorWidget: (context, url, error) => _defaultCover(),
                    )
                  : _defaultCover(),
            ),

            // 2. Holographic Specular CD Sheen (Polycarbonate sheen)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.32),
                      Colors.white.withValues(alpha: 0.04),
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.18),
                    ],
                    stops: const [0.0, 0.35, 0.65, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultCover() {
    return Container(
      color: const Color(0xFFE4E8F0),
      child: const Center(
        child: Icon(
          Icons.album_rounded,
          size: 44,
          color: Color(0xFF8C93A0),
        ),
      ),
    );
  }
}

/// Draws the thin orbit arc line (#E5E9F0, strokeWidth 1.5) behind the items
class _OrbitArcPainter extends CustomPainter {
  final double centerX;
  final double centerY;
  final double radius;

  _OrbitArcPainter({
    required this.centerX,
    required this.centerY,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5E9F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const sweep = 1.6;
    final startAngle = math.pi - (sweep / 2);

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: radius,
      ),
      startAngle,
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitArcPainter oldDelegate) =>
      oldDelegate.centerX != centerX ||
      oldDelegate.centerY != centerY ||
      oldDelegate.radius != radius;
}
