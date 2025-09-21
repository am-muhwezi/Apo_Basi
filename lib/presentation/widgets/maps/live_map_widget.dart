import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveMapWidget extends StatefulWidget {
  final List<dynamic> buses;
  final bool showControls;
  final Function(LatLng)? onTap;
  final double? height;

  const LiveMapWidget({
    super.key,
    required this.buses,
    this.showControls = true,
    this.onTap,
    this.height,
  });

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // Default location (can be updated based on user's location)
  static const LatLng _defaultLocation = LatLng(0.3476, 32.5825); // Kampala, Uganda

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  @override
  void didUpdateWidget(LiveMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buses != widget.buses) {
      _updateMarkers();
    }
  }

  void _updateMarkers() {
    Set<Marker> markers = {};
    
    // Add bus markers
    for (int i = 0; i < widget.buses.length; i++) {
      final bus = widget.buses[i];
      // Mock bus location for demo
      final location = LatLng(
        _defaultLocation.latitude + (i * 0.01),
        _defaultLocation.longitude + (i * 0.01),
      );
      
      markers.add(
        Marker(
          markerId: MarkerId('bus_$i'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Bus ${i + 1}',
            snippet: 'Active • 5 students on board',
          ),
          onTap: () {
            _showBusBottomSheet(bus);
          },
        ),
      );
    }

    // Add sample route polyline
    if (widget.buses.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('sample_route'),
          points: [
            _defaultLocation,
            LatLng(_defaultLocation.latitude + 0.02, _defaultLocation.longitude + 0.02),
            LatLng(_defaultLocation.latitude + 0.01, _defaultLocation.longitude + 0.03),
          ],
          color: Theme.of(context).colorScheme.primary,
          width: 3,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _showBusBottomSheet(dynamic bus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Bus Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard('Bus Number', 'BUS-001'),
                    _buildInfoCard('Driver', 'John Doe'),
                    _buildInfoCard('Status', 'Active'),
                    _buildInfoCard('Students on Board', '12'),
                    _buildInfoCard('Next Stop', 'Central Park Stop'),
                    _buildInfoCard('ETA', '5 minutes'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Call driver
                            },
                            icon: const Icon(Icons.phone),
                            label: const Text('Call Driver'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Send message
                            },
                            icon: const Icon(Icons.message),
                            label: const Text('Message'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
              initialCameraPosition: const CameraPosition(
                target: _defaultLocation,
                zoom: 14.0,
              ),
              markers: _markers,
              polylines: _polylines,
              onTap: widget.onTap,
              myLocationEnabled: true,
              myLocationButtonEnabled: widget.showControls,
              zoomControlsEnabled: widget.showControls,
              mapToolbarEnabled: widget.showControls,
              compassEnabled: widget.showControls,
            ),
            if (widget.buses.isEmpty)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 48,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No active buses',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bus locations will appear here when available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            // Map controls overlay
            if (widget.showControls)
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'refresh_map',
                      onPressed: () {
                        _updateMarkers();
                      },
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.refresh,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'center_map',
                      onPressed: () {
                        _controller?.animateCamera(
                          CameraUpdate.newCameraPosition(
                            const CameraPosition(
                              target: _defaultLocation,
                              zoom: 14.0,
                            ),
                          ),
                        );
                      },
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.my_location,
                        color: Theme.of(context).colorScheme.primary,
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
}