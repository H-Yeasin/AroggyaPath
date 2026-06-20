import 'dart:async';

import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';

class LocationPickerScreen extends StatefulWidget {
  /// Pre-existing location to center the map on. Falls back to GPS or Dhaka.
  final LatLng? initialPosition;

  const LocationPickerScreen({super.key, this.initialPosition});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  LatLng _selectedPosition = const LatLng(23.8103, 90.4125); // Dhaka default
  String _address = 'Fetching addressâ€¦';
  bool _isLoadingAddress = true;
  bool _isLoadingInitial = true;
  bool _isLocating = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializePosition();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializePosition() async {
    // 1. Use provided initial position if available
    if (widget.initialPosition != null) {
      _selectedPosition = widget.initialPosition!;
      setState(() => _isLoadingInitial = false);
      _fetchAddress(_selectedPosition);
      return;
    }

    // 2. Try GPS
    try {
      final pos = await _locationService.getCurrentPosition();
      _selectedPosition = LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      // Keep default Dhaka
    }

    if (mounted) {
      setState(() => _isLoadingInitial = false);
      _fetchAddress(_selectedPosition);
    }
  }

  void _onMapMoved(LatLng center) {
    // Update the selected position
    _selectedPosition = center;

    // Debounce â€” wait 500ms after user stops panning before reverse geocoding
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoadingAddress = true);
        _fetchAddress(_selectedPosition);
      }
    });
  }

  Future<void> _fetchAddress(LatLng pos) async {
    try {
      final address = await _locationService.getAddressFromLatLng(pos);
      if (mounted) {
        setState(() {
          _address = address;
          _isLoadingAddress = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _address = 'Unable to fetch address';
          _isLoadingAddress = false;
        });
      }
    }
  }

  Future<void> _locateMe() async {
    if (_isLocating) return;

    setState(() => _isLocating = true);

    try {
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enable location services.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: Geolocator.openLocationSettings,
              ),
            ),
          );
        }
        return;
      }

      var permission = await _locationService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _locationService.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is needed to locate you.'),
            ),
          );
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Location permission is blocked. Enable it in app settings.',
              ),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: Geolocator.openAppSettings,
              ),
            ),
          );
        }
        return;
      }

      final pos = await _locationService.getCurrentPosition();
      final location = LatLng(pos.latitude, pos.longitude);
      _debounceTimer?.cancel();

      if (mounted) {
        setState(() {
          _selectedPosition = location;
          _isLoadingAddress = true;
        });
        _mapController.move(location, 16);
        await _fetchAddress(location);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get your current location.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _confirmLocation() {
    Navigator.pop(context, {
      'latitude': _selectedPosition.latitude,
      'longitude': _selectedPosition.longitude,
      'address': _address,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Set Practice Location',
          style: TextStyle(color: colors.heading, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.heading),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingInitial
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // â”€â”€ Map â”€â”€
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedPosition,
                    initialZoom: 15,
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd ||
                          event is MapEventFlingAnimationEnd) {
                        _onMapMoved(_mapController.camera.center);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.aroggyapath.app',
                    ),
                  ],
                ),

                // â”€â”€ Fixed crosshair in center â”€â”€
                Center(
                  child: IgnorePointer(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: colors.primary,
                        size: 32,
                      ),
                    ),
                  ),
                ),

                // â”€â”€ Hint text at top â”€â”€
                Positioned(
                  top: 12,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Drag the map to place the pin on your practice location',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // â”€â”€ Locate me button â”€â”€
                Positioned(
                  right: 16,
                  bottom: 190,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 4,
                    child: IconButton(
                      tooltip: 'Locate me',
                      onPressed: _isLocating ? null : _locateMe,
                      icon: _isLocating
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: colors.primary,
                              ),
                            )
                          : Icon(
                              Icons.my_location,
                              color: colors.primary,
                              size: 26,
                            ),
                    ),
                  ),
                ),

                // â”€â”€ Bottom panel â”€â”€
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Address
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on,
                                  color: colors.primary, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _isLoadingAddress
                                    ? const Text('Looking up address...',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 14))
                                    : Text(
                                        _address,
                                        style: TextStyle(
                                          color: colors.heading,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Coordinates
                          Text(
                            '${_selectedPosition.latitude.toStringAsFixed(6)}, '
                            '${_selectedPosition.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          // Confirm button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _confirmLocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Confirm Location',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
