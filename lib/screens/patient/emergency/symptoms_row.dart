import 'package:arogya_path3/core/constants/app_constants.dart';
import 'package:arogya_path3/models/symptom.dart';
import 'package:flutter/material.dart';

class SymptomsRow extends StatelessWidget {
  const SymptomsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: symptoms.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final symptom = symptoms[index];

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: AssetImage(symptom.image),
                ),
                const SizedBox(width: 8),
                Text(
                  symptom.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: black,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
