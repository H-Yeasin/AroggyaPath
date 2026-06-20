import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current position with high accuracy, with last-known fallback
  Future<Position> getCurrentPosition() async {
    // Try last known position first for instant response
    Position? lastKnown;
    try {
      lastKnown = await Geolocator.getLastKnownPosition();
    } catch (_) {
      // Best-effort optimization
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      if (lastKnown != null) {
        debugPrint(
            'Live position timed out, falling back to last-known position');
        return lastKnown;
      }
      rethrow;
    }
  }

  /// Get address from LatLng
  Future<String> getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}';
      }
      return 'Address not found';
    } catch (e) {
      debugPrint('Error getting address: $e');
      return 'Error retrieving address';
    }
  }

  /// Calculate distance between two points in km (Haversine formula)
  double calculateDistanceInKm(LatLng from, LatLng to) {
    const double earthRadius = 6371; // km

    double lat1 = from.latitude * math.pi / 180;
    double lat2 = to.latitude * math.pi / 180;
    double lon1 = from.longitude * math.pi / 180;
    double lon2 = to.longitude * math.pi / 180;

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }
}
