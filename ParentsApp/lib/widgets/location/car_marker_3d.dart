import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 3D-style car marker for real-time tracking (Uber-like)
class CarMarker3D extends StatelessWidget {
  final double size;
  final double heading; // Rotation angle in degrees
  final bool isMoving;
  final String? vehicleNumber; // Optional vehicle number to display

  const CarMarker3D({
    super.key,
    this.size = 60,
    this.heading = 0,
    this.isMoving = false,
    this.vehicleNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: heading * (math.pi / 180), // Convert degrees to radians
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Outer glow/pulse effect (like Uber)
          if (isMoving)
            Container(
              width: size * 1.6,
              height: size * 1.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFFFB800).withValues(alpha: 0.3),
                    Color(0xFFFFB800).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

          // Shadow circle
          Container(
            width: size * 1.2,
            height: size * 1.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: isMoving
                      ? Color(0xFFFFB800).withValues(alpha: 0.3)
                      : Colors.transparent,
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // Car image with rotation
          Container(
            width: size,
            height: size,
            child: Image.asset(
              'assets/images/car.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
          ),

          // Direction indicator (arrow pointing forward)
          Positioned(
            top: -size * 0.15,
            child: Container(
              width: size * 0.25,
              height: size * 0.35,
              decoration: BoxDecoration(
                color: isMoving ? Color(0xFFFFB800) : Color(0xFF757575),
                borderRadius: BorderRadius.circular(size * 0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),

          // "LIVE" badge
          if (isMoving)
            Positioned(
              bottom: -size * 0.35,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size * 0.2,
                  vertical: size * 0.08,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(size * 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

          // Vehicle number badge (optional)
          if (vehicleNumber != null && vehicleNumber!.isNotEmpty)
            Positioned(
              top: -size * 0.45,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size * 0.15,
                  vertical: size * 0.08,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(size * 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  vehicleNumber!,
                  style: TextStyle(
                    color: Color(0xFF212121),
                    fontSize: size * 0.16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
