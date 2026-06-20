import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:arogya_path3/core/location/utils/cached_map_tile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FullMapScreen extends StatefulWidget {
  final LatLng currentPosition;
  final List<Marker> markers;
  final List<Polyline> polylines;

  const FullMapScreen({
    super.key,
    required this.currentPosition,
    required this.markers,
    required this.polylines,
  });

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Full Screen Map â€” free OpenStreetMap tiles via flutter_map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.currentPosition,
                initialZoom: 13,
                onMapReady: () {
                  // Map is ready â€” no action needed.
                },
              ),
              children: [
                // OpenStreetMap tile layer (free, no API key)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.aroggyapath.app',
                  tileProvider: CachedMapTileProvider(),
                ),
                // Doctor + user markers
                MarkerLayer(markers: widget.markers),
                // Polylines (straight lines + direction routes)
                PolylineLayer(polylines: widget.polylines),
              ],
            ),

            // Close Button
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close,
                      color: AppColors.patientPrimaryDark, size: 24),
                ),
              ),
            ),

            // Map Legend
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Distance',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.heading)),
                    const SizedBox(height: 8),
                    _buildLegendItem(Colors.green, '< 5 km'),
                    _buildLegendItem(Colors.lightGreen, '5-10 km'),
                    _buildLegendItem(Colors.orange, '10-15 km'),
                    _buildLegendItem(Colors.red, '> 15 km'),
                  ],
                ),
              ),
            ),

            // Zoom Controls
            Positioned(
              bottom: 80,
              left: 16,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add,
                          color: AppColors.patientPrimaryDark, size: 28),
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                            _mapController.camera.center, currentZoom + 1);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove,
                          color: AppColors.patientPrimaryDark, size: 28),
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                            _mapController.camera.center, currentZoom - 1);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Recenter Button
            Positioned(
              bottom: 80,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.my_location,
                      color: AppColors.patientPrimaryDark, size: 28),
                  onPressed: () {
                    _mapController.move(widget.currentPosition, 14);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
