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
      if (response['success'] == true && response['data'] != null) {
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
    final bool hasVideoCall = widget.doctor.isVideoCallAvailable;
    final String? currentUserRole =
        Provider.of<UserProvider>(context, listen: false).user?.role;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: widget.doctor.image.startsWith('http')
                            ? Image.network(widget.doctor.image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.person, size: 40)))
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.person, size: 40)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.doctor.fullName,
                              style: const TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.bold)),
                          Text(widget.doctor.specialty,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 8),
                          if (hasVideoCall)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 6),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: colors.info, width: 1.5),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.videocam,
                                        color: colors.info, size: 14),
                                    SizedBox(width: 2),
                                    Text('Video Available',
                                        style: TextStyle(
                                            color: colors.info,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 10)),
                                  ]),
                            ),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.location_on, size: 16),
                            Text(" ${widget.doctor.distance}"),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.star,
                                size: 20, color: Colors.orange),
                            Text(
                                " ${_avgRating.toStringAsFixed(1)} ($_totalReviews reviews)"),
                          ]),
                        ],
                      ),
                    ),
                    Column(children: [
                      IconButton(
                        icon: const Icon(Icons.close, size: 35),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ]),
                  ],
                ),
                const SizedBox(height: 25),

                // Bio
                const Text('About',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(widget.doctor.bio ??
                    "${widget.doctor.fullName} is a ${widget.doctor.specialty} with ${widget.doctor.experience} years of experience."),
                const SizedBox(height: 30),

                // Specialty
                const Text('Specialty',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildBulletItem(widget.doctor.specialty),
                const SizedBox(height: 35),

                // Fees
                Text(
                    "Fees: ${widget.doctor.fees?['amount'] ?? 'Contact'} ${widget.doctor.fees?['currency'] ?? ''}",
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                // Visiting hours
                Text(_getVisitingHours(),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),

                // Reviews
                if (_reviews.isNotEmpty) ...[
                  const Text('Reviews',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._reviews.take(5).map((review) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[200],
                              child: Text(
                                (review['patient']?['fullName'] ?? 'U')
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        review['patient']?['fullName'] ??
                                            'User',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const Spacer(),
                                      Row(children: [
                                        const Icon(Icons.star,
                                            size: 14, color: Colors.orange),
                                        Text(' ${review['rating'] ?? 'N/A'}'),
                                      ]),
                                    ],
                                  ),
                                  if (review['comment'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(review['comment'],
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],

                // Book Now Button
                if (currentUserRole != 'doctor' &&
                    widget.doctor.id !=
                        Provider.of<UserProvider>(context, listen: false)
                            .user
                            ?.id) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 65,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookAppointmentScreen(doctor: widget.doctor),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryLight,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('Book Now',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text("â€¢ ",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(text, style: const TextStyle(fontSize: 17)),
      ]),
    );
  }

  String _getVisitingHours() {
    if (widget.doctor.weeklySchedule == null ||
        widget.doctor.weeklySchedule!.isEmpty) {
      return 'Visiting Hours: Not set';
    }
    List<String> activeDays = [];
    for (var schedule in widget.doctor.weeklySchedule!) {
      if (schedule.isActive && schedule.slots.isNotEmpty) {
        activeDays.add(schedule.day.substring(0, 3));
      }
    }
    if (activeDays.isEmpty) return 'Visiting Hours: Not set';
    if (activeDays.length <= 3)
      return 'Visiting Hours: ${activeDays.join(', ')}';
    return 'Visiting Hours: ${activeDays.first}-${activeDays.last}';
  }
}
