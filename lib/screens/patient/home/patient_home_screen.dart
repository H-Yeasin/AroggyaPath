import 'dart:async';

import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:arogya_path3/core/utils/marker_factory.dart';
import 'package:arogya_path3/screens/patient/emergency/emergency_contact_home.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../models/doctor_model.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/doctor_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/directions_service.dart';
import '../../../services/location_service.dart';
import '../doctor/book_appointment_screen.dart';
import '../doctor/doctor_detail_screen.dart';
import 'full_map_screen.dart';
import 'search_doctor_screen.dart';
import 'see_all_doctors_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final LocationService _locationService = LocationService();
  final MarkerFactory _markerFactory = MarkerFactory();
  final DirectionsService _directionsService = DirectionsService();

  final MapController _mapController = MapController();

  LatLng _currentPosition = const LatLng(23.8103, 90.4125);
  bool _isLoadingLocation = true;
  bool _locationPermissionGranted = false;
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  final List<Polyline> _directionPolylines = [];

  Timer? _refreshTimer;
  bool _isScreenInitialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isScreenInitialized) {
        _isScreenInitialized = true;
        _initializeScreen();
        _startAutoRefresh();
      }
    });
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _onRefresh();
      }
    });
  }

  Future<void> _initializeScreen() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final doctorProvider =
          Provider.of<DoctorProvider>(context, listen: false);
      final appointmentProvider =
          Provider.of<AppointmentProvider>(context, listen: false);

      await Future.wait([
        if (userProvider.user == null) userProvider.loadFromCache(),
        if (appointmentProvider.appointments.isEmpty)
          appointmentProvider.loadFromCache(),
        if (doctorProvider.nearbyDoctors.isEmpty)
          doctorProvider.loadFromCache(),
      ]);

      // Fetch fresh data
      userProvider.fetchUserProfile().then(
            (_) => debugPrint('User profile loaded'),
            onError: (e) => debugPrint('Error fetching user profile: $e'),
          );

      appointmentProvider.fetchAppointments().then(
            (_) => debugPrint('Appointments loaded'),
            onError: (e) => debugPrint('Error fetching appointments: $e'),
          );

      _getCurrentLocation().then((_) {
        if (mounted) {
          _fetchDoctorsForCurrentPosition();
        }
      }).catchError((e) {
        debugPrint('Error getting location: $e');
        if (mounted) {
          _fetchDoctorsForCurrentPosition();
        }
      });
    } catch (e) {
      debugPrint('Error initializing screen: $e');
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _fetchDoctorsForCurrentPosition() {
    double? lat = _currentPosition.latitude;
    double? lng = _currentPosition.longitude;

    if (lat == 0 && lng == 0) {
      lat = null;
      lng = null;
    }

    Provider.of<DoctorProvider>(context, listen: false)
        .fetchNearbyDoctors(lat: lat, lng: lng)
        .then((_) => debugPrint('Doctors loaded'))
        .catchError((e) => debugPrint('Error fetching doctors: $e'));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationPermissionGranted = false;
          });
          _showLocationServiceDialog();
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoadingLocation = false;
              _locationPermissionGranted = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationPermissionGranted = false;
          });
          _showPermissionDeniedDialog();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _locationPermissionGranted = true;
        });
      }

      Position? bestPosition;

      // 1. Try last known position first (instant on real devices)
      try {
        bestPosition = await Geolocator.getLastKnownPosition();
        if (bestPosition != null) {
          debugPrint(
              'Last known position: ${bestPosition.latitude}, ${bestPosition.longitude}');
        }
      } catch (_) {
        // Best-effort optimization â€” ignore failures
      }

      // 2. Try live position (may take time, may fail on emulators)
      try {
        bestPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15),
          ),
        );
        debugPrint(
            'Live position obtained: ${bestPosition.latitude}, ${bestPosition.longitude}');
      } catch (_) {
        if (bestPosition != null) {
          debugPrint('Live position timed out, using last-known position');
        } else {
          debugPrint('GPS unavailable on this device (emulator or no GPS). '
              'Using default location until GPS fix is obtained.');
        }
      }

      if (mounted) {
        if (bestPosition != null) {
          _currentPosition =
              LatLng(bestPosition.latitude, bestPosition.longitude);
        }
        // If bestPosition is null, keep the default _currentPosition (Dhaka)

        setState(() {
          _isLoadingLocation = false;
        });

        _mapController.move(_currentPosition, 14);
        _addDoctorMarkers();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Unable to get your location. Showing default area.'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _getCurrentLocation,
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  double _calculateDistanceInKm(LatLng from, LatLng to) {
    return _locationService.calculateDistanceInKm(from, to);
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
              'Please enable location services to find nearby doctors.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
              'AroggyaPath needs location access to find doctors near you. Please grant permission in Settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Color _getRouteColor(double distanceKm) {
    if (distanceKm <= 5) return Colors.green;
    if (distanceKm <= 10) return Colors.lightGreen;
    if (distanceKm <= 15) return Colors.orange;
    return Colors.red;
  }

  Future<void> _addDoctorMarkers() async {
    try {
      final doctors = context.read<DoctorProvider>().nearbyDoctors;
      List<Marker> markers = [];
      List<Polyline> polylines = [];

      markers.add(_markerFactory.createUserMarker(_currentPosition));

      for (int i = 0; i < doctors.length; i++) {
        final doctor = doctors[i];

        if (doctor.latitude != null && doctor.longitude != null) {
          final doctorLocation = LatLng(doctor.latitude!, doctor.longitude!);

          double distanceKm = _locationService.calculateDistanceInKm(
            _currentPosition,
            doctorLocation,
          );

          final marker = await _markerFactory.createCustomDoctorMarker(
            doctor: doctor,
            distanceKm: distanceKm,
            onTap: () {
              _showDoctorRoute(doctor.id, doctorLocation, distanceKm);
            },
          );
          markers.add(marker);

          Color routeColor = _getRouteColor(distanceKm);

          polylines.add(
            Polyline(
              points: [_currentPosition, doctorLocation],
              color: routeColor,
              strokeWidth: 4,
              pattern: distanceKm > 15
                  ? StrokePattern.dashed(segments: const [10, 7])
                  : const StrokePattern.solid(),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _markers = markers;
          _polylines = polylines;
        });
      }
    } catch (e) {
      debugPrint('Error adding doctor markers: $e');
    }
  }

  void _showDoctorRoute(
    String doctorId,
    LatLng doctorLocation,
    double distance,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Loading route...'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );

    final directions = await _directionsService.getDirections(
      origin: _currentPosition,
      destination: doctorLocation,
    );

    if (directions != null && mounted) {
      final polylinePoints = directions['polylinePoints'] as List<LatLng>;

      setState(() {
        _directionPolylines.clear();

        _directionPolylines.add(
          Polyline(
            points: polylinePoints,
            color: Colors.blue,
            strokeWidth: 6,
          ),
        );
      });

      // Zoom to fit both user and doctor locations
      final bounds = LatLngBounds.fromPoints([
        _currentPosition,
        doctorLocation,
      ]);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(100),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.directions_car, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '${directions['distance']} â€¢ ${directions['duration']}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        final doctor = context.read<DoctorProvider>().nearbyDoctors.firstWhere(
              (d) => d.id == doctorId,
            );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorDetailsScreen(doctor: doctor),
          ),
        );
      }
    } else {
      debugPrint('Could not fetch street directions, using straight line');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Directions API unavailable. Showing straight-line route.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );

        final doctor = context.read<DoctorProvider>().nearbyDoctors.firstWhere(
              (d) => d.id == doctorId,
            );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorDetailsScreen(doctor: doctor),
          ),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    try {
      double? lat = _currentPosition.latitude;
      double? lng = _currentPosition.longitude;

      if (lat == 0 && lng == 0) {
        lat = null;
        lng = null;
      }

      await Future.wait([
        Provider.of<UserProvider>(context, listen: false)
            .fetchUserProfile()
            .catchError((e) {
          debugPrint('Error refreshing user: $e');
          return false;
        }),
        Provider.of<DoctorProvider>(context, listen: false)
            .fetchNearbyDoctors(lat: lat, lng: lng)
            .catchError((e) {
          debugPrint('Error refreshing doctors: $e');
          return false;
        }),
        Provider.of<AppointmentProvider>(context, listen: false)
            .fetchAppointments()
            .catchError((e) {
          debugPrint('Error refreshing appointments: $e');
          return false;
        }),
      ]);

      if (mounted) {
        await _addDoctorMarkers();
      }
    } catch (e) {
      debugPrint('Error during refresh: $e');
    }
  }

  String _calculateDistance(Doctor doctor) {
    if (doctor.latitude != null && doctor.longitude != null) {
      try {
        final latLngDoctor = LatLng(doctor.latitude!, doctor.longitude!);
        double distanceKm = _locationService.calculateDistanceInKm(
          _currentPosition,
          latLngDoctor,
        );

        if (distanceKm < 1) {
          return '${(distanceKm * 1000).round()} m';
        } else {
          return '${distanceKm.toStringAsFixed(1)} km';
        }
      } catch (e) {
        debugPrint('Error calculating distance: $e');
        return 'N/A';
      }
    }
    return doctor.distance;
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ BUILD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: colors.surfaceAlt,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // â”€â”€ Header: user avatar, name, search â”€â”€
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // User avatar + name
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Profile navigation (placeholder for Phase 4)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  appBar: AppBar(title: const Text('Profile')),
                                  body: const Center(
                                      child: Text('Profile - Phase 4')),
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: colors.primaryContainer,
                                child: ClipOval(
                                  child: userProvider.user?.profileImage != null
                                      ? CachedNetworkImage(
                                          imageUrl:
                                              userProvider.user!.profileImage!,
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Icon(
                                              Icons.person,
                                              size: 30,
                                              color: colors.primary),
                                          errorWidget: (_, __, ___) => Icon(
                                              Icons.person,
                                              size: 30,
                                              color: colors.primary),
                                        )
                                      : Icon(Icons.person,
                                          size: 30, color: colors.primary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userProvider.user?.fullName ??
                                          'Welcome to AroggyaPath',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colors.heading,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            userProvider.user?.address ??
                                                'Location not set',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
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
                      const SizedBox(width: 8),
                      // Search button
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SearchDoctorScreen(
                              userPosition: _currentPosition,
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.search,
                              size: 28, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),

                // â”€â”€ Google Map â”€â”€
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullMapScreen(
                          currentPosition: _currentPosition,
                          markers: _markers,
                          polylines: _polylines,
                        ),
                      ),
                    );
                  },
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
                      child: _isLoadingLocation
                          ? Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 10),
                                    Text('Loading map...',
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            )
                          : Stack(
                              children: [
                                FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _currentPosition,
                                    initialZoom: 13,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.aroggyapath.app',
                                    ),
                                    MarkerLayer(markers: _markers),
                                    PolylineLayer(
                                      polylines: [
                                        ..._polylines,
                                        ..._directionPolylines,
                                      ],
                                    ),
                                  ],
                                ),
                                // Map Legend
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Distance',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: colors.heading,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        _buildLegendItem(
                                            Colors.green, '< 5 km'),
                                        _buildLegendItem(
                                            Colors.lightGreen, '5-10 km'),
                                        _buildLegendItem(
                                            Colors.orange, '10-15 km'),
                                        _buildLegendItem(Colors.red, '> 15 km'),
                                      ],
                                    ),
                                  ),
                                ),
                                // Zoom Controls
                                Positioned(
                                  bottom: 10,
                                  left: 10,
                                  child: Column(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.1),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.add,
                                              color: colors.primaryDark,
                                              size: 24),
                                          onPressed: () {
                                            final currentZoom =
                                                _mapController.camera.zoom;
                                            _mapController.move(
                                              _mapController.camera.center,
                                              currentZoom + 1,
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.1),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.remove,
                                              color: colors.primaryDark,
                                              size: 24),
                                          onPressed: () {
                                            final currentZoom =
                                                _mapController.camera.zoom;
                                            _mapController.move(
                                              _mapController.camera.center,
                                              currentZoom - 1,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Locate Me button â€” always visible
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.my_location,
                                        color: _locationPermissionGranted
                                            ? colors.primaryDark
                                            : Colors.grey,
                                        size: 24,
                                      ),
                                      onPressed: () async {
                                        if (_locationPermissionGranted) {
                                          // Already know where we are â†’ recenter
                                          _mapController.move(
                                              _currentPosition, 14);
                                        } else {
                                          // No location yet â†’ try to get one
                                          await _getCurrentLocation();
                                          if (_locationPermissionGranted) {
                                            _mapController.move(
                                                _currentPosition, 14);
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // â”€â”€ Emergency Help Button â”€â”€
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmergencyHelpScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.emergency,
                              color: Colors.red.shade700, size: 30),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Emergency Help & Health Tips',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                                Text(
                                  'National Helplines, Ambulance & Symptoms',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              color: Colors.red.shade400, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // â”€â”€ Upcoming Appointment â”€â”€
                Consumer<AppointmentProvider>(
                  builder: (context, aptProvider, child) {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);

                    final upcoming = aptProvider.upcomingAppointments
                        .where((a) {
                      final appointmentDay = DateTime(
                        a.appointmentDate.year,
                        a.appointmentDate.month,
                        a.appointmentDate.day,
                      );
                      return appointmentDay.isAtSameMomentAs(today) ||
                          appointmentDay.isAfter(today);
                    }).toList()
                      ..sort((a, b) =>
                          a.appointmentDate.compareTo(b.appointmentDate));

                    if (upcoming.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upcoming Appointment',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: colors.heading,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildUpcomingAppointmentCard(upcoming.first),
                          const SizedBox(height: 25),
                        ],
                      ),
                    );
                  },
                ),

                // â”€â”€ Nearby Doctors Header â”€â”€
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nearby Doctors',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: colors.heading,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SeeAllDoctorsScreen(
                              userPosition: _currentPosition,
                            ),
                          ),
                        ),
                        child: const Text(
                          'See All',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // â”€â”€ Doctors List â”€â”€
                Consumer<DoctorProvider>(
                  builder: (context, doctorProvider, child) {
                    if (doctorProvider.isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (doctorProvider.error != null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text('Error: ${doctorProvider.error}'),
                        ),
                      );
                    }

                    // Filter to 50km radius
                    final nearbyDoctors =
                        doctorProvider.nearbyDoctors.where((doc) {
                      if (doc.latitude == null || doc.longitude == null) {
                        return false;
                      }
                      final distance = _calculateDistanceInKm(
                        _currentPosition,
                        LatLng(doc.latitude!, doc.longitude!),
                      );
                      return distance <= 50;
                    }).toList();

                    if (nearbyDoctors.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('No doctors found nearby'),
                        ),
                      );
                    }

                    // Sort by distance
                    nearbyDoctors.sort((a, b) {
                      if (a.latitude == null || a.longitude == null) return 1;
                      if (b.latitude == null || b.longitude == null) return -1;

                      final distA = _calculateDistanceInKm(
                        _currentPosition,
                        LatLng(a.latitude!, a.longitude!),
                      );
                      final distB = _calculateDistanceInKm(
                        _currentPosition,
                        LatLng(b.latitude!, b.longitude!),
                      );

                      return distA.compareTo(distB);
                    });

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: nearbyDoctors.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 20,
                            left: 20,
                            right: 20,
                          ),
                          child: _buildCustomDoctorCard(nearbyDoctors[index]),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // â”€â”€â”€ Map Legend Item â”€â”€â”€
  Widget _buildLegendItem(Color color, String label) {
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

  // â”€â”€â”€ Upcoming Appointment Card â”€â”€â”€
  Widget _buildUpcomingAppointmentCard(appointment) {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.success.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_today, color: colors.success, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.doctorName ?? 'Doctor',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colors.heading,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.specialty ?? '',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      appointment.formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildStatusBadge(appointment.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final colors = AppTheme.of(context);
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = colors.statusPendingBg;
        textColor = Colors.orange;
        label = 'Pending';
        break;
      case 'accepted':
        bgColor = colors.statusAcceptedBg;
        textColor = Colors.green;
        label = 'Accepted';
        break;
      case 'completed':
        bgColor = colors.primaryContainer;
        textColor = Colors.blue;
        label = 'Completed';
        break;
      case 'cancelled':
        bgColor = colors.statusCancelledBg;
        textColor = Colors.red;
        label = 'Cancelled';
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // â”€â”€â”€ Doctor Availability â”€â”€â”€
  bool _isDoctorAvailable(Doctor doctor) {
    if (doctor.weeklySchedule == null || doctor.weeklySchedule!.isEmpty) {
      return false;
    }

    for (var schedule in doctor.weeklySchedule!) {
      if (schedule.isActive && schedule.slots.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  String _getVisitingHours(Doctor doctor) {
    if (doctor.weeklySchedule == null || doctor.weeklySchedule!.isEmpty) {
      return 'No schedule set';
    }

    List<String> activeDays = [];
    for (var schedule in doctor.weeklySchedule!) {
      if (schedule.isActive && schedule.slots.isNotEmpty) {
        String dayShort = schedule.day.length >= 3
            ? schedule.day.substring(0, 3)
            : schedule.day;
        activeDays.add(dayShort);
      }
    }

    if (activeDays.isEmpty) return 'No schedule set';
    if (activeDays.length == 1) return activeDays[0];
    if (activeDays.length <= 3) return activeDays.join(', ');
    return '${activeDays.first}-${activeDays.last}';
  }

  // â”€â”€â”€ Custom Doctor Card â”€â”€â”€
  Widget _buildCustomDoctorCard(Doctor doctor) {
    final colors = AppTheme.of(context);
    final bool isAvailable = _isDoctorAvailable(doctor);
    final String visitingHours = _getVisitingHours(doctor);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor image
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: doctor.image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: doctor.image,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey[100],
                            child: const Icon(Icons.person,
                                size: 40, color: Colors.grey),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[100],
                            child: const Icon(Icons.person,
                                size: 40, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey[100],
                          child: const Icon(Icons.person,
                              size: 40, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            doctor.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? colors.statusAcceptedBg
                                : colors.statusPendingBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAvailable ? 'Available' : 'No Schedule',
                            style: TextStyle(
                              color: isAvailable
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialty,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            visitingHours,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 16, color: Colors.orangeAccent),
                        Text(
                          ' ${doctor.rating.toStringAsFixed(1)} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 15),
                        Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _calculateDistance(doctor),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isAvailable
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookAppointmentScreen(doctor: doctor),
                            ),
                          )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isAvailable ? colors.primaryDark : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isAvailable ? 'Book Now' : 'Not Available',
                    style: TextStyle(
                      color: isAvailable ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorDetailsScreen(doctor: doctor),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info_outline, color: colors.primaryDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
