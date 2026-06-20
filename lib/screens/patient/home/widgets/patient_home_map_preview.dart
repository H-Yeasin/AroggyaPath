import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:arogya_path3/core/location/utils/cached_map_tile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PatientHomeMapPreview extends StatelessWidget {
  final MapController mapController;
  final LatLng currentPosition;
  final bool isLoadingLocation;
  final bool locationPermissionGranted;
  final List<Marker> markers;
  final List<Polyline> polylines;
  final List<Polyline> directionPolylines;
  final VoidCallback onOpenMap;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final Future<void> Function() onLocateMe;

  const PatientHomeMapPreview({
    super.key,
    required this.mapController,
    required this.currentPosition,
    required this.isLoadingLocation,
    required this.locationPermissionGranted,
    required this.markers,
    required this.polylines,
    required this.directionPolylines,
    required this.onOpenMap,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onLocateMe,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return GestureDetector(
      onTap: onOpenMap,
      child: Container(
        height: 250,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: isLoadingLocation
              ? Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text(
                          'Loading map...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: currentPosition,
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.aroggyapath.app',
                          tileProvider: CachedMapTileProvider(),
                        ),
                        MarkerLayer(markers: markers),
                        PolylineLayer(
                          polylines: [
                            ...polylines,
                            ...directionPolylines,
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _MapLegend(headingColor: colors.heading),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Column(
                        children: [
                          _MapIconButton(
                            icon: Icons.add,
                            color: colors.primaryDark,
                            onPressed: onZoomIn,
                          ),
                          const SizedBox(height: 8),
                          _MapIconButton(
                            icon: Icons.remove,
                            color: colors.primaryDark,
                            onPressed: onZoomOut,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: _MapIconButton(
                        icon: Icons.my_location,
                        color: locationPermissionGranted
                            ? colors.primaryDark
                            : Colors.grey,
                        onPressed: onLocateMe,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _MapIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 24),
        onPressed: onPressed,
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  final Color headingColor;

  const _MapLegend({required this.headingColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distance',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: headingColor,
            ),
          ),
          const SizedBox(height: 4),
          const _MapLegendItem(color: Colors.green, label: '< 5 km'),
          const _MapLegendItem(color: Colors.lightGreen, label: '5-10 km'),
          const _MapLegendItem(color: Colors.orange, label: '10-15 km'),
          const _MapLegendItem(color: Colors.red, label: '> 15 km'),
        ],
      ),
    );
  }
}

class _MapLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _MapLegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
