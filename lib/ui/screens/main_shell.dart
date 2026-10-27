import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/player_provider.dart';
import '../widgets/mini_player.dart';
import 'artists_screen.dart';
import 'explore_screen.dart';

/// Main application shell managing 2-tab navigation (Explore & Artists),
/// balanced floating bottom capsule bar, and mini player.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ExploreScreen(),
    ArtistsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    try {
      // 1. Prioritize POST_NOTIFICATIONS on Android 13+ for media & lock screen controls
      final notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted) {
        await Permission.notification.request();
      }

      // 2. Request battery optimization exemption separately after notification prompt is handled
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      debugPrint('FlaCore Permission Request Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild MainShell when active song presence changes, not on playback/position ticks
    final hasCurrentSong = context.select<PlayerProvider, bool>(
      (p) => p.hasCurrentSong,
    );

    // Hide Mini Player on Explore screen (index 0) so it doesn't obstruct the orbit curve
    final showMiniPlayer = hasCurrentSong && _currentIndex != 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // 1. Main Screens IndexedStack (2 Menus: Explore & Artists)
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // 2. Bottom Floating Overlay (MiniPlayer + 2-Menu Floating Capsule Nav Bar)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mini Player Slot (hidden on Explore screen, shown on Artists screen)
                AnimatedSlide(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  offset: showMiniPlayer
                      ? Offset.zero
                      : const Offset(0, 1.2),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: showMiniPlayer ? 1.0 : 0.0,
                    child: MiniPlayer(isVisible: showMiniPlayer),
                  ),
                ),

                // Floating 2-Menu Capsule Navigation Bar (Solid 0xFAFFFFFF with standard BoxShadow, no BackdropFilter)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Center(
                    child: Container(
                      width: 200,
                      height: 66,
                      decoration: BoxDecoration(
                        color: const Color(0xFAFFFFFF),
                        borderRadius: BorderRadius.circular(33),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            offset: Offset(0, 10),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 1. Home / Explore Icon (Left)
                          _buildNavItem(
                            index: 0,
                            iconWidget: (color) => _HomeNavIcon(color: color),
                          ),
                          // 2. Artists Icon (Right)
                          _buildNavItem(
                            index: 1,
                            iconWidget: (color) => _ArtistNavIcon(color: color),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required Widget Function(Color color) iconWidget,
  }) {
    final isSelected = _currentIndex == index;
    final iconColor = isSelected
        ? const Color(0xFF1E232E)
        : const Color(0xFF8C93A0);

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 74,
        height: 66,
        child: Center(
          child: AnimatedScale(
            scale: isSelected ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: iconWidget(iconColor),
          ),
        ),
      ),
    );
  }
}

/// Modern minimalist Home icon with balanced proportions matching _ArtistNavIcon
class _HomeNavIcon extends StatelessWidget {
  final Color color;
  static const double size = 24.0;

  const _HomeNavIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(size, size),
      painter: _HomeNavPainter(color: color),
    );
  }
}

class _HomeNavPainter extends CustomPainter {
  final Color color;

  _HomeNavPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. House contour (Modern Lucide / SF Symbols inspired architecture)
    final housePath = Path();
    housePath.moveTo(w * 0.15, h * 0.42);
    housePath.lineTo(w * 0.50, h * 0.15);
    housePath.lineTo(w * 0.85, h * 0.42);
    housePath.lineTo(w * 0.85, h * 0.80);
    housePath.quadraticBezierTo(w * 0.85, h * 0.86, w * 0.77, h * 0.86);
    housePath.lineTo(w * 0.23, h * 0.86);
    housePath.quadraticBezierTo(w * 0.15, h * 0.86, w * 0.15, h * 0.80);
    housePath.close();

    canvas.drawPath(housePath, strokePaint);

    // 2. Elegant inner door arch
    final doorPath = Path();
    doorPath.moveTo(w * 0.39, h * 0.86);
    doorPath.lineTo(w * 0.39, h * 0.58);
    doorPath.quadraticBezierTo(w * 0.50, h * 0.50, w * 0.61, h * 0.58);
    doorPath.lineTo(w * 0.61, h * 0.86);

    canvas.drawPath(doorPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _HomeNavPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Custom Artist profile avatar icon representing Artists screen
class _ArtistNavIcon extends StatelessWidget {
  final Color color;
  static const double size = 24.0;

  const _ArtistNavIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(size, size),
      painter: _ArtistNavPainter(color: color),
    );
  }
}

class _ArtistNavPainter extends CustomPainter {
  final Color color;

  _ArtistNavPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. Head circle (diameter ~9.6px, centered)
    final headCenter = Offset(w * 0.50, h * 0.34);
    canvas.drawCircle(headCenter, w * 0.20, strokePaint);

    // 2. Smooth shoulders arc (matching width and scale to Saturn icon)
    final shoulderPath = Path();
    shoulderPath.moveTo(w * 0.16, h * 0.84);
    shoulderPath.cubicTo(
      w * 0.16, h * 0.60,
      w * 0.84, h * 0.60,
      w * 0.84, h * 0.84,
    );

    canvas.drawPath(shoulderPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ArtistNavPainter oldDelegate) =>
      oldDelegate.color != color;
}
