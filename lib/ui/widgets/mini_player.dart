import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/player_provider.dart';
import '../screens/now_playing_screen.dart';

/// Floating Neumorphic Mini Player with a continuously rotating vinyl disc.
class MiniPlayer extends StatefulWidget {
  final bool isVisible;

  const MiniPlayer({
    super.key,
    this.isVisible = true,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
  }

  @override
  void didUpdateWidget(covariant MiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isVisible && _rotationController.isAnimating) {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;

    if (song == null) {
      if (_rotationController.isAnimating) {
        _rotationController.stop();
      }
      return const SizedBox.shrink();
    }

    // Turntable rotation ONLY runs when MiniPlayer is visible on screen, is top route, AND playing
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
    final shouldAnimate = widget.isVisible && isCurrentRoute && player.isPlaying;
    if (shouldAnimate) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      if (_rotationController.isAnimating) {
        _rotationController.stop();
      }
    }

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const NowPlayingScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
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
          },
          child: Container(
            height: 66,
            decoration: AppTheme.neumorphicConvex(
              borderRadius: 22,
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  // Content Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        // Rotating Vinyl Disc Thumbnail (Isolated with RepaintBoundary)
                        RepaintBoundary(
                          child: RotationTransition(
                            turns: _rotationController,
                            child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF14171E),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x24000000),
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(5),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Grooves ring
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0x22FFFFFF),
                                    width: 1,
                                  ),
                                ),
                              ),
                              // Center Album Art Label
                              ClipOval(
                                child: song.hasCover
                                    ? CachedNetworkImage(
                                        imageUrl: song.coverUrl,
                                        width: 26,
                                        height: 26,
                                        fit: BoxFit.cover,
                                        memCacheWidth: 250,
                                        memCacheHeight: 250,
                                        placeholder: (context, url) =>
                                            _coverPlaceholder(),
                                        errorWidget: (context, url, error) =>
                                            _coverPlaceholder(),
                                      )
                                    : _coverPlaceholder(),
                              ),
                              // Center spindle hole
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF0F1218),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                      // Title & Artist (Clean, NO BADGES)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.artist,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Play/Pause Button (White Neumorphic circle with dark icon)
                      GestureDetector(
                        onTap: () => player.togglePlayPause(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: AppTheme.neumorphicConvex(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Center(
                            child: Icon(
                              player.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 20,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Next Track Button
                      GestureDetector(
                        onTap: () => player.next(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: AppTheme.neumorphicConvex(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.skip_next_rounded,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Slim Progress Bar at Bottom (Isolated with RepaintBoundary)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: RepaintBoundary(
                    child: LinearProgressIndicator(
                      value: player.progress,
                      minHeight: 2.0,
                      backgroundColor: const Color(0xFFE5E9F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF7E8695),
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
  );
}

  Widget _coverPlaceholder() {
    return Container(
      width: 28,
      height: 28,
      color: const Color(0xFFE2E6EF),
      child: const Center(
        child: Icon(
          Icons.album_rounded,
          size: 16,
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}
