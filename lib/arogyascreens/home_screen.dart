import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/const.dart';
import '../components/widgets/list_of_doctor.dart';
// Hospital booking temporarily disabled during migration
// import 'package:arogya_path3/hospital/appoinment.dart';
import '../models/emergency_contacts.dart';
import '../models/symptom.dart';
import 'doctor_details_screen.dart';

class DoctorAppoinmentHomeScreen extends StatefulWidget {
  const DoctorAppoinmentHomeScreen({super.key});

  @override
  State<DoctorAppoinmentHomeScreen> createState() =>
      _DoctorAppoinmentHomeScreenState();
}

class _DoctorAppoinmentHomeScreenState
    extends State<DoctorAppoinmentHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerParts(),
          const SizedBox(height: 20),
          clinicAndHomeVisit(),
          const SizedBox(height: 30),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              "সুস্বাস্থ্যের জন্য",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -.5,
                color: black,
              ),
            ),
          ),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                ...List.generate(
                  symptoms.length,
                  (index) => Padding(
                    padding: index == 0
                        ? const EdgeInsets.only(left: 15, right: 15)
                        : const EdgeInsets.only(right: 15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 15),
                      decoration: BoxDecoration(
                        color: grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundImage: AssetImage(
                              symptoms[index].image,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            symptoms[index].label,
                            style: const TextStyle(
                              fontSize: 16,
                              color: black,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 35),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              "জরুরি ফোন নম্বর: মনে রাখুন, সহায়তা নিন",
              style: TextStyle(
                fontSize: 18,
                color: black,
                letterSpacing: -.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Number of items per row
                crossAxisSpacing: 16, // Spacing between columns
                mainAxisSpacing: 14, // Spacing between rows
                childAspectRatio: 3 / 4, // Adjust the aspect ratio as needed
              ),
              itemCount: emergencyContacts.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DoctorDetailScreen(
                          doctor: emergencyContacts[index],
                        ),
                      ),
                    );
                  },
                  child: ListOfDoctor(
                    doctor: emergencyContacts[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Padding clinicAndHomeVisit() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Hospital booking temporarily disabled during migration to
                // location-based doctor finding
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Hospital booking is being upgraded to doctor appointments. Coming soon!',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
                // Old hospital booking code preserved for future re-enable:
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => const AppointmentPage(),
                //   ),
                // );
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: purple.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 5,
                      offset: const Offset(-0, 10),
                    ),
                  ],
                  color: purple,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.add_circle,
                      size: 60,
                      color: Colors.white,
                    ),
                    SizedBox(height: 40),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hospital visit",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          "Make an appoinment",
                          style: TextStyle(
                            color: Colors.white38,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: grey.withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ],
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: purple.withValues(alpha: 0.15),
                        shape: BoxShape.circle),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.car_crash_outlined,
                      size: 30,
                      color: purple,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Emergency",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        "Call an Ambulance",
                        style: TextStyle(
                          color: Colors.black38,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Padding headerParts() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: FutureBuilder(
        future: fetchUsername(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Loading...", style: TextStyle(fontSize: 32));
          } else if (snapshot.hasError) {
            return const Text("Error", style: TextStyle(fontSize: 32));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Text("Welcome, User", style: TextStyle(fontSize: 22));
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "Welcome ${snapshot.data!}", // Username fetched from Firebase
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Image.asset(
                    "assets/doctor-appoinment/hand.png",
                    height: 40,
                    width: 40,
                  ),
                ],
              ),
              const CircleAvatar(
                radius: 27,
                child: Icon(
                  Icons.person,
                  size: 30,
                  color: purple,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

// Fetch username from SharedPreferences (saved on JWT login)
  Future<String?> fetchUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_full_name');
    } catch (e) {
      debugPrint("Error fetching username: $e");
      return null;
    }
  }
}
