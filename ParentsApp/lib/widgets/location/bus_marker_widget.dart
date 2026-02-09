import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';

/// Bus Marker Widget
///
/// Customizable bus marker for map display.
/// Can show bus number, status, and includes animation support.
class BusMarkerWidget extends StatelessWidget {
  final String busNumber;
  final bool isActive;
  final Color? color;
  final double scale;
  final bool showLabel;

  const BusMarkerWidget({
    Key? key,
    required this.busNumber,
    this.isActive = true,
    this.color,
    this.scale = 1.0,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final markerColor = color ??
        (isActive
            ? Theme.of(context).colorScheme.secondary
            : Colors.grey.shade400);

    return Transform.scale(
      scale: scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 0.5.h,
              ),
              decoration: BoxDecoration(
                color: markerColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 12.sp,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    busNumber,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
          Icon(
            Icons.location_on,
            color: markerColor,
            size: 50,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Animated Bus Marker Widget
///
/// Bus marker with pulse animation for real-time updates
class AnimatedBusMarkerWidget extends StatefulWidget {
  final String busNumber;
  final bool isActive;
  final Color? color;
  final bool showLabel;

  const AnimatedBusMarkerWidget({
    Key? key,
    required this.busNumber,
    this.isActive = true,
    this.color,
    this.showLabel = true,
  }) : super(key: key);

  @override
  State<AnimatedBusMarkerWidget> createState() =>
      _AnimatedBusMarkerWidgetState();
}

class _AnimatedBusMarkerWidgetState extends State<AnimatedBusMarkerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Pulse animation
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return BusMarkerWidget(
          busNumber: widget.busNumber,
          isActive: widget.isActive,
          color: widget.color,
          scale: _scaleAnimation.value,
          showLabel: widget.showLabel,
        );
      },
    );
  }
}
