import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/driver_location_service.dart';

/// Location Tracking Toggle Widget
///
/// Allows drivers to enable/disable location sharing with a toggle switch.
/// Shows active tracking indicator and stats.
class LocationTrackingToggle extends StatefulWidget {
  final Function(bool)? onToggle;
  final bool showStats;

  const LocationTrackingToggle({
    Key? key,
    this.onToggle,
    this.showStats = true,
  }) : super(key: key);

  @override
  State<LocationTrackingToggle> createState() => _LocationTrackingToggleState();
}

class _LocationTrackingToggleState extends State<LocationTrackingToggle> {
  final DriverLocationService _locationService = DriverLocationService();
  bool _isTracking = false;
  bool _isLoading = false;
  LocationStats? _stats;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _listenToStreams();
  }

  Future<void> _initializeService() async {
    await _locationService.initialize();
    setState(() {
      _isTracking = _locationService.isTracking;
    });
  }

  void _listenToStreams() {
    _locationService.trackingStateStream.listen((isTracking) {
      if (mounted) {
        setState(() {
          _isTracking = isTracking;
        });
      }
    });

    _locationService.statsStream.listen((stats) {
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    });

    _locationService.errorStream.listen((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Future<void> _handleToggle(bool value) async {
    setState(() {
      _isLoading = true;
    });

    bool success;
    if (value) {
      success = await _locationService.startTracking();
    } else {
      await _locationService.stopTracking();
      success = true;
    }

    setState(() {
      _isLoading = false;
      if (success) {
        _isTracking = value;
      }
    });

    if (success && widget.onToggle != null) {
      widget.onToggle!(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: _isTracking
                      ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on,
                  color: _isTracking
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.grey.shade600,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Sharing',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      _isTracking
                          ? 'Parents can track your bus'
                          : 'Location sharing is off',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                )
              else
                Switch(
                  value: _isTracking,
                  onChanged: _handleToggle,
                  activeColor: Theme.of(context).colorScheme.secondary,
                ),
            ],
          ),
          if (_isTracking && widget.showStats && _stats != null) ...[
            SizedBox(height: 2.h),
            Divider(height: 1, color: Colors.grey.shade200),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.send,
                  label: 'Updates',
                  value: '${_stats!.totalUpdatesSent}',
                  color: Theme.of(context).colorScheme.secondary,
                ),
                _buildStatItem(
                  icon: Icons.access_time,
                  label: 'Last Update',
                  value: _stats!.lastUpdateText,
                  color: Colors.blue,
                ),
                _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Success',
                  value: '${_stats!.successRate.toStringAsFixed(0)}%',
                  color: Colors.green,
                ),
              ],
            ),
            if (_stats!.queuedUpdates > 0) ...[
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_queue,
                      color: Colors.orange.shade700,
                      size: 18,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        '${_stats!.queuedUpdates} updates queued (will retry)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
