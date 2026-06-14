import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../arogyascreens/main_page.dart';
import '../onboarding/select_profile_screen.dart';
import '../patient/navigation/patient_main_navigation.dart';
import '../doctor/navigation/doctor_main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;

      // Check login status
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final role = prefs.getString('user_role')?.toLowerCase();

      if (token != null && token.isNotEmpty) {
        if (role == 'patient') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const PatientMainNavigation()),
          );
        } else if (role == 'doctor') {
          // Doctor → new doctor dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const DoctorMainNavigation()),
          );
        } else {
          // Other roles → old main page (fallback)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainPage()),
          );
        }
      } else {
        // Not logged in → show role selection first
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const SelectProfileScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logos/logoArogya.png',
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return Column(
                  children: [
                    Icon(Icons.medical_services,
                        size: 100,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    const Text(
                      'AroggyaPath',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'AroggyaPath',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F2F32),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your Health Companion',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFA2A8B4),
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
