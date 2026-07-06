import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  late Animation<Offset> _blob1;
  late Animation<Offset> _blob2;
  late Animation<Offset> _blob3;

  @override
  void initState() {
    super.initState();

    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);

    _controller3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat(reverse: true);

    _blob1 = Tween<Offset>(
      begin: const Offset(-0.15, -0.1),
      end: const Offset(0.15, 0.2),
    ).animate(CurvedAnimation(parent: _controller1, curve: Curves.easeInOut));

    _blob2 = Tween<Offset>(
      begin: const Offset(0.2, 0.1),
      end: const Offset(-0.1, 0.3),
    ).animate(CurvedAnimation(parent: _controller2, curve: Curves.easeInOut));

    _blob3 = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: const Offset(0.25, -0.05),
    ).animate(CurvedAnimation(parent: _controller3, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: Listenable.merge([_controller1, _controller2, _controller3]),
      builder: (context, _) {
        return SizedBox.expand(
          child: CustomPaint(
            painter: _BlobPainter(
              blob1Offset: _blob1.value,
              blob2Offset: _blob2.value,
              blob3Offset: _blob3.value,
              size: Size(w, h),
            ),
          ),
        );
      },
    );
  }
}

class _BlobPainter extends CustomPainter {
  final Offset blob1Offset;
  final Offset blob2Offset;
  final Offset blob3Offset;
  final Size size;

  _BlobPainter({
    required this.blob1Offset,
    required this.blob2Offset,
    required this.blob3Offset,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final w = canvasSize.width;
    final h = canvasSize.height;

    // Base gradient — deep burgundy to dusty rose
    final bgPaint = Paint();
    final bgRect = Rect.fromLTWH(0, 0, w, h);
    bgPaint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF5C1F28), // very deep burgundy top
        Color(0xFF8B3A42), // mid burgundy
        Color(0xFFB56F76), // dusty rose bottom
      ],
      stops: [0.0, 0.5, 1.0],
    ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // Blob 1 — large glowing light rose orb, top-right area
    final blob1Center = Offset(
      w * (0.75 + blob1Offset.dx),
      h * (0.12 + blob1Offset.dy),
    );
    final blob1Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFD4909A).withValues(alpha: 0.55),
          const Color(0xFFB56F76).withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: blob1Center, radius: w * 0.55));
    canvas.drawCircle(blob1Center, w * 0.55, blob1Paint);

    // Blob 2 — medium mauve orb, mid-left
    final blob2Center = Offset(
      w * (0.2 + blob2Offset.dx),
      h * (0.28 + blob2Offset.dy),
    );
    final blob2Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFC47A85).withValues(alpha: 0.45),
          const Color(0xFF9B4A55).withValues(alpha: 0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: blob2Center, radius: w * 0.45));
    canvas.drawCircle(blob2Center, w * 0.45, blob2Paint);

    // Blob 3 — small bright highlight orb, upper-center for glossy sheen
    final blob3Center = Offset(
      w * (0.5 + blob3Offset.dx),
      h * (0.06 + blob3Offset.dy),
    );
    final blob3Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE8B4BA).withValues(alpha: 0.4),
          const Color(0xFFD4909A).withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: blob3Center, radius: w * 0.35));
    canvas.drawCircle(blob3Center, w * 0.35, blob3Paint);
  }

  @override
  bool shouldRepaint(_BlobPainter old) =>
      old.blob1Offset != blob1Offset ||
      old.blob2Offset != blob2Offset ||
      old.blob3Offset != blob3Offset;
}