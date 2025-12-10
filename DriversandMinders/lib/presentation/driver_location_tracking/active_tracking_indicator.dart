import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';

/// Active Tracking Indicator
///
/// Persistent indicator shown when location tracking is active.
/// Shows pulsing animation and real-time status.
class ActiveTrackingIndicator extends StatefulWidget {
  final bool isActive;
  final DateTime? lastUpdateTime;
  final int? updateCount;
  final VoidCallback? onTap;

  const ActiveTrackingIndicator({
    Key? key,
    required this.isActive,
    this.lastUpdateTime,
    this.updateCount,
    this.onTap,
  }) : super(key: key);

  @override
  State<ActiveTrackingIndicator> createState() => _ActiveTrackingIndicatorState();
}

class _ActiveTrackingIndicatorState extends State<ActiveTrackingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _updateTimer;
  String _timeSinceUpdate = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _startUpdateTimer();
  }

  void _initializeAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.lastUpdateTime != null) {
        setState(() {
          _timeSinceUpdate = _formatTimeSince(widget.lastUpdateTime!);
        });
      }
    });
  }

  String _formatTimeSince(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 5) {
      return 'Just now';
    } else if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.secondary
                              .withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(width: 2.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Location Tracking Active',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.lastUpdateTime != null)
                  Text(
                    _timeSinceUpdate,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            if (widget.updateCount != null) ...[
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.updateCount}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
