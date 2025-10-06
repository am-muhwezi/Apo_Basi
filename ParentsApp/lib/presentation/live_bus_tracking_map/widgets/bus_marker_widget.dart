import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BusMarkerWidget extends StatefulWidget {
  final double rotation;
  final bool isMoving;

  const BusMarkerWidget({
    Key? key,
    required this.rotation,
    required this.isMoving,
  }) : super(key: key);

  @override
  State<BusMarkerWidget> createState() => _BusMarkerWidgetState();
}

class _BusMarkerWidgetState extends State<BusMarkerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isMoving) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BusMarkerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMoving != oldWidget.isMoving) {
      if (widget.isMoving) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isMoving ? _pulseAnimation.value : 1.0,
          child: Transform.rotate(
            angle: widget.rotation,
            child: Container(
              width: 15.w,
              height: 8.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Bus body
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // Bus windows
                  Positioned(
                    top: 1.h,
                    left: 2.w,
                    right: 2.w,
                    child: Row(
                      children: List.generate(
                        3,
                        (index) => Expanded(
                          child: Container(
                            height: 2.h,
                            margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bus icon
                  Center(
                    child: CustomIconWidget(
                      iconName: 'directions_bus',
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  // Movement indicator
                  if (widget.isMoving)
                    Positioned(
                      bottom: 0.5.h,
                      right: 1.w,
                      child: Container(
                        width: 2.w,
                        height: 1.h,
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
