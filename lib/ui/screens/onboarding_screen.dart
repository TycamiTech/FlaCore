import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import 'main_shell.dart';

/// Onboarding Screen welcoming first-time FlaCore users.
/// Implements a frosted Glassmorphic card, tactile physical music illustration (CDs & Cassette),
/// bold stacked typography ("New / Age Of / Music"), and a convex Neumorphic "Get Started" button.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _onGetStarted(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainShell(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: Curves.easeOutCubic),
            );
            final slideTween = Tween<Offset>(
              begin: const Offset(0.0, 0.04),
              end: Offset.zero,
            ).chain(
              CurveTween(curve: Curves.easeOutCubic),
            );

            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: SlideTransition(
                position: animation.drive(slideTween),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.65),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    offset: Offset(0, 16),
                    blurRadius: 36,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Color(0x80FFFFFF),
                    offset: Offset(-4, -4),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28.0, 24.0, 28.0, 28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Music Physical Illustration Composition (Discs & Cassette)
                      const Expanded(
                        flex: 5,
                        child: _MusicPhysicalIllustration(),
                      ),

                      // 2. Stacked Typography (Bottom Left)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'New',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF161922),
                              letterSpacing: -1.0,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'Age Of',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF9CA3AF),
                              letterSpacing: -1.0,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'Music',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF161922),
                              letterSpacing: -1.0,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // 3. Neumorphic "Get Started" Capsule Button
                      GestureDetector(
                        onTap: () => _onGetStarted(context),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: double.infinity,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(29),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x18000000),
                                offset: Offset(0, 8),
                                blurRadius: 18,
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Color(0xFFFFFFFF),
                                offset: Offset(0, -2),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF161922),
                                letterSpacing: -0.2,
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
      ),
    );
  }
}

/// Physical music format collage composition:
/// - 2 overlapping silver vinyl discs on the upper-left with concentric groove rings.
/// - 1 CD disc with monochrome wave graphics on the upper-right.
/// - 1 transparent Neumorphic cassette tape with label "B" and two spool wheels.
class _MusicPhysicalIllustration extends StatelessWidget {
  const _MusicPhysicalIllustration();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // A. Top-left Disc 1 (Back silver vinyl disc)
            Positioned(
              top: h * 0.04,
              left: w * 0.02,
              child: const _SilverVinylDisc(size: 130),
            ),

            // B. Top-left Disc 2 (Overlapping silver disc with subtle tilt)
            Positioned(
              top: h * 0.12,
              left: w * 0.24,
              child: const _SilverVinylDisc(size: 118),
            ),

            // C. Top-right Disc 3 (CD with monochrome wave graphics)
            Positioned(
              top: h * 0.02,
              right: w * 0.02,
              child: const _MonochromeWaveCd(size: 136),
            ),

            // D. Middle-right Neumorphic Cassette Tape with label "B"
            Positioned(
              top: h * 0.44,
              right: w * 0.04,
              child: const _NeumorphicCassetteTape(
                width: 168,
                height: 104,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Silver vinyl disc with concentric circular groove rings and white outer outline.
class _SilverVinylDisc extends StatelessWidget {
  final double size;

  const _SilverVinylDisc({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8EDF5),
            Color(0xFFF7FAFD),
            Color(0xFFD6DCE8),
            Color(0xFFEFF2F8),
          ],
          stops: [0.0, 0.35, 0.70, 1.0],
        ),
        border: Border.all(
          color: Colors.white,
          width: 2.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            offset: Offset(4, 8),
            blurRadius: 16,
          ),
          BoxShadow(
            color: Color(0xFFFFFFFF),
            offset: Offset(-2, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _GrooveRingsPainter(),
        child: Center(
          child: Container(
            width: size * 0.22,
            height: size * 0.22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF4F5F9),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Center(
              child: Container(
                width: size * 0.08,
                height: size * 0.08,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFCBD2DE),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter for delicate concentric groove lines on vinyl/CD discs.
class _GrooveRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    final paint = Paint()
      ..color = const Color(0x1F000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    for (double r = maxRadius * 0.32; r < maxRadius * 0.92; r += 5.5) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// CD Disc featuring optical monochrome wave graphic pattern.
class _MonochromeWaveCd extends StatelessWidget {
  final double size;

  const _MonochromeWaveCd({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF161922),
        border: Border.all(color: Colors.white, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            offset: Offset(4, 10),
            blurRadius: 20,
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
            // Graphic monochrome wavy ripples
            CustomPaint(
              size: Size(size, size),
              painter: _MonochromeWavePainter(),
            ),

            // Holographic translucent sheen overlay
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.28),
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.14),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Center spindle disc
            Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF4F5F9),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x20000000),
                    offset: Offset(1, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: size * 0.10,
                  height: size * 0.10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF161922),
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

/// Custom painter for stylized high-contrast monochrome wave pattern on CD.
class _MonochromeWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int i = 1; i <= 6; i++) {
      final path = Path();
      final radius = (size.width * 0.08) * i;
      final step = math.pi / 24;

      for (double a = 0; a <= 2 * math.pi + step; a += step) {
        final wave = math.sin(a * 4 + i) * 3.5;
        final r = radius + wave;
        final x = center.dx + r * math.cos(a);
        final y = center.dy + r * math.sin(a);

        if (a == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Transparent Neumorphic Cassette Tape with label "B" and two spool wheels.
class _NeumorphicCassetteTape extends StatelessWidget {
  final double width;
  final double height;

  const _NeumorphicCassetteTape({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.06,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.95),
            width: 1.6,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              offset: Offset(4, 10),
              blurRadius: 18,
            ),
            BoxShadow(
              color: Color(0xFFFFFFFF),
              offset: Offset(-2, -2),
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            // Top Screws & Header Line
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _screwDot(),
                Container(
                  width: width * 0.45,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0x20000000),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _screwDot(),
              ],
            ),

            const SizedBox(height: 6),

            // Middle Window with Label "B" and 2 Spool Wheels
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x10000000),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0x14000000),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bold Label "B"
                    const Text(
                      'B',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF161922),
                      ),
                    ),

                    // Center Spool Area: Wheel 1 + Tape Ribbon + Wheel 2
                    Expanded(
                      child: Container(
                        height: 38,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0x18000000),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _spoolWheel(),
                            // Dark magnetic tape ribbon between spools
                            Container(
                              width: 34,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C1E1A),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            _spoolWheel(),
                          ],
                        ),
                      ),
                    ),

                    // Balance spacing right
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Bottom Tape Head Cutout / Trapezoid Notch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _screwDot(),
                Container(
                  width: width * 0.55,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0x14000000),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    border: Border.all(
                      color: const Color(0x10000000),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _guideHole(),
                      _guideHole(),
                    ],
                  ),
                ),
                _screwDot(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _spoolWheel() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: const Color(0x30000000),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF161922),
          ),
        ),
      ),
    );
  }

  Widget _screwDot() {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0x40000000),
      ),
    );
  }

  Widget _guideHole() {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF4F5F9),
      ),
    );
  }
}
