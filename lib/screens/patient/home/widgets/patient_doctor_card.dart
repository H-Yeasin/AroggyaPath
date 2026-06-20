import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/patient_home_doctor_card_model.dart';

class PatientDoctorCard extends StatelessWidget {
  final PatientHomeDoctorCardModel item;
  final VoidCallback onBook;
  final VoidCallback onDetails;

  const PatientDoctorCard({
    super.key,
    required this.item,
    required this.onBook,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final doctor = item.doctor;

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
              _DoctorAvatar(imageUrl: doctor.image),
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
                        _AvailabilityBadge(isAvailable: item.isAvailable),
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
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.visitingHours,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.orangeAccent,
                        ),
                        Text(
                          ' ${doctor.rating.toStringAsFixed(1)} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 15),
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.distanceText,
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
                  onPressed: item.isAvailable ? onBook : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        item.isAvailable ? colors.primaryDark : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    item.isAvailable ? 'Book Now' : 'Not Available',
                    style: TextStyle(
                      color: item.isAvailable ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onDetails,
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

class _DoctorAvatar extends StatelessWidget {
  final String imageUrl;

  const _DoctorAvatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        width: 80,
        height: 80,
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const _AvatarFallback(),
                errorWidget: (_, __, ___) => const _AvatarFallback(),
              )
            : const _AvatarFallback(),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: const Icon(Icons.person, size: 40, color: Colors.grey),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;

  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? colors.statusAcceptedBg : colors.statusPendingBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isAvailable ? 'Available' : 'No Schedule',
        style: TextStyle(
          color: isAvailable ? Colors.green[700] : Colors.orange[700],
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
