import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/doctor_model.dart';
import '../../../providers/user_provider.dart';
import '../../../services/api_service.dart';
import 'book_appointment_screen.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final Doctor doctor;
  const DoctorDetailsScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  List<dynamic> _reviews = [];
  double _avgRating = 0.0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadDoctorReviews();
  }

  Future<void> _loadDoctorReviews() async {
    try {
      final response = await ApiService.get(
        '/api/v1/doctor-review/doctor/${widget.doctor.id}',
        requiresAuth: false,
      );
      if (response['success'] == true && response['data'] != null && mounted) {
        final data = response['data'];
        setState(() {
          _reviews = data['items'] ?? [];
          _avgRating = (data['summary']?['avgRating'] ?? 0.0).toDouble();
          _totalReviews = data['summary']?['totalReviews'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final doctor = widget.doctor;
    final hasVideoCall = doctor.isVideoCallAvailable;
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    final isOwnProfile = doctor.id == currentUser?.id;
    final canBook = currentUser?.role != 'doctor' && !isOwnProfile;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.heading),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Doctor Details',
          style: TextStyle(
            color: colors.heading,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeader(
                doctor: doctor,
                hasVideoCall: hasVideoCall,
                avgRating: _avgRating,
                totalReviews: _totalReviews,
              ),
              const SizedBox(height: 16),
              _LocationCard(doctor: doctor),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.medical_services_outlined,
                      title: 'Specialty',
                      value: doctor.specialty.isEmpty
                          ? 'Not specified'
                          : doctor.specialty,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.payments_outlined,
                      title: 'Fees',
                      value: _getFeesText(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.access_time,
                title: 'Visiting Hours',
                value: _getVisitingHours(),
                fullWidth: true,
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'About'),
              const SizedBox(height: 8),
              Text(
                doctor.bio ??
                    "${doctor.fullName} is a ${doctor.specialty} with ${doctor.experience} years of experience.",
                style: TextStyle(
                  color: colors.bodyText,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              if (doctor.degrees.isNotEmpty) ...[
                const SizedBox(height: 22),
                _SectionTitle(title: 'Degrees'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: doctor.degrees
                      .map((degree) => _Chip(text: degree))
                      .toList(),
                ),
              ],
              if (_reviews.isNotEmpty) ...[
                const SizedBox(height: 24),
                _SectionTitle(title: 'Reviews'),
                const SizedBox(height: 12),
                ..._reviews
                    .take(5)
                    .map((review) => _ReviewCard(review: review)),
              ],
              if (canBook) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookAppointmentScreen(doctor: doctor),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryLight,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getFeesText() {
    final amount = widget.doctor.fees?['amount'];
    final currency = widget.doctor.fees?['currency'];

    if (amount == null) return 'Contact';
    if (currency == null || currency.toString().trim().isEmpty) {
      return amount.toString();
    }
    return '$amount $currency';
  }

  String _getVisitingHours() {
    final customText = widget.doctor.visitingHoursText?.trim();
    if (customText != null && customText.isNotEmpty) return customText;

    if (widget.doctor.weeklySchedule == null ||
        widget.doctor.weeklySchedule!.isEmpty) {
      return 'Not set';
    }

    final activeDays = <String>[];
    for (final schedule in widget.doctor.weeklySchedule!) {
      if (schedule.isActive && schedule.slots.isNotEmpty) {
        activeDays.add(
          schedule.day.length >= 3
              ? schedule.day.substring(0, 3)
              : schedule.day,
        );
      }
    }

    if (activeDays.isEmpty) return 'Not set';
    if (activeDays.length <= 3) return activeDays.join(', ');
    return '${activeDays.first}-${activeDays.last}';
  }
}

class _ProfileHeader extends StatelessWidget {
  final Doctor doctor;
  final bool hasVideoCall;
  final double avgRating;
  final int totalReviews;

  const _ProfileHeader({
    required this.doctor,
    required this.hasVideoCall,
    required this.avgRating,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DoctorAvatar(image: doctor.image),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.fullName,
                      style: TextStyle(
                        color: colors.heading,
                        fontSize: 23,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      doctor.specialty,
                      style: TextStyle(
                        color: colors.bodyText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AvailabilityBadge(hasVideoCall: hasVideoCall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.star,
                  value: avgRating.toStringAsFixed(1),
                  label: '$totalReviews reviews',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  icon: Icons.work_history_outlined,
                  value: doctor.experience,
                  label: 'Years exp.',
                  color: colors.primaryDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  icon: Icons.event_available_outlined,
                  value: doctor.isAvailable ? 'Yes' : 'No',
                  label: 'Available',
                  color: doctor.isAvailable ? colors.success : colors.warning,
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
  final String image;

  const _DoctorAvatar({required this.image});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 96,
        height: 96,
        child: image.startsWith('http')
            ? Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _AvatarFallback(),
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
      child: const Icon(Icons.person, size: 44, color: Colors.grey),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool hasVideoCall;

  const _AvailabilityBadge({required this.hasVideoCall});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final color = hasVideoCall ? colors.info : colors.warning;
    final background =
        hasVideoCall ? colors.primaryContainer : colors.statusPendingBg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasVideoCall ? Icons.videocam : Icons.local_hospital_outlined,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              hasVideoCall ? 'Video Available' : 'In-person only',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.heading,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.bodyText, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final Doctor doctor;

  const _LocationCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final locationText = _getLocationText();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primaryContainer),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.location_on, color: colors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Practice Location',
                  style: TextStyle(
                    color: colors.heading,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  locationText,
                  style: TextStyle(
                    color: colors.bodyText,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                if (doctor.distance != 'N/A' &&
                    doctor.distance.trim().isNotEmpty &&
                    doctor.distance != locationText) ...[
                  const SizedBox(height: 8),
                  Text(
                    doctor.distance,
                    style: TextStyle(
                      color: colors.primaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLocationText() {
    final address = doctor.address?.trim();
    final location = doctor.location.trim();

    if (address != null && address.isNotEmpty) return address;
    if (location.isNotEmpty && !location.startsWith('{')) return location;
    if (doctor.latitude != null && doctor.longitude != null) {
      return '${doctor.latitude!.toStringAsFixed(5)}, ${doctor.longitude!.toStringAsFixed(5)}';
    }
    if (doctor.distance != 'N/A' && doctor.distance.trim().isNotEmpty) {
      return doctor.distance;
    }
    return 'Location not set';
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool fullWidth;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Container(
      width: fullWidth ? double.infinity : null,
      height: 82,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primaryDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.bodyText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    color: colors.heading,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Text(
      title,
      style: TextStyle(
        color: colors.heading,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;

  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colors.primaryDark,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final dynamic review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final patientName = (review['patient']?['fullName'] ?? 'User').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.primaryContainer,
            child: Text(
              patientName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: colors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        patientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.heading,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.star, size: 14, color: Colors.orange),
                    Text(' ${review['rating'] ?? 'N/A'}'),
                  ],
                ),
                if (review['comment'] != null &&
                    review['comment'].toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    review['comment'],
                    style: TextStyle(
                      color: colors.bodyText,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
