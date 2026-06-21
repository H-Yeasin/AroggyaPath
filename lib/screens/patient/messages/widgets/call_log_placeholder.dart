import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';

class CallLogPlaceholder extends StatelessWidget {
  final bool isMe;
  final String text;

  const CallLogPlaceholder({
    super.key,
    required this.isMe,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    AppTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.call, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Text(
                text.replaceAll('call:', ''),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
