import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/bus_tracking/bus_tracking_bloc.dart';
import '../../widgets/maps/live_map_widget.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/dashboard/bus_status_card.dart';
import '../../widgets/dashboard/student_card.dart';
import '../../widgets/dashboard/quick_actions.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() {
    context.read<BusTrackingBloc>().add(LoadBusTrackingData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome to ${AppConstants.appName}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: BlocBuilder<BusTrackingBloc, BusTrackingState>(
        builder: (context, state) {
          if (state is BusTrackingLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is BusTrackingError) {
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
                    'Error loading data',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadDashboardData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is BusTrackingLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                _loadDashboardData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Message
                    _buildWelcomeSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    const QuickActions(),
                    
                    const SizedBox(height: 24),
                    
                    // Students Section
                    _buildStudentsSection(state.students),
                    
                    const SizedBox(height: 24),
                    
                    // Live Map Section
                    _buildLiveMapSection(state.buses),
                    
                    const SizedBox(height: 24),
                    
                    // Bus Status Section
                    _buildBusStatusSection(state.buses),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.waving_hand,
                size: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your children\\'s bus in real-time',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsSection(List<dynamic> students) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Children',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        if (students.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.family_restroom,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No children added yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your children to start tracking their bus',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to add student screen
                    },
                    child: const Text('Add Child'),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: students.length,
              itemBuilder: (context, index) {
                return StudentCard(student: students[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLiveMapSection(List<dynamic> buses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Live Bus Tracking',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to full map screen
              },
              child: const Text('View Full Map'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 250,
            child: LiveMapWidget(
              buses: buses,
              showControls: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusStatusSection(List<dynamic> buses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bus Status',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        if (buses.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
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
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: buses.length,
            itemBuilder: (context, index) {
              return BusStatusCard(bus: buses[index]);
            },
          ),
      ],
    );
  }
}

// Placeholder BLoC classes
abstract class BusTrackingEvent {}

class LoadBusTrackingData extends BusTrackingEvent {}

abstract class BusTrackingState {}

class BusTrackingInitial extends BusTrackingState {}

class BusTrackingLoading extends BusTrackingState {}

class BusTrackingLoaded extends BusTrackingState {
  final List<dynamic> buses;
  final List<dynamic> students;

  BusTrackingLoaded({required this.buses, required this.students});
}

class BusTrackingError extends BusTrackingState {
  final String message;
  BusTrackingError(this.message);
}