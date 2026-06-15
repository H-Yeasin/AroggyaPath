import 'package:arogya_path3/models/doctor_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MarkerFactory {
  // Singleton pattern
  static final MarkerFactory _instance = MarkerFactory._internal();
  factory MarkerFactory() => _instance;
  MarkerFactory._internal();

  /// Create a marker for the user's current location.
  Marker createUserMarker(LatLng position) {
    return Marker(
      point: position,
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () {
          // Could show a snackbar — caller provides context if needed.
        },
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_pin_circle, color: Colors.blue, size: 36),
          ],
        ),
      ),
    );
  }

  /// Create a marker for a doctor with a custom icon, distance label,
  /// and tap handler.
  Marker createCustomDoctorMarker({
    required Doctor doctor,
    required double distanceKm,
    required VoidCallback onTap,
  }) {
    final LatLng position =
        (doctor.latitude != null && doctor.longitude != null)
            ? LatLng(doctor.latitude!, doctor.longitude!)
            : const LatLng(0, 0);

    return Marker(
      point: position,
      width: 50,
      height: 60,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Doctor icon from asset, with fallback
            Image.asset(
              'assets/icons/doclocation.png',
              width: 40,
              height: 40,
              errorBuilder: (_, __, ___) => Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_hospital,
                    color: Colors.white, size: 28),
              ),
            ),
            // Distance label
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Text(
                '${distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Create a generic selection marker.
  Marker createSelectedMarker(LatLng position) {
    return Marker(
      point: position,
      width: 40,
      height: 40,
      child: const Icon(Icons.location_on, color: Colors.blue, size: 36),
    );
  }
}
