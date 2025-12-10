import 'package:flutter/material.dart';
import 'dart:async';

/// Connection Indicator Dot
///
/// Shows a pulsing dot to indicate connection status.
/// Colors: Green (connected), Yellow (connecting), Red (disconnected)
class ConnectionIndicatorDot extends StatefulWidget {
  final bool isConnected;
  final bool isConnecting;
  final double size;
  final bool animate;

  const ConnectionIndicatorDot({
    Key? key,
    required this.isConnected,
    this.isConnecting = false,
    this.size = 12,
    this.animate = true,
  }) : super(key: key);

  @override
  State<ConnectionIndicatorDot> createState() => _ConnectionIndicatorDotState();
}

class _ConnectionIndicatorDotState extends State<ConnectionIndicatorDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ConnectionIndicatorDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.value = 1.0;
      }
    }
  }

  Color _getColor() {
    if (widget.isConnecting) {
      return Colors.amber;
    } else if (widget.isConnected) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _getColor(),
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _getColor().withOpacity(_pulseAnimation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getColor().withOpacity(0.5 * _pulseAnimation.value),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
