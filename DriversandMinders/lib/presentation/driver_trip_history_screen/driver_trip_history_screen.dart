import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/date_range_selector.dart';
import './widgets/empty_state_widget.dart';
import './widgets/trip_filter_bottom_sheet.dart';
import './widgets/trip_history_card.dart';
import './widgets/trip_search_bar.dart';

class DriverTripHistoryScreen extends StatefulWidget {
  const DriverTripHistoryScreen({super.key});

  @override
  State<DriverTripHistoryScreen> createState() =>
      _DriverTripHistoryScreenState();
}

class _DriverTripHistoryScreenState extends State<DriverTripHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  // Search and filter state
  String _searchQuery = '';
  Map<String, dynamic> _activeFilters = {
    'status': 'All',
    'route': 'All Routes',
    'timePeriod': 'All Time',
    'startDate': null,
    'endDate': null,
  };

  // Data state
  List<Map<String, dynamic>> _allTrips = [];
  List<Map<String, dynamic>> _filteredTrips = [];
  bool _isLoading = false;
  bool _isRefreshing = false;

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _initializeMockData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeMockData() {
    _allTrips = [
      {
        "id": 1,
        "routeName": "Downtown Express - Route A",
        "date": "10/03/2025",
        "startTime": "07:30 AM",
        "endTime": "09:15 AM",
        "duration": "1h 45m",
        "studentCount": 28,
        "status": "completed",
        "totalDistance": "15.2 km",
        "fuelUsed": "2.3L",
        "averageSpeed": "32 km/h",
        "notes":
            "All students picked up on time. Minor traffic delay on Main Street.",
      },
      {
        "id": 2,
        "routeName": "Suburban Loop - Route B",
        "date": "10/02/2025",
        "startTime": "07:45 AM",
        "endTime": "09:30 AM",
        "duration": "1h 45m",
        "studentCount": 32,
        "status": "completed",
        "totalDistance": "18.7 km",
        "fuelUsed": "2.8L",
        "averageSpeed": "28 km/h",
        "notes": "Smooth trip with no incidents.",
      },
      {
        "id": 3,
        "routeName": "Hillside Circuit - Route C",
        "date": "10/01/2025",
        "startTime": "08:00 AM",
        "endTime": "09:20 AM",
        "duration": "1h 20m",
        "studentCount": 24,
        "status": "delayed",
        "totalDistance": "12.4 km",
        "fuelUsed": "2.1L",
        "averageSpeed": "25 km/h",
        "notes": "15-minute delay due to road construction on Oak Avenue.",
      },
      {
        "id": 4,
        "routeName": "Eastside Express - Route D",
        "date": "09/30/2025",
        "startTime": "07:15 AM",
        "endTime": "08:45 AM",
        "duration": "1h 30m",
        "studentCount": 26,
        "status": "completed",
        "totalDistance": "14.8 km",
        "fuelUsed": "2.2L",
        "averageSpeed": "35 km/h",
        "notes": "Early completion due to light traffic.",
      },
      {
        "id": 5,
        "routeName": "Central Park Route - Route A",
        "date": "09/29/2025",
        "startTime": "07:30 AM",
        "endTime": "08:00 AM",
        "duration": "30m",
        "studentCount": 15,
        "status": "cancelled",
        "totalDistance": "0 km",
        "fuelUsed": "0L",
        "averageSpeed": "0 km/h",
        "notes": "Trip cancelled due to severe weather conditions.",
      },
      {
        "id": 6,
        "routeName": "Riverside Drive - Route B",
        "date": "09/28/2025",
        "startTime": "07:45 AM",
        "endTime": "09:10 AM",
        "duration": "1h 25m",
        "studentCount": 30,
        "status": "completed",
        "totalDistance": "16.3 km",
        "fuelUsed": "2.5L",
        "averageSpeed": "30 km/h",
        "notes": "Regular trip with all students accounted for.",
      },
      {
        "id": 7,
        "routeName": "Industrial Zone - Route C",
        "date": "09/27/2025",
        "startTime": "08:00 AM",
        "endTime": "09:35 AM",
        "duration": "1h 35m",
        "studentCount": 22,
        "status": "completed",
        "totalDistance": "17.1 km",
        "fuelUsed": "2.6L",
        "averageSpeed": "29 km/h",
        "notes": "Minor detour due to accident on Industrial Blvd.",
      },
      {
        "id": 8,
        "routeName": "University District - Route D",
        "date": "09/26/2025",
        "startTime": "07:20 AM",
        "endTime": "08:50 AM",
        "duration": "1h 30m",
        "studentCount": 35,
        "status": "completed",
        "totalDistance": "13.9 km",
        "fuelUsed": "2.1L",
        "averageSpeed": "33 km/h",
        "notes": "Full capacity trip, all seats occupied.",
      },
    ];

    _applyFilters();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMoreData) {
        _loadMoreTrips();
      }
    }
  }

  Future<void> _loadMoreTrips() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _currentPage++;
      _isLoading = false;

      // Simulate no more data after page 3
      if (_currentPage >= 3) {
        _hasMoreData = false;
      }
    });
  }

  Future<void> _refreshTrips() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate API refresh
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isRefreshing = false;
      _currentPage = 1;
      _hasMoreData = true;
    });

    _applyFilters();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onFiltersApplied(Map<String, dynamic> filters) {
    setState(() {
      _activeFilters = filters;
    });
    _applyFilters();
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allTrips);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((trip) {
        final routeName = (trip['routeName'] as String).toLowerCase();
        final date = (trip['date'] as String).toLowerCase();
        final query = _searchQuery.toLowerCase();
        return routeName.contains(query) || date.contains(query);
      }).toList();
    }

    // Apply status filter
    if (_activeFilters['status'] != 'All') {
      filtered = filtered.where((trip) {
        return (trip['status'] as String).toLowerCase() ==
            (_activeFilters['status'] as String).toLowerCase();
      }).toList();
    }

    // Apply route filter
    if (_activeFilters['route'] != 'All Routes') {
      filtered = filtered.where((trip) {
        final routeName = trip['routeName'] as String;
        final filterRoute = _activeFilters['route'] as String;
        return routeName.contains(filterRoute.replaceAll('Route ', ''));
      }).toList();
    }

    // Apply date range filter
    final DateTime? startDate = _activeFilters['startDate'] as DateTime?;
    final DateTime? endDate = _activeFilters['endDate'] as DateTime?;

    if (startDate != null || endDate != null) {
      filtered = filtered.where((trip) {
        final tripDateStr = trip['date'] as String;
        final tripDateParts = tripDateStr.split('/');
        final tripDate = DateTime(
          int.parse(tripDateParts[2]),
          int.parse(tripDateParts[0]),
          int.parse(tripDateParts[1]),
        );

        if (startDate != null && tripDate.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && tripDate.isAfter(endDate)) {
          return false;
        }
        return true;
      }).toList();
    }

    setState(() {
      _filteredTrips = filtered;
    });
  }

  bool _hasActiveFilters() {
    return _activeFilters['status'] != 'All' ||
        _activeFilters['route'] != 'All Routes' ||
        _activeFilters['timePeriod'] != 'All Time' ||
        _activeFilters['startDate'] != null ||
        _activeFilters['endDate'] != null;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TripFilterBottomSheet(
        currentFilters: _activeFilters,
        onFiltersApplied: _onFiltersApplied,
      ),
    );
  }

  void _onTripCardTap(Map<String, dynamic> tripData) {
    // Navigate to trip details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening details for ${tripData['routeName']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onViewDetails(Map<String, dynamic> tripData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Trip Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Route: ${tripData['routeName']}'),
            Text('Date: ${tripData['date']}'),
            Text('Duration: ${tripData['duration']}'),
            Text('Students: ${tripData['studentCount']}'),
            Text('Distance: ${tripData['totalDistance']}'),
            Text('Fuel Used: ${tripData['fuelUsed']}'),
            if (tripData['notes'] != null) Text('Notes: ${tripData['notes']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _onShareReport(Map<String, dynamic> tripData) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing report for ${tripData['routeName']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onAddNotes(Map<String, dynamic> tripData) {
    final TextEditingController notesController = TextEditingController(
      text: tripData['notes'] as String? ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Notes'),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter trip notes...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save notes logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Notes saved successfully'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightDriverTheme,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Trip History',
          subtitle: '${_filteredTrips.length} trips found',
          actions: [
            IconButton(
              onPressed: _refreshTrips,
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: AppTheme.textOnPrimary,
                size: 24,
              ),
              tooltip: 'Refresh trips',
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            TripSearchBar(
              searchQuery: _searchQuery,
              onSearchChanged: _onSearchChanged,
              onFilterTap: _showFilterBottomSheet,
              hasActiveFilters: _hasActiveFilters(),
            ),

            // Date range selector
            DateRangeSelector(
              startDate: _activeFilters['startDate'] as DateTime?,
              endDate: _activeFilters['endDate'] as DateTime?,
              onDateRangeChanged: (start, end) {
                setState(() {
                  _activeFilters['startDate'] = start;
                  _activeFilters['endDate'] = end;
                });
                _applyFilters();
              },
            ),

            // Trip list
            Expanded(
              child: _filteredTrips.isEmpty
                  ? EmptyStateWidget(
                      title: _searchQuery.isNotEmpty || _hasActiveFilters()
                          ? 'No trips match your criteria'
                          : 'No trips found',
                      subtitle: _searchQuery.isNotEmpty || _hasActiveFilters()
                          ? 'Try adjusting your search or filter criteria'
                          : 'Your trip history will appear here once you complete some trips',
                      onActionPressed:
                          _hasActiveFilters() ? _showFilterBottomSheet : null,
                      showFiltersButton: _hasActiveFilters(),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshTrips,
                      color: AppTheme.primaryDriver,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _filteredTrips.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _filteredTrips.length) {
                            return Container(
                              padding: EdgeInsets.all(4.w),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryDriver,
                                ),
                              ),
                            );
                          }

                          final trip = _filteredTrips[index];
                          return TripHistoryCard(
                            tripData: trip,
                            onTap: () => _onTripCardTap(trip),
                            onViewDetails: () => _onViewDetails(trip),
                            onShareReport: () => _onShareReport(trip),
                            onAddNotes: () => _onAddNotes(trip),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomBar(
          currentIndex: 2, // History tab
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushNamed(context, '/driver-start-shift-screen');
                break;
              case 1:
                Navigator.pushNamed(context, '/driver-active-trip-screen');
                break;
              case 2:
                // Already on history screen
                break;
            }
          },
        ),
      ),
    );
  }
}
