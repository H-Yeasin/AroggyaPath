import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class DirectionsService {
  /// Free OSRM (OpenStreetMap Routing Machine) public API — no key required.
  /// Production note: the public demo server is rate-limited. For production
  /// use, host your own OSRM instance or use a sponsored tile service.
  static const String _baseUrl = 'https://router.project-osrm.org';

  /// Get driving directions between two points using OSRM.
  /// Returns decoded polyline points, distance text, and duration text.
  Future<Map<String, dynamic>?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      // OSRM expects: lng,lat;lng,lat
      final String url =
          '$_baseUrl/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson&steps=true';

      debugPrint('Fetching directions from OSRM...');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];

          // Parse GeoJSON LineString coordinates into LatLng list
          final List<LatLng> polylinePoints = [];
          if (geometry['type'] == 'LineString') {
            for (final coord in geometry['coordinates']) {
              // GeoJSON coords are [longitude, latitude]
              polylinePoints.add(LatLng(
                (coord[1] as num).toDouble(),
                (coord[0] as num).toDouble(),
              ));
            }
          }

          // Extract step-by-step directions (optional, for UI)
          final List<Map<String, dynamic>> steps = [];
          if (route['legs'] != null && route['legs'].isNotEmpty) {
            final leg = route['legs'][0];
            if (leg['steps'] != null) {
              for (final step in leg['steps']) {
                steps.add({
                  'instruction': step['name'] ?? '',
                  'distance': step['distance'] ?? 0,
                  'duration': step['duration'] ?? 0,
                });
              }
            }
          }

          // Convert meters to human-readable text
          final double distanceMeters =
              (route['distance'] as num?)?.toDouble() ?? 0;
          final double durationSeconds =
              (route['duration'] as num?)?.toDouble() ?? 0;

          return {
            'polylinePoints': polylinePoints,
            'distance': _formatDistance(distanceMeters),
            'duration': _formatDuration(durationSeconds),
            'steps': steps,
          };
        } else {
          debugPrint('OSRM API code: ${data['code']}');
          return null;
        }
      } else {
        debugPrint('OSRM HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching OSRM directions: $e');
      return null;
    }
  }

  /// Format distance in meters to human-readable text.
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Format duration in seconds to human-readable text.
  String _formatDuration(double seconds) {
    if (seconds < 60) {
      return '${seconds.round()} sec';
    } else if (seconds < 3600) {
      return '${(seconds / 60).round()} min';
    } else {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).round();
      return '$hours hr $minutes min';
    }
  }
}
