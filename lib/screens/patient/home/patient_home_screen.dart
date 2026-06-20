import 'dart:async';

import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:arogya_path3/core/location/location.dart';
import 'package:arogya_path3/screens/patient/emergency/emergency_contact_home.dart';
import 'package:arogya_path3/screens/patient/profile/patient_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../models/doctor_model.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/doctor_provider.dart';
import '../../../providers/user_provider.dart';
import '../doctor/book_appointment_screen.dart';
import '../doctor/doctor_detail_screen.dart';
import 'full_map_screen.dart';
import 'search_doctor_screen.dart';
import 'see_all_doctors_screen.dart';
import 'widgets/emergency_help_card.dart';
import 'widgets/nearby_doctors_section.dart';
import 'widgets/patient_home_header.dart';
import 'widgets/patient_home_map_preview.dart';
import 'widgets/upcoming_appointment_section.dart';

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
      if (_isScreenInitialized) return;

      _isScreenInitialized = true;
      _initializeScreen();
      _startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
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
      final userProvider = context.read<UserProvider>();
      final doctorProvider = context.read<DoctorProvider>();
      final appointmentProvider = context.read<AppointmentProvider>();

      await Future.wait([
        if (userProvider.user == null) userProvider.loadFromCache(),
        if (appointmentProvider.appointments.isEmpty)
          appointmentProvider.loadFromCache(),
        if (doctorProvider.nearbyDoctors.isEmpty)
          doctorProvider.loadFromCache(),
      ]);

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
    final (lat, lng) = _currentFetchCoordinates();

    context
        .read<DoctorProvider>()
        .fetchNearbyDoctors(lat: lat, lng: lng)
        .then((_) async {
      debugPrint('Doctors loaded');
      if (mounted) {
        await _addDoctorMarkers();
      }
    }).catchError((e) => debugPrint('Error fetching doctors: $e'));
  }

  (double?, double?) _currentFetchCoordinates() {
    double? lat = _currentPosition.latitude;
    double? lng = _currentPosition.longitude;

    if (lat == 0 && lng == 0) {
      lat = null;
      lng = null;
    }

    return (lat, lng);
  }

  Future<void> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
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
        setState(() => _locationPermissionGranted = true);
      }

      Position? bestPosition;

      try {
        bestPosition = await Geolocator.getLastKnownPosition();
        if (bestPosition != null) {
          debugPrint(
            'Last known position: '
            '${bestPosition.latitude}, ${bestPosition.longitude}',
          );
        }
      } catch (_) {
        // Last-known location is a best-effort speed-up.
      }

      try {
        bestPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15),
          ),
        );
        debugPrint(
          'Live position obtained: '
          '${bestPosition.latitude}, ${bestPosition.longitude}',
        );
      } catch (_) {
        if (bestPosition != null) {
          debugPrint('Live position timed out, using last-known position');
        } else {
          debugPrint(
            'GPS unavailable. Using default location until GPS fix is obtained.',
          );
        }
      }

      if (!mounted) return;

      if (bestPosition != null) {
        _currentPosition = LatLng(
          bestPosition.latitude,
          bestPosition.longitude,
        );
      }

      setState(() => _isLoadingLocation = false);
      _moveMapToCurrentPosition();
      await _addDoctorMarkers();
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (!mounted) return;

      setState(() => _isLoadingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Unable to get your location. Showing default area.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _getCurrentLocation,
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _moveMapToCurrentPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        _mapController.move(_currentPosition, 14);
      } catch (e) {
        debugPrint('Map is not ready to move yet: $e');
      }
    });
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Please enable location services to find nearby doctors.',
          ),
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
            'AroggyaPath needs location access to find doctors near you. '
            'Please grant permission in Settings.',
          ),
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
      final markers = <Marker>[
        _markerFactory.createUserMarker(_currentPosition),
      ];
      final polylines = <Polyline>[];

      for (final doctor in doctors) {
        if (doctor.latitude == null || doctor.longitude == null) {
          debugPrint(
            'Skipping doctor marker for ${doctor.fullName}: missing coordinates',
          );
          continue;
        }

        final doctorLocation = LatLng(doctor.latitude!, doctor.longitude!);
        final distanceKm = _locationService.calculateDistanceInKm(
          _currentPosition,
          doctorLocation,
        );

        final marker = await _markerFactory.createCustomDoctorMarker(
          doctor: doctor,
          distanceKm: distanceKm,
          onTap: () => _showDoctorRoute(
            doctor.id,
            doctorLocation,
            distanceKm,
          ),
        );

        markers.add(marker);
        polylines.add(
          Polyline(
            points: [_currentPosition, doctorLocation],
            color: _getRouteColor(distanceKm),
            strokeWidth: 4,
            pattern: distanceKm > 15
                ? StrokePattern.dashed(segments: const [10, 7])
                : const StrokePattern.solid(),
          ),
        );
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

  Future<void> _showDoctorRoute(
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
        _directionPolylines
          ..clear()
          ..add(
            Polyline(
              points: polylinePoints,
              color: Colors.blue,
              strokeWidth: 6,
            ),
          );
      });

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
                '${directions['distance']} - ${directions['duration']}',
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
        _openDoctorDetailsById(doctorId);
      }
      return;
    }

    debugPrint('Could not fetch street directions, using straight line');
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 20,
            ),
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
    _openDoctorDetailsById(doctorId);
  }

  void _openDoctorDetailsById(String doctorId) {
    final doctor = context.read<DoctorProvider>().nearbyDoctors.firstWhere(
          (doctor) => doctor.id == doctorId,
        );
    _openDoctorDetails(doctor);
  }

  Future<void> _onRefresh() async {
    try {
      final (lat, lng) = _currentFetchCoordinates();

      await Future.wait([
        context.read<UserProvider>().fetchUserProfile().catchError((e) {
          debugPrint('Error refreshing user: $e');
          return false;
        }),
        context
            .read<DoctorProvider>()
            .fetchNearbyDoctors(lat: lat, lng: lng)
            .catchError((e) {
          debugPrint('Error refreshing doctors: $e');
          return false;
        }),
        context.read<AppointmentProvider>().fetchAppointments().catchError((e) {
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

  Future<void> _locateMe() async {
    if (_locationPermissionGranted) {
      _mapController.move(_currentPosition, 14);
      return;
    }

    await _getCurrentLocation();
    if (_locationPermissionGranted) {
      _mapController.move(_currentPosition, 14);
    }
  }

  void _zoomIn() {
    final camera = _mapController.camera;
    _mapController.move(camera.center, camera.zoom + 1);
  }

  void _zoomOut() {
    final camera = _mapController.camera;
    _mapController.move(camera.center, camera.zoom - 1);
  }

  void _openProfilePlaceholder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PatientProfileScreen()),
    );
  }

  void _openDoctorSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchDoctorScreen(userPosition: _currentPosition),
      ),
    );
  }

  void _openFullMap() {
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
  }

  void _openEmergencyHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyHelpScreen()),
    );
  }

  void _openAllDoctors() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeeAllDoctorsScreen(userPosition: _currentPosition),
      ),
    );
  }

  void _openBookAppointment(Doctor doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookAppointmentScreen(doctor: doctor),
      ),
    );
  }

  void _openDoctorDetails(Doctor doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorDetailsScreen(doctor: doctor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final user = context.watch<UserProvider>().user;

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
                PatientHomeHeader(
                  user: user,
                  onProfileTap: _openProfilePlaceholder,
                  onSearchTap: _openDoctorSearch,
                ),
                PatientHomeMapPreview(
                  mapController: _mapController,
                  currentPosition: _currentPosition,
                  isLoadingLocation: _isLoadingLocation,
                  locationPermissionGranted: _locationPermissionGranted,
                  markers: _markers,
                  polylines: _polylines,
                  directionPolylines: _directionPolylines,
                  onOpenMap: _openFullMap,
                  onZoomIn: _zoomIn,
                  onZoomOut: _zoomOut,
                  onLocateMe: _locateMe,
                ),
                const SizedBox(height: 25),
                EmergencyHelpCard(onTap: _openEmergencyHelp),
                const SizedBox(height: 25),
                const UpcomingAppointmentSection(),
                NearbyDoctorsSection(
                  userPosition: _currentPosition,
                  onSeeAll: _openAllDoctors,
                  onBookDoctor: _openBookAppointment,
                  onViewDoctor: _openDoctorDetails,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
