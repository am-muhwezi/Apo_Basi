import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter for school bus themed background
class TelegramBackgroundPainter extends CustomPainter {
  final Color bubbleColor;

  TelegramBackgroundPainter({
    this.bubbleColor = const Color(0xFFFFB300), // School bus yellow
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint for buses
    final busPaint = Paint()
      ..color = bubbleColor.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    // Paint for roads
    final roadPaint = Paint()
      ..color = Colors.grey.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Paint for location pins
    final pinPaint = Paint()
      ..color = const Color(0xFF4285F4).withOpacity(0.12)
      ..style = PaintingStyle.fill;

    // Draw wavy road pattern
    _drawRoadPattern(canvas, roadPaint, size);

    // Draw school bus icons at various positions
    _drawBusIcon(
        canvas, busPaint, Offset(size.width * 0.15, size.height * 0.15), 30);
    _drawBusIcon(
        canvas, busPaint, Offset(size.width * 0.75, size.height * 0.25), 25);
    _drawBusIcon(
        canvas, busPaint, Offset(size.width * 0.25, size.height * 0.45), 28);
    _drawBusIcon(
        canvas, busPaint, Offset(size.width * 0.85, size.height * 0.55), 26);
    _drawBusIcon(
        canvas, busPaint, Offset(size.width * 0.2, size.height * 0.75), 27);
    _drawBusIcon(
        canvas, busPaint, Offset(size.width * 0.8, size.height * 0.85), 29);

    // Draw location pins
    _drawLocationPin(
        canvas, pinPaint, Offset(size.width * 0.35, size.height * 0.2), 20);
    _drawLocationPin(
        canvas, pinPaint, Offset(size.width * 0.65, size.height * 0.4), 18);
    _drawLocationPin(
        canvas, pinPaint, Offset(size.width * 0.45, size.height * 0.65), 22);
    _drawLocationPin(
        canvas, pinPaint, Offset(size.width * 0.15, size.height * 0.9), 19);
  }

  void _drawRoadPattern(Canvas canvas, Paint paint, Size size) {
    final path = Path();

    // Draw horizontal wavy lines representing roads
    for (int i = 0; i < 4; i++) {
      final y = size.height * (0.25 + i * 0.25);
      path.moveTo(0, y);

      for (double x = 0; x <= size.width; x += 20) {
        final wave = math.sin(x / 50) * 3;
        path.lineTo(x, y + wave);
      }
    }

    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  void _drawBusIcon(Canvas canvas, Paint paint, Offset center, double size) {
    // Bus body
    final busRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size * 2, height: size * 1.3),
      const Radius.circular(4),
    );
    canvas.drawRRect(busRect, paint);

    // Windows
    final windowPaint = Paint()
      ..color = paint.color.withOpacity(paint.color.opacity * 0.6)
      ..style = PaintingStyle.fill;

    final window1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx - size * 0.6, center.dy - size * 0.35,
          size * 0.45, size * 0.35),
      const Radius.circular(2),
    );
    final window2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx + size * 0.15, center.dy - size * 0.35,
          size * 0.45, size * 0.35),
      const Radius.circular(2),
    );
    canvas.drawRRect(window1, windowPaint);
    canvas.drawRRect(window2, windowPaint);

    // Wheels
    final wheelPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx - size * 0.5, center.dy + size * 0.55),
        size * 0.2, wheelPaint);
    canvas.drawCircle(Offset(center.dx + size * 0.5, center.dy + size * 0.55),
        size * 0.2, wheelPaint);
  }

  void _drawLocationPin(
      Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();

    // Draw pin shape
    path.moveTo(center.dx, center.dy - size);
    path.arcToPoint(
      Offset(center.dx, center.dy),
      radius: Radius.circular(size * 0.5),
      clockwise: false,
    );
    path.arcToPoint(
      Offset(center.dx, center.dy - size),
      radius: Radius.circular(size * 0.5),
      clockwise: false,
    );
    path.lineTo(center.dx, center.dy);

    canvas.drawPath(path, paint);

    // Draw center dot
    canvas.drawCircle(Offset(center.dx, center.dy - size * 0.7), size * 0.2,
        Paint()..color = paint.color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget wrapper for Telegram-style background
class TelegramBackground extends StatelessWidget {
  final Widget child;
  final Color? bubbleColor;

  const TelegramBackground({
    Key? key,
    required this.child,
    this.bubbleColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TelegramBackgroundPainter(
        bubbleColor: bubbleColor ?? Theme.of(context).colorScheme.primary,
      ),
      child: child,
    );
  }
}
