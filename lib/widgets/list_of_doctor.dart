import 'package:arogya_path3/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import '../../models/emergency_contacts.dart';

class ListOfDoctor extends StatelessWidget {
  final EmergencyContact doctor;
  const ListOfDoctor({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      width: MediaQuery.of(context).size.width / 2.24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: grey.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Color(doctor.color),
            backgroundImage: AssetImage(
              doctor.image,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            doctor.name,
            style: const TextStyle(
              fontSize: 15,
              letterSpacing: -.5,
              color: black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            doctor.specialist,
            style: const TextStyle(
                letterSpacing: 0,
                color: Colors.black54,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
