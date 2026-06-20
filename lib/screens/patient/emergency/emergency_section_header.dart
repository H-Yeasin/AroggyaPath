import 'package:arogya_path3/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class EmergencySectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const EmergencySectionHeader({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: purple),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: black,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}
