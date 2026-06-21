import 'package:arogya_path3/screens/shared/messages/messages_list_screen.dart';
import 'package:flutter/material.dart';

class DoctorMessagesListScreen extends StatelessWidget {
  final bool showBackButton;

  const DoctorMessagesListScreen({
    super.key,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return MessagesListScreen(
      counterpartFallbackName: 'Patient',
      roleBadge: 'Pt.',
      showBackButton: showBackButton,
    );
  }
}
