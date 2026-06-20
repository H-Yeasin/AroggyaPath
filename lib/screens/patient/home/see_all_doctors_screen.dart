import 'dart:math' show cos, sqrt;

import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../models/doctor_model.dart';
import '../../../providers/user_provider.dart';
import '../../../services/api_service.dart';
import '../doctor/doctor_detail_screen.dart';

enum DoctorListFilter { all, nearby, online }

class SeeAllDoctorsScreen extends StatefulWidget {
  static const double nearbyRadiusKm = 10;

  final LatLng? userPosition;
  final DoctorListFilter filter;

  const SeeAllDoctorsScreen({
    super.key,
    this.userPosition,
    this.filter = DoctorListFilter.all,
  });

  @override
  State<SeeAllDoctorsScreen> createState() => _SeeAllDoctorsScreenState();
}

class _SeeAllDoctorsScreenState extends State<SeeAllDoctorsScreen> {
  List<Doctor> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result =
          await ApiService.get('/api/v1/user/role/doctor', requiresAuth: true);
      if (result['success'] == true) {
        final doctorsData = result['data'] as List? ?? [];
        final currentUser =
            Provider.of<UserProvider>(context, listen: false).user;
        List<Doctor> loadedDoctors = doctorsData
            .map((json) => Doctor.fromJson(json))
            .where((doctor) => doctor.id != currentUser?.id)
            .toList();
        loadedDoctors = _filterDoctors(loadedDoctors);
        if (widget.filter == DoctorListFilter.online) {
          loadedDoctors.sort((a, b) {
            final availability = (_isDoctorAvailable(b) ? 1 : 0)
                .compareTo(_isDoctorAvailable(a) ? 1 : 0);
            if (availability != 0) return availability;
            return b.rating.compareTo(a.rating);
          });
        } else if (widget.userPosition != null) {
          loadedDoctors.sort((a, b) {
            if (a.latitude == null || a.longitude == null) return 1;
            if (b.latitude == null || b.longitude == null) return -1;
            return _calculateDistanceInKm(
                    widget.userPosition!, LatLng(a.latitude!, a.longitude!))
                .compareTo(_calculateDistanceInKm(
                    widget.userPosition!, LatLng(b.latitude!, b.longitude!)));
          });
        }
        setState(() {
          _doctors = loadedDoctors;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load doctors';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load doctors: $e';
        _isLoading = false;
      });
    }
  }

  List<Doctor> _filterDoctors(List<Doctor> doctors) {
    switch (widget.filter) {
      case DoctorListFilter.nearby:
        if (widget.userPosition == null) return [];
        return doctors.where((doctor) {
          if (doctor.latitude == null || doctor.longitude == null) {
            return false;
          }

          final distance = _calculateDistanceInKm(
            widget.userPosition!,
            LatLng(doctor.latitude!, doctor.longitude!),
          );
          return distance <= SeeAllDoctorsScreen.nearbyRadiusKm;
        }).toList();
      case DoctorListFilter.online:
        return doctors.where((doctor) => doctor.isVideoCallAvailable).toList();
      case DoctorListFilter.all:
        return doctors;
    }
  }

  double _calculateDistanceInKm(LatLng p1, LatLng p2) {
    const double p = 0.017453292519943295;
    final double a = 0.5 -
        cos((p2.latitude - p1.latitude) * p) / 2 +
        cos(p1.latitude * p) *
            cos(p2.latitude * p) *
            (1 - cos((p2.longitude - p1.longitude) * p)) /
            2;
    return 12742 * sqrt(a);
  }

  String _getDistanceText(Doctor doctor) {
    if (widget.userPosition == null ||
        doctor.latitude == null ||
        doctor.longitude == null) {
      return doctor.distance;
    }
    final distance = _calculateDistanceInKm(
        widget.userPosition!, LatLng(doctor.latitude!, doctor.longitude!));
    if (distance < 1) return '${(distance * 1000).toInt()} m';
    return '${distance.toStringAsFixed(1)} km';
  }

  bool _isDoctorAvailable(Doctor doctor) {
    if (doctor.weeklySchedule == null || doctor.weeklySchedule!.isEmpty) {
      return false;
    }
    for (var schedule in doctor.weeklySchedule!) {
      if (schedule.isActive && schedule.slots.isNotEmpty) return true;
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
        activeDays.add(schedule.day.length >= 3
            ? schedule.day.substring(0, 3)
            : schedule.day);
      }
    }
    if (activeDays.isEmpty) return 'No schedule set';
    if (activeDays.length == 1) return activeDays[0];
    if (activeDays.length <= 3) return activeDays.join(', ');
    return '${activeDays.first}-${activeDays.last}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: colors.surfaceAlt,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
        title: Text(_screenTitle,
            style: TextStyle(
                color: colors.heading,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ),
      body: _buildBody(),
    );
  }

  String get _screenTitle {
    switch (widget.filter) {
      case DoctorListFilter.nearby:
        return 'Nearby Doctors';
      case DoctorListFilter.online:
        return 'Online Doctors';
      case DoctorListFilter.all:
        return 'All Doctors';
    }
  }

  String get _emptyText {
    switch (widget.filter) {
      case DoctorListFilter.nearby:
        return 'No doctors found within 10 km';
      case DoctorListFilter.online:
        return 'No online doctors available';
      case DoctorListFilter.all:
        return 'No doctors available';
    }
  }

  Widget _buildBody() {
    final colors = AppTheme.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(_errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadDoctors,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary, foregroundColor: Colors.white),
          ),
        ]),
      );
    }
    if (_doctors.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(
            Icons.medical_services_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(_emptyText,
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadDoctors,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _doctors.length,
        itemBuilder: (context, index) => _buildDoctorCard(_doctors[index]),
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    final colors = AppTheme.of(context);
    final bool isAvailable = _isDoctorAvailable(doctor);
    final String visitingHours = _getVisitingHours(doctor);
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DoctorDetailsScreen(doctor: doctor))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 70,
                height: 70,
                child: doctor.image != null && doctor.image!.startsWith('http')
                    ? Image.network(doctor.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.person, size: 40)))
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.person, size: 40)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(doctor.fullName,
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colors.heading),
                                  overflow: TextOverflow.ellipsis)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? colors.statusAcceptedBg
                                  : colors.statusPendingBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                                isAvailable ? 'Available' : 'No Schedule',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAvailable
                                        ? Colors.green[700]
                                        : Colors.orange[700])),
                          ),
                        ]),
                    const SizedBox(height: 4),
                    Text(doctor.specialty,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(visitingHours,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis))
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.star, size: 16, color: Colors.orange),
                      Text(' ${doctor.rating.toStringAsFixed(1)} ',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      Text(_getDistanceText(doctor),
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey)),
                    ]),
                  ]),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: isAvailable
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                DoctorDetailsScreen(doctor: doctor)))
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isAvailable ? colors.primaryDark : Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(isAvailable ? 'Book Now' : 'Not Available',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isAvailable ? Colors.white : Colors.grey[600])),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                  color: colors.primaryContainer, shape: BoxShape.circle),
              child: IconButton(
                icon: Icon(Icons.info_outline, color: colors.primaryDark),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DoctorDetailsScreen(doctor: doctor))),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
