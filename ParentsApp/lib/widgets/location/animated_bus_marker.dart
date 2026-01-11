import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'bus_marker_3d.dart';

/// Animated bus marker that smoothly transitions between positions and headings
class AnimatedBusMarker extends StatefulWidget {
  final LatLng position;
  final double heading;
  final bool isMoving;
  final String? vehicleNumber;
  final double size;

  const AnimatedBusMarker({
    super.key,
    required this.position,
    this.heading = 0,
    this.isMoving = false,
    this.vehicleNumber,
    this.size = 50,
  });

  @override
  State<AnimatedBusMarker> createState() => _AnimatedBusMarkerState();
}

class _AnimatedBusMarkerState extends State<AnimatedBusMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _headingAnimation;
  double _previousHeading = 0;
  LatLng? _previousPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800), // Smooth 800ms transition
      vsync: this,
    );

    _previousHeading = widget.heading;
    _previousPosition = widget.position;

    _headingAnimation = Tween<double>(
      begin: _previousHeading,
      end: widget.heading,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(AnimatedBusMarker oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only animate if heading changed significantly (> 5 degrees)
    if ((widget.heading - oldWidget.heading).abs() > 5) {
      _previousHeading = oldWidget.heading;

      // Handle 360-degree wrapping for smooth rotation
      double headingDiff = widget.heading - _previousHeading;

      // If difference > 180, rotate the shorter way
      if (headingDiff > 180) {
        headingDiff -= 360;
      } else if (headingDiff < -180) {
        headingDiff += 360;
      }

      _headingAnimation = Tween<double>(
        begin: _previousHeading,
        end: _previousHeading + headingDiff,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));

      _controller.forward(from: 0);
    }

    _previousPosition = widget.position;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Normalize heading to 0-360 range
        double normalizedHeading = _headingAnimation.value % 360;
        if (normalizedHeading < 0) normalizedHeading += 360;

        return BusMarker3D(
          size: widget.size,
          heading: normalizedHeading,
          isMoving: widget.isMoving,
          vehicleNumber: widget.vehicleNumber,
        );
      },
    );
  }
}
