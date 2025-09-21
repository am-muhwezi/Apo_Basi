import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/bus_tracking/bus_tracking_bloc.dart';
import '../../widgets/maps/live_map_widget.dart';

class BusTrackingScreen extends StatefulWidget {
  final String? busId;

  const BusTrackingScreen({
    super.key,
    this.busId,
  });

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  bool _isMapFullscreen = false;

  @override
  void initState() {
    super.initState();
    if (widget.busId != null) {
      context.read<BusTrackingBloc>().add(
            StartBusTracking(busId: widget.busId!),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isMapFullscreen
          ? null
          : AppBar(
              title: const Text('Bus Tracking'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () {
                    setState(() {
                      _isMapFullscreen = true;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<BusTrackingBloc>().add(RefreshBusData());
                  },
                ),
              ],
            ),
      body: BlocBuilder<BusTrackingBloc, BusTrackingState>(
        builder: (context, state) {
          if (state is BusTrackingLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is BusTrackingError) {
            return _buildErrorState(state.message);
          }

          if (state is BusTrackingLoaded) {
            return _buildLoadedState(state);
          }

          return const Center(
            child: Text('No data available'),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load bus tracking',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<BusTrackingBloc>().add(LoadBusTrackingData());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(BusTrackingLoaded state) {
    if (_isMapFullscreen) {
      return _buildFullscreenMap(state.buses);
    }

    return Column(
      children: [
        // Map Section
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: LiveMapWidget(
                buses: state.buses,
                showControls: true,
              ),
            ),
          ),
        ),
        
        // Bus Information Section
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: _buildBusInfoSection(state.buses),
          ),
        ),
      ],
    );
  }

  Widget _buildFullscreenMap(List<dynamic> buses) {
    return Stack(
      children: [
        LiveMapWidget(
          buses: buses,
          showControls: true,
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: () {
              setState(() {
                _isMapFullscreen = false;
              });
            },
            child: Icon(
              Icons.fullscreen_exit,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusInfoSection(List<dynamic> buses) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            'Active Buses',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Bus List
          if (buses.isEmpty)
            _buildNoBusesState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: buses.length,
              itemBuilder: (context, index) {
                return _buildBusInfoCard(buses[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNoBusesState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No active buses',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Bus tracking will appear here when available',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBusInfoCard(dynamic bus) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus ${bus['plateNumber'] ?? 'Unknown'}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        'Route: Main Street - School',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                _buildStatusIndicator(bus['status'] ?? 'unknown'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Real-time Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoColumn(
                    icon: Icons.people,
                    label: 'Students',
                    value: '${bus['currentStudents'] ?? 0}/${bus['capacity'] ?? 0}',
                  ),
                  _buildInfoColumn(
                    icon: Icons.speed,
                    label: 'Speed',
                    value: '45 km/h',
                  ),
                  _buildInfoColumn(
                    icon: Icons.schedule,
                    label: 'ETA',
                    value: '8 min',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Call driver
                      _showCallDriverDialog();
                    },
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call Driver'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Send notification
                      _showNotificationDialog();
                    },
                    icon: const Icon(Icons.notifications, size: 18),
                    label: const Text('Notify Me'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color color;
    String displayStatus;
    
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        displayStatus = 'Active';
        break;
      case 'inactive':
        color = Colors.grey;
        displayStatus = 'Inactive';
        break;
      case 'emergency':
        color = Colors.red;
        displayStatus = 'Emergency';
        break;
      default:
        color = Colors.orange;
        displayStatus = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 4),
          Text(
            displayStatus,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
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

  void _showCallDriverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Driver'),
        content: const Text('Would you like to call the bus driver?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual phone call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling driver...')),
              );
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bus Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Arrival notifications'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Departure notifications'),
              value: false,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Emergency alerts'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification preferences updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}