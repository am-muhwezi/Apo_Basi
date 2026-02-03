import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import '../../theme/app_theme.dart';

/// Location Timestamp Widget
///
/// Displays "last updated" timestamp with auto-refresh.
/// Shows relative time (e.g., "2 minutes ago")
class LocationTimestampWidget extends StatefulWidget {
  final DateTime? timestamp;
  final IconData icon;
  final bool showIcon;
  final TextStyle? textStyle;

  const LocationTimestampWidget({
    Key? key,
    required this.timestamp,
    this.icon = Icons.access_time,
    this.showIcon = true,
    this.textStyle,
  }) : super(key: key);

  @override
  State<LocationTimestampWidget> createState() =>
      _LocationTimestampWidgetState();
}

class _LocationTimestampWidgetState extends State<LocationTimestampWidget> {
  Timer? _updateTimer;
  String _displayText = '';

  @override
  void initState() {
    super.initState();
    _updateDisplayText();
    _startUpdateTimer();
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateDisplayText();
      }
    });
  }

  void _updateDisplayText() {
    setState(() {
      _displayText = _formatTimestamp();
    });
  }

  String _formatTimestamp() {
    if (widget.timestamp == null) {
      return 'No updates yet';
    }

    final age = DateTime.now().difference(widget.timestamp!);

    if (age.inSeconds < 5) {
      return 'Just now';
    } else if (age.inSeconds < 60) {
      return '${age.inSeconds} seconds ago';
    } else if (age.inMinutes == 1) {
      return '1 minute ago';
    } else if (age.inMinutes < 60) {
      return '${age.inMinutes} minutes ago';
    } else if (age.inHours == 1) {
      return '1 hour ago';
    } else if (age.inHours < 24) {
      return '${age.inHours} hours ago';
    } else {
      return '${age.inDays} days ago';
    }
  }

  Color _getTextColor() {
    if (widget.timestamp == null) {
      return Colors.grey;
    }

    final age = DateTime.now().difference(widget.timestamp!);

    if (age.inSeconds < 30) {
      return Colors.green.shade700;
    } else if (age.inMinutes < 2) {
      return Colors.blue.shade700;
    } else if (age.inMinutes < 5) {
      return Colors.orange.shade700;
    } else {
      return Colors.red.shade700;
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTextColor();
    final textStyle = widget.textStyle ??
        Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcon) ...[
          Icon(
            widget.icon,
            size: 14,
            color: color,
          ),
          SizedBox(width: 1.w),
        ],
        Text(
          _displayText,
          style: textStyle,
        ),
      ],
    );
  }
}

/// Compact Location Timestamp
///
/// Minimal version showing just the time text
class CompactLocationTimestamp extends StatelessWidget {
  final DateTime? timestamp;

  const CompactLocationTimestamp({
    Key? key,
    required this.timestamp,
  }) : super(key: key);

  String _formatCompact() {
    if (timestamp == null) return 'N/A';

    final age = DateTime.now().difference(timestamp!);

    if (age.inSeconds < 5) {
      return 'Now';
    } else if (age.inSeconds < 60) {
      return '${age.inSeconds}s';
    } else if (age.inMinutes < 60) {
      return '${age.inMinutes}m';
    } else {
      return '${age.inHours}h';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatCompact(),
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}
