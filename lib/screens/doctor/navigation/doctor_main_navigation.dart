import 'package:arogya_path3/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../messages/doctor_messages_list_screen.dart';
import '../appointments/doctor_appointments_screen.dart';
import '../home/doctor_home_screen.dart';
import '../profile/doctor_profile_screen.dart';
import '../../../services/call_manager_service.dart';
import '../../../services/socket_service.dart';

/// Doctor Main Navigation â€” 4-tab bottom nav:
///   0: Home         â†’ DoctorHomeScreen (appointment overview + stats)
///   1: Appointments â†’ DoctorAppointmentsScreen (pending/accepted/completed)
///   2: Messages     → Appointment-based chat (Socket.IO + REST)
///   3: Profile      â†’ DoctorProfileScreen

class DoctorMainNavigation extends StatefulWidget {
  const DoctorMainNavigation({super.key});

  @override
  State<DoctorMainNavigation> createState() => _DoctorMainNavigationState();
}

class _DoctorMainNavigationState extends State<DoctorMainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DoctorHomeScreen(),
    DoctorAppointmentsScreen(),
    DoctorMessagesListScreen(),
    DoctorProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeCallSignaling();
    });
  }

  Future<void> _initializeCallSignaling() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null || userId.isEmpty) return;

    await SocketService.instance.connect(userId);
    if (!mounted) return;
    CallManager.instance.initialize(context);
  }

  @override
  void dispose() {
    CallManager.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 15,
                offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: colors.primary,
          unselectedItemColor: colors.bodyText,
          selectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 28),
                activeIcon: Icon(Icons.home, size: 28),
                label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined, size: 26),
                activeIcon: Icon(Icons.calendar_today, size: 26),
                label: 'Appointments'),
            BottomNavigationBarItem(
                icon: Icon(Icons.message_outlined, size: 26),
                activeIcon: Icon(Icons.message, size: 26),
                label: 'Messages'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline, size: 28),
                activeIcon: Icon(Icons.person, size: 28),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Scaffold(
      backgroundColor: colors.surfaceAlt,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: colors.primary.withAlpha(25), shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: colors.primary)),
          const SizedBox(height: 24),
          Text(title,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.heading)),
          const SizedBox(height: 8),
          Text('Coming soon',
              style: TextStyle(fontSize: 14, color: colors.bodyText)),
        ]),
      ),
    );
  }
}
