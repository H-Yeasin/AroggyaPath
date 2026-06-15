import 'package:arogya_path3/core/constants/app_constants.dart';
import 'package:arogya_path3/models/emergency_contacts.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactDetailsScreen extends StatelessWidget {
  final EmergencyContact doctor;
  const EmergencyContactDetailsScreen({
    super.key,
    required this.doctor,
  });

  Future<void> _makeCall(String number) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $number';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: purple,
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Color(doctor.color),
                  backgroundImage: NetworkImage(
                    doctor.image,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  " ( ${doctor.specialist} )",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  doctor.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(top: 20),
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "About",
                            style: TextStyle(
                              fontSize: 18,
                              color: black,
                              letterSpacing: 0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            doctor.about,
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              letterSpacing: 0,
                              color: black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Lead by",
                            style: TextStyle(
                              fontSize: 18,
                              color: black,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: purple.withValues(alpha: 0.3),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: purple,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doctor.location,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        letterSpacing: -.5,
                                        color: black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.visible,
                                      softWrap:
                                          true, // Ensures the text truncates if it's too long
                                      // maxLines:1, // Limits text to a single line
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: grey.withValues(alpha: 0.3),
              blurRadius: 5,
            ),
          ],
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "à¦•à¦² à¦°à§‡à¦Ÿ",
                  style: TextStyle(
                    letterSpacing: 0,
                    color: grey,
                  ),
                ),
                Text(
                  "à§³${doctor.price}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: black,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _makeCall(doctor.specialist),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: purple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize
                        .min, // Ensures the row takes only the space it needs
                    children: [
                      Icon(
                        Icons.call,
                        color: Colors.white,
                      ),
                      SizedBox(
                          width: 8), // Adds spacing between the icon and text
                      Text(
                        "à¦à¦–à¦¨à¦‡ à¦•à¦² à¦•à¦°à§à¦¨",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
