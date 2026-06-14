import 'package:flutter/material.dart';
import '../home/patient_home_screen.dart';
import '../appointments/patient_appointments_screen.dart';
import '../profile/patient_profile_screen.dart';
import '../messages/patient_messages_list_screen.dart';

/// Patient Main Navigation — 4-tab bottom nav:
///   0: Home         → PatientHomeScreen (Google Map + nearby doctors)
///   1: Appointments → PatientAppointmentsScreen
///   2: Messages     → PatientMessagesListScreen (Agora Chat)
///   3: Profile      → PatientProfileScreen

class PatientMainNavigation extends StatefulWidget {
  const PatientMainNavigation({super.key});

  @override
  State<PatientMainNavigation> createState() => _PatientMainNavigationState();
}

class _PatientMainNavigationState extends State<PatientMainNavigation> {
  int _currentIndex = 0;
  final List<Widget?> _initializedScreens = List.filled(4, null);

  Widget _getScreen(int index) {
    if (_initializedScreens[index] == null) {
      switch (index) {
        case 0:
          _initializedScreens[index] = const PatientHomeScreen();
        case 1:
          _initializedScreens[index] = const PatientAppointmentsScreen();
        case 2:
          _initializedScreens[index] = const PatientMessagesListScreen();
        case 3:
          _initializedScreens[index] = const PatientProfileScreen();
      }
    }
    return _initializedScreens[index]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(4, (index) {
          if (index == _currentIndex || _initializedScreens[index] != null) {
            return _getScreen(index);
          }
          return const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              spreadRadius: 1,
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFF1664CD),
          unselectedItemColor: const Color(0xFF4B5563),
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 5),
                  child: Icon(Icons.home_outlined, size: 28)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 5),
                  child: Icon(Icons.home, size: 28)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 5),
                  child: Icon(Icons.calendar_today_outlined, size: 26)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 5),
                  child: Icon(Icons.calendar_today, size: 26)),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 5),
                  child: Icon(Icons.message_outlined, size: 26)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 5),
                  child: Icon(Icons.message, size: 26)),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 5),
                  child: Icon(Icons.person_outline, size: 28)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 5),
                  child: Icon(Icons.person, size: 28)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
