// lib/screens/splash_screen.dart
// DoE PNG Mobile App — Branded Splash Screen
// Matches the HTML/CSS design mockup with DoE logo.

import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── DoE Brand palette ────────────────────────────────────────────
  static const _bg   = Color(0xFF0E2554);
  static const _arc  = Color(0xFF1A3A8A);
  static const _gold = Color(0xFFC8960C);
  static const _blue = Color(0xFF8AAAD4);

  // ── Controllers ──────────────────────────────────────────────────
  late final AnimationController _outerRingCtrl;
  late final AnimationController _innerRingCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _entranceCtrl;
  late final AnimationController _dotPulseCtrl;
  late final AnimationController _exitCtrl;

  // Shimmer
  late final Animation<double> _arc1Opacity;
  late final Animation<double> _arc2Opacity;

  // Logo
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // Gold line
  late final Animation<double> _lineOpacity;
  late final Animation<double> _lineSlide;

  // Title
  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleSlide;

  // Subtitle
  late final Animation<double> _subOpacity;
  late final Animation<double> _subSlide;

  // Tagline
  late final Animation<double> _tagOpacity;
  late final Animation<double> _tagSlide;

  // Dots
  late final Animation<double> _dotsOpacity;
  late final Animation<double> _dotsSlide;

  bool _disposed = false;

  @override
  void initState() {
    super.initState();

    // Spinning rings
    _outerRingCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 18))
      ..repeat();
    _innerRingCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..repeat();

    // Shimmer arcs
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _arc1Opacity = Tween<double>(begin: 0.15, end: 0.35).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
    _arc2Opacity = Tween<double>(begin: 0.35, end: 0.15).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    // Entrance (1600 ms total, all elements staggered via Interval)
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));

    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.06, 0.50, curve: Curves.elasticOut)));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.06, 0.25, curve: Curves.easeIn)));

    _lineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.31, 0.50, curve: Curves.easeIn)));
    _lineSlide = Tween<double>(begin: 10.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.31, 0.50, curve: Curves.easeOut)));

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.41, 0.60, curve: Curves.easeIn)));
    _titleSlide = Tween<double>(begin: 12.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.41, 0.60, curve: Curves.easeOut)));

    _subOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.50, 0.69, curve: Curves.easeIn)));
    _subSlide = Tween<double>(begin: 12.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.50, 0.69, curve: Curves.easeOut)));

    _tagOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.63, 0.82, curve: Curves.easeIn)));
    _tagSlide = Tween<double>(begin: 12.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.63, 0.82, curve: Curves.easeOut)));

    _dotsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.75, 1.00, curve: Curves.easeIn)));
    _dotsSlide = Tween<double>(begin: 12.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.75, 1.00, curve: Curves.easeOut)));

    // Dot pulse
    _dotPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);

    // Exit
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));

    _runSequence();
  }

  Future<void> _runSequence() async {
    if (_disposed) return;
    await _entranceCtrl.forward();
    if (_disposed) return;
    await Future.delayed(const Duration(milliseconds: 1400));
    if (_disposed) return;
    await _exitCtrl.forward();
    if (_disposed || !mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _disposed = true;
    _outerRingCtrl.dispose();
    _innerRingCtrl.dispose();
    _shimmerCtrl.dispose();
    _entranceCtrl.dispose();
    _dotPulseCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitCtrl,
      builder: (_, child) =>
          Opacity(opacity: 1.0 - _exitCtrl.value, child: child),
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            // ── Shimmer arc — top left ─────────────────────────────
            AnimatedBuilder(
              animation: _arc1Opacity,
              builder: (_, __) => Positioned(
                top: -100,
                left: -100,
                child: Opacity(
                  opacity: _arc1Opacity.value,
                  child: Container(
                    width: 420,
                    height: 420,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: _arc),
                  ),
                ),
              ),
            ),

            // ── Shimmer arc — bottom right ─────────────────────────
            AnimatedBuilder(
              animation: _arc2Opacity,
              builder: (_, __) => Positioned(
                bottom: -80,
                right: -80,
                child: Opacity(
                  opacity: _arc2Opacity.value,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: _arc),
                  ),
                ),
              ),
            ),

            // ── Outer ring — 18 s clockwise ───────────────────────
            Center(
              child: RotationTransition(
                turns: _outerRingCtrl,
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    children: [
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _gold.withValues(alpha: 0.27), width: 1),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 127,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: _gold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Inner ring — 12 s counter-clockwise ───────────────
            Center(
              child: RotationTransition(
                turns: Tween<double>(begin: 1.0, end: 0.0)
                    .animate(_innerRingCtrl),
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _gold.withValues(alpha: 0.20),
                              width: 0.5),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 97,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: _gold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Corner decorations ─────────────────────────────────
            const Positioned(top: 24, left: 24, child: _Corner(flip: false)),
            const Positioned(bottom: 24, right: 24, child: _Corner(flip: true)),

            // ── All animated content, centred ──────────────────────
            AnimatedBuilder(
              animation: _entranceCtrl,
              builder: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // DoE logo in white circle
                    Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'assets/images/logo/DoE Logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // Gold gradient divider line
                    Transform.translate(
                      offset: Offset(0, _lineSlide.value),
                      child: Opacity(
                        opacity: _lineOpacity.value,
                        child: Container(
                          width: 220,
                          height: 2,
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              _gold,
                              Colors.transparent,
                            ]),
                          ),
                        ),
                      ),
                    ),

                    // Title
                    Transform.translate(
                      offset: Offset(0, _titleSlide.value),
                      child: Opacity(
                        opacity: _titleOpacity.value,
                        child: const Text(
                          'Department of\nEducation',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle in gold
                    Transform.translate(
                      offset: Offset(0, _subSlide.value),
                      child: Opacity(
                        opacity: _subOpacity.value,
                        child: const Text(
                          'PAPUA NEW GUINEA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Tagline
                    Transform.translate(
                      offset: Offset(0, _tagSlide.value),
                      child: Opacity(
                        opacity: _tagOpacity.value,
                        child: const Text(
                          'Empowering every learner, everywhere.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _blue,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Pulsing dots
                    Transform.translate(
                      offset: Offset(0, _dotsSlide.value),
                      child: Opacity(
                        opacity: _dotsOpacity.value,
                        child: AnimatedBuilder(
                          animation: _dotPulseCtrl,
                          builder: (_, __) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _pulseDot(0.0, _gold),
                              const SizedBox(width: 6),
                              _pulseDot(0.2, _blue),
                              const SizedBox(width: 6),
                              _pulseDot(0.4, _gold.withValues(alpha: 0.5)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom home-bar indicator ──────────────────────────
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 100,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.33),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pulseDot(double phase, Color color) {
    final t = (_dotPulseCtrl.value + phase) % 1.0;
    final scale   = 1.0 + 0.08 * sin(t * pi);
    final opacity = 0.6 + 0.4 * sin(t * pi);
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

// ── Corner decoration: two angled gold lines ──────────────────────────
class _Corner extends StatelessWidget {
  final bool flip;
  const _Corner({required this.flip});

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: flip ? (Matrix4.identity()..rotateZ(pi)) : Matrix4.identity(),
      child: CustomPaint(
        size: const Size(28, 28),
        painter: _CornerPainter(),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC8960C).withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width / 2, 0), paint);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
