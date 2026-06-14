import 'package:flutter/material.dart';

import '../login_screen.dart';
import '../signup_screen.dart';

/// Shown before login/signup — user picks Patient or Doctor.
/// Choosing "Doctor" reveals doctor-specific registration fields later.
class SelectProfileScreen extends StatefulWidget {
  const SelectProfileScreen({super.key});

  @override
  State<SelectProfileScreen> createState() => _SelectProfileScreenState();
}

class _SelectProfileScreenState extends State<SelectProfileScreen> {
  String? _selectedRole; // 'Patient' or 'Doctor'

  void _continueToLogin() {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your profile type'),
          backgroundColor: Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          initialRole: _selectedRole!.toLowerCase(),
        ),
      ),
    );
  }

  void _continueToSignup() {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your profile type'),
          backgroundColor: Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SignupScreen(initialRole: _selectedRole!.toLowerCase()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPatient = _selectedRole == 'Patient';
    final isDoctor = _selectedRole == 'Doctor';
    final hasSelection = _selectedRole != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const Spacer(flex: 1),

            // Logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.medical_services,
                  size: 56, color: Color(0xFF1664CD)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to AroggyaPath',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2C49),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please select your profile to continue',
              style: TextStyle(fontSize: 15, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 6),
            Text(
              hasSelection
                  ? (_selectedRole == 'Patient'
                      ? 'You can find and book doctors near you'
                      : 'Manage appointments and help patients')
                  : 'Who are you?',
              style: TextStyle(
                fontSize: 13,
                color: hasSelection
                    ? (isPatient
                        ? const Color(0xFF1664CD)
                        : const Color(0xFF4CAF50))
                    : const Color(0xFF4B5563),
                fontWeight: hasSelection ? FontWeight.w600 : FontWeight.normal,
              ),
            ),

            const Spacer(flex: 1),

            // Role cards
            Row(children: [
              Expanded(
                child: _buildRoleCard(
                  title: 'Patient',
                  subtitle: 'Find & book\ndoctors nearby',
                  icon: Icons.person,
                  isSelected: isPatient,
                  color: const Color(0xFF1664CD),
                  onTap: () => setState(() => _selectedRole = 'Patient'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRoleCard(
                  title: 'Doctor',
                  subtitle: 'Manage patients\n& appointments',
                  icon: Icons.medical_services,
                  isSelected: isDoctor,
                  color: const Color(0xFF4CAF50),
                  onTap: () => setState(() => _selectedRole = 'Doctor'),
                ),
              ),
            ]),

            const Spacer(flex: 1),

            // Doctor-specific fields info
            if (isDoctor)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF4CAF50)
                      .withOpacity(0.3)),
                ),
                child: Column(children: [
                  Row(children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFF4CAF50), size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Doctor registration requires:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  _buildDoctorReq('Medical License Number'),
                  _buildDoctorReq('Medical Specialty'),
                  _buildDoctorReq('Years of Experience'),
                ]),
              ),

            // Continue → Login
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _continueToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasSelection
                      ? (isPatient
                          ? const Color(0xFF1664CD)
                          : const Color(0xFF4CAF50))
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: const Text('Log in',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),

            // Continue → Signup
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: _continueToSignup,
                style: OutlinedButton.styleFrom(
                  foregroundColor: hasSelection
                      ? (isPatient
                          ? const Color(0xFF1664CD)
                          : const Color(0xFF4CAF50))
                      : Colors.grey,
                  side: BorderSide(
                    color: hasSelection
                        ? (isPatient
                            ? const Color(0xFF1664CD)
                            : const Color(0xFF4CAF50))
                        : Colors.grey,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Create Account',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.25),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 6))]
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: isSelected ? color : Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: isSelected ? color : const Color(0xFF1B2C49))),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13,
                  color: isSelected ? color.withOpacity(0.8) : Colors.grey,
                  height: 1.4)),
        ]),
      ),
    );
  }

  Widget _buildDoctorReq(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF33691E))),
      ]),
    );
  }
}
