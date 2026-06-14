import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../models/doctor_model.dart';

class MarkerFactory {
  // Singleton pattern
  static final MarkerFactory _instance = MarkerFactory._internal();
  factory MarkerFactory() => _instance;
  MarkerFactory._internal();

  // Cache for custom markers to avoid re-downloading/processing
  final Map<String, BitmapDescriptor> _markerCache = {};

  /// Create a marker for the user's location
  Marker createUserMarker(LatLng position) {
    return Marker(
      markerId: const MarkerId('user_location'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(
        title: 'Your Location',
        snippet: 'You are here',
      ),
    );
  }

  /// Create a marker for a doctor
  Future<Marker> createCustomDoctorMarker({
    required Doctor doctor,
    required double distanceKm,
    required VoidCallback onTap,
  }) async {
    LatLng position;
    if (doctor.latitude != null && doctor.longitude != null) {
      position = LatLng(doctor.latitude!, doctor.longitude!);
    } else {
      position = const LatLng(0, 0);
    }

    BitmapDescriptor icon;

    // Check cache first
    if (_markerCache.containsKey('static_doctor_icon')) {
      icon = _markerCache['static_doctor_icon']!;
    } else {
      try {
        // Resize icon to 50px width
        final Uint8List markerIcon = await _getBytesFromAsset(
          'assets/icons/doclocation.png',
          50,
        );
        icon = BitmapDescriptor.bytes(markerIcon);
        // Cache it
        _markerCache['static_doctor_icon'] = icon;
      } catch (e) {
        debugPrint('Error loading static doctor icon: $e');
        icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      }
    }

    return Marker(
      markerId: MarkerId(doctor.id),
      position: position,
      infoWindow: InfoWindow(
        title: doctor.fullName,
        snippet:
            '${doctor.specialty} - ${distanceKm.toStringAsFixed(1)} km away',
      ),
      icon: icon,
      onTap: onTap,
    );
  }

  // Helper to resize asset image
  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  /// Create a generic marker for selection
  Marker createSelectedMarker(LatLng position) {
    return Marker(
      markerId: const MarkerId('selected'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
  }
}
