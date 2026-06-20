import 'package:latlong2/latlong.dart';

import '../../../../models/doctor_model.dart';

class PatientHomeDoctorCardModel {
  final Doctor doctor;
  final bool isAvailable;
  final String visitingHours;
  final String distanceText;
  final double? distanceKm;

  const PatientHomeDoctorCardModel({
    required this.doctor,
    required this.isAvailable,
    required this.visitingHours,
    required this.distanceText,
    required this.distanceKm,
  });

  factory PatientHomeDoctorCardModel.fromDoctor({
    required Doctor doctor,
    required LatLng userPosition,
  }) {
    final distanceKm = _distanceInKm(doctor, userPosition);

    return PatientHomeDoctorCardModel(
      doctor: doctor,
      isAvailable: _isDoctorAvailable(doctor),
      visitingHours: _visitingHours(doctor),
      distanceKm: distanceKm,
      distanceText: _distanceText(doctor, distanceKm),
    );
  }

  static List<PatientHomeDoctorCardModel> nearbyDoctors({
    required List<Doctor> doctors,
    required LatLng userPosition,
    double maxDistanceKm = 50,
  }) {
    final items = doctors
        .map(
          (doctor) => PatientHomeDoctorCardModel.fromDoctor(
            doctor: doctor,
            userPosition: userPosition,
          ),
        )
        .where((item) {
      final distance = item.distanceKm;
      return distance != null && distance <= maxDistanceKm;
    }).toList();

    items.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
    return items;
  }

  static double? _distanceInKm(Doctor doctor, LatLng userPosition) {
    if (doctor.latitude == null || doctor.longitude == null) {
      return null;
    }

    final doctorPosition = LatLng(doctor.latitude!, doctor.longitude!);
    return const Distance().as(
      LengthUnit.Kilometer,
      userPosition,
      doctorPosition,
    );
  }

  static String _distanceText(Doctor doctor, double? distanceKm) {
    if (distanceKm == null) {
      return doctor.distance;
    }

    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }

    return '${distanceKm.toStringAsFixed(1)} km';
  }

  static bool _isDoctorAvailable(Doctor doctor) {
    final schedule = doctor.weeklySchedule;
    if (schedule == null || schedule.isEmpty) {
      return false;
    }

    return schedule.any((day) => day.isActive && day.slots.isNotEmpty);
  }

  static String _visitingHours(Doctor doctor) {
    final schedule = doctor.weeklySchedule;
    if (schedule == null || schedule.isEmpty) {
      return 'No schedule set';
    }

    final activeDays = schedule
        .where((day) => day.isActive && day.slots.isNotEmpty)
        .map((day) => day.day.length >= 3 ? day.day.substring(0, 3) : day.day)
        .toList();

    if (activeDays.isEmpty) return 'No schedule set';
    if (activeDays.length == 1) return activeDays.first;
    if (activeDays.length <= 3) return activeDays.join(', ');
    return '${activeDays.first}-${activeDays.last}';
  }
}
