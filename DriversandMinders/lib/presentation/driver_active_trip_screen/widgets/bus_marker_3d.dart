import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 3D-style bus marker with realistic appearance
class BusMarker3D extends StatelessWidget {
  final double size;
  final double heading; // Rotation angle in degrees
  final bool isMoving;

  const BusMarker3D({
    super.key,
    this.size = 50,
    this.heading = 0,
    this.isMoving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: heading * (math.pi / 180), // Convert degrees to radians
      child: Container(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Shadow for 3D effect
            Positioned(
              bottom: 0,
              child: Container(
                width: size * 0.8,
                height: size * 0.2,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

            // Main bus body
            CustomPaint(
              size: Size(size, size * 0.8),
              painter: _BusPainter(isMoving: isMoving),
            ),

            // Moving indicator
            if (isMoving)
              Positioned(
                top: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
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

class _BusPainter extends CustomPainter {
  final bool isMoving;

  _BusPainter({required this.isMoving});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Bus body - main gradient
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.2, size.width * 0.8, size.height * 0.6),
      Radius.circular(8),
    );

    // 3D gradient effect
    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isMoving
          ? [
              Color(0xFFFFB800), // Bright orange-yellow
              Color(0xFFFFA000), // Deep orange
              Color(0xFFFF8F00), // Darker orange
            ]
          : [
              Color(0xFF1976D2), // Blue
              Color(0xFF1565C0), // Darker blue
              Color(0xFF0D47A1), // Deep blue
            ],
    ).createShader(bodyRect.outerRect);

    canvas.drawRRect(bodyRect, paint);

    // Bus body border for depth
    paint
      ..shader = null
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(bodyRect, paint);

    // Windows (lighter rectangles)
    paint
      ..style = PaintingStyle.fill
      ..color = Color(0xFF87CEEB).withValues(alpha: 0.8); // Sky blue

    // Front window
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.15,
          size.height * 0.25,
          size.width * 0.25,
          size.height * 0.25,
        ),
        Radius.circular(4),
      ),
      paint,
    );

    // Side windows
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.45,
          size.height * 0.25,
          size.width * 0.15,
          size.height * 0.25,
        ),
        Radius.circular(4),
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.65,
          size.height * 0.25,
          size.width * 0.15,
          size.height * 0.25,
        ),
        Radius.circular(4),
      ),
      paint,
    );

    // Window frames
    paint
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.15, size.height * 0.25, size.width * 0.25, size.height * 0.25),
        Radius.circular(4),
      ),
      paint,
    );

    // Wheels (dark circles with highlights)
    paint
      ..style = PaintingStyle.fill
      ..color = Color(0xFF212121); // Almost black

    // Left wheel
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.85),
      size.width * 0.08,
      paint,
    );

    // Right wheel
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.85),
      size.width * 0.08,
      paint,
    );

    // Wheel highlights for 3D effect
    paint.color = Colors.white.withValues(alpha: 0.3);
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.82),
      size.width * 0.03,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.82),
      size.width * 0.03,
      paint,
    );

    // Front bumper/grill
    paint.color = Colors.black.withValues(alpha: 0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.08,
          size.height * 0.7,
          size.width * 0.15,
          size.height * 0.08,
        ),
        Radius.circular(2),
      ),
      paint,
    );

    // Headlights
    if (isMoving) {
      paint.color = Color(0xFFFFEB3B); // Bright yellow
      canvas.drawCircle(
        Offset(size.width * 0.12, size.height * 0.73),
        size.width * 0.04,
        paint,
      );

      // Headlight glow
      paint.color = Color(0xFFFFEB3B).withValues(alpha: 0.3);
      canvas.drawCircle(
        Offset(size.width * 0.12, size.height * 0.73),
        size.width * 0.06,
        paint,
      );
    }

    // Roof detail (for depth)
    paint
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.12,
          size.height * 0.18,
          size.width * 0.76,
          size.height * 0.04,
        ),
        Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BusPainter oldDelegate) => oldDelegate.isMoving != isMoving;
}
