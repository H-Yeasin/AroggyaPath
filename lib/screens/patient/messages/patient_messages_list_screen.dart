import 'package:arogya_path3/screens/patient/navigation/patient_main_navigation.dart';
import 'package:arogya_path3/screens/shared/messages/messages_list_screen.dart';
import 'package:flutter/material.dart';

class PatientMessagesListScreen extends StatelessWidget {
  final bool showBackButton;

  const PatientMessagesListScreen({
    super.key,
    this.showBackButton = false,
  });

  static Widget _buildPatientHome(BuildContext context) {
    return const PatientMainNavigation();
  }

  @override
  Widget build(BuildContext context) {
    return MessagesListScreen(
      counterpartFallbackName: 'Doctor',
      roleBadge: 'Dr.',
      showBackButton: showBackButton,
      backDestinationBuilder: showBackButton ? _buildPatientHome : null,
    );
  }
}
