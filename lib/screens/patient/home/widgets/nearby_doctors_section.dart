import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../models/doctor_model.dart';
import '../../../../providers/doctor_provider.dart';
import '../models/patient_home_doctor_card_model.dart';
import 'patient_doctor_card.dart';

class NearbyDoctorsSection extends StatelessWidget {
  static const double _nearbyRadiusKm = 10;

  final LatLng userPosition;
  final VoidCallback onSeeAllNearby;
  final VoidCallback onSeeAllOnline;
  final ValueChanged<Doctor> onBookDoctor;
  final ValueChanged<Doctor> onViewDoctor;

  const NearbyDoctorsSection({
    super.key,
    required this.userPosition,
    required this.onSeeAllNearby,
    required this.onSeeAllOnline,
    required this.onBookDoctor,
    required this.onViewDoctor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DoctorProvider>(
      builder: (context, doctorProvider, child) {
        if (doctorProvider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (doctorProvider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Error: ${doctorProvider.error}'),
            ),
          );
        }

        final nearbyDoctors = PatientHomeDoctorCardModel.nearbyDoctors(
          doctors: doctorProvider.nearbyDoctors,
          userPosition: userPosition,
          maxDistanceKm: _nearbyRadiusKm,
        );
        final onlineDoctors = doctorProvider.onlineDoctors
            .map(
              (doctor) => PatientHomeDoctorCardModel.fromDoctor(
                doctor: doctor,
                userPosition: userPosition,
              ),
            )
            .take(5)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DoctorPreviewSection(
              title: 'Nearby Doctors',
              emptyText: 'No doctors found within 10 km',
              doctors: nearbyDoctors.take(5).toList(),
              onSeeAll: onSeeAllNearby,
              onBookDoctor: onBookDoctor,
              onViewDoctor: onViewDoctor,
            ),
            const SizedBox(height: 24),
            _DoctorPreviewSection(
              title: 'Online Doctors',
              emptyText: 'No online doctors available',
              doctors: onlineDoctors,
              onSeeAll: onSeeAllOnline,
              onBookDoctor: onBookDoctor,
              onViewDoctor: onViewDoctor,
            ),
          ],
        );
      },
    );
  }
}

class _DoctorPreviewSection extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<PatientHomeDoctorCardModel> doctors;
  final VoidCallback onSeeAll;
  final ValueChanged<Doctor> onBookDoctor;
  final ValueChanged<Doctor> onViewDoctor;

  const _DoctorPreviewSection({
    required this.title,
    required this.emptyText,
    required this.doctors,
    required this.onSeeAll,
    required this.onBookDoctor,
    required this.onViewDoctor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: colors.heading,
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                child: const Text(
                  'See All',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        if (doctors.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(emptyText),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: doctors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final item = doctors[index];

                return SizedBox(
                  width: 320,
                  child: PatientDoctorCard(
                    item: item,
                    onBook: () => onBookDoctor(item.doctor),
                    onDetails: () => onViewDoctor(item.doctor),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
