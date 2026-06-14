import 'package:flutter/material.dart';

class CallLogBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;

  const CallLogBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final String type = message['callType']?.toString() ?? '';
    final String status = message['callStatus']?.toString() ?? '';
    final duration = message['duration']?.toString() ?? '';

    IconData icon;
    String label;
    switch (type) {
      case 'video':
        icon = Icons.videocam;
        label = 'Video Call';
        break;
      case 'audio':
        icon = Icons.call;
        label = 'Audio Call';
        break;
      default:
        icon = Icons.call_missed;
        label = 'Call';
    }

    if (status == 'missed' || status == 'declined') {
      icon = Icons.call_missed;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 16, color: status == 'missed' ? Colors.red : Colors.grey),
            const SizedBox(width: 8),
            Text('$label ${duration.isNotEmpty ? '($duration)' : ''}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
      ),
    );
  }
}
