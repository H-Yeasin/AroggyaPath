import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../models/doctor_model.dart';
import '../../../../providers/doctor_provider.dart';
import '../models/patient_home_doctor_card_model.dart';
import 'patient_doctor_card.dart';

class NearbyDoctorsSection extends StatelessWidget {
  final LatLng userPosition;
  final VoidCallback onSeeAll;
  final ValueChanged<Doctor> onBookDoctor;
  final ValueChanged<Doctor> onViewDoctor;

  const NearbyDoctorsSection({
    super.key,
    required this.userPosition,
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
                'Nearby Doctors',
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
        Consumer<DoctorProvider>(
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

            final doctors = PatientHomeDoctorCardModel.nearbyDoctors(
              doctors: doctorProvider.nearbyDoctors,
              userPosition: userPosition,
            );

            if (doctors.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No doctors found nearby'),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final item = doctors[index];

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  child: PatientDoctorCard(
                    item: item,
                    onBook: () => onBookDoctor(item.doctor),
                    onDetails: () => onViewDoctor(item.doctor),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
