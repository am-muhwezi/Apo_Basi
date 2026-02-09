import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 3D-style bus marker for real-time tracking (yellow school bus theme)
class BusMarker3D extends StatelessWidget {
  final double size;
  final double heading; // Rotation angle in degrees
  final bool isMoving;
  final String? vehicleNumber; // Optional vehicle number to display

  const BusMarker3D({
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
          // Outer glow/pulse effect for moving bus
          if (isMoving)
            Container(
              width: size * 1.6,
              height: size * 1.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFFFD700).withValues(alpha: 0.4), // Gold yellow
                    Color(0xFFFFD700).withValues(alpha: 0.2),
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
                      ? Color(0xFFFFD700).withValues(alpha: 0.4) // Gold glow when moving
                      : Colors.transparent,
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // Yellow bus image
          Container(
            width: size,
            height: size,
            child: Image.asset(
              'assets/images/Bus 2.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
          ),

          // "LIVE" badge for moving bus
          if (isMoving)
            Positioned(
              bottom: -size * 0.35,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size * 0.2,
                  vertical: size * 0.08,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4CAF50), // Green for live
                      Color(0xFF45A049),
                    ],
                  ),
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
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFFD700), // Gold yellow
                      Color(0xFFFFA500), // Orange
                    ],
                  ),
                  borderRadius: BorderRadius.circular(size * 0.12),
                  border: Border.all(
                    color: Color(0xFFCC8800),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: size * 0.16,
                    ),
                    SizedBox(width: size * 0.05),
                    Text(
                      vehicleNumber!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
