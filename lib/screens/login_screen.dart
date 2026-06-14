import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/custom_textfield.dart';
import '../providers/auth_provider.dart';
import 'doctor/navigation/doctor_main_navigation.dart';
import 'forgatepass_screen.dart';
import 'patient/navigation/patient_main_navigation.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? initialRole;
  const LoginScreen({super.key, this.initialRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = 'patient'; // patient or doctor
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialRole == 'doctor') {
      _selectedRole = 'doctor';
      _tabController.index = 1;
    }
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedRole = _tabController.index == 0 ? 'patient' : 'doctor';
        });
      }
    });
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.login(email, password);

    if (success && mounted) {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role')?.toLowerCase();

      // Validate role match
      if (role != _selectedRole) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This account is registered as ${role ?? "unknown"}. '
              'Please select the correct role.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        // Still navigate to the correct dashboard
        if (role == 'patient') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const PatientMainNavigation()));
        } else if (role == 'doctor') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const DoctorMainNavigation()));
        }
        return;
      }

      if (role == 'patient') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const PatientMainNavigation()));
      } else if (role == 'doctor') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const DoctorMainNavigation()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unknown role. Please contact support.')),
        );
      }
    } else if (mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPatient = _selectedRole == 'patient';

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isPatient
                ? const [
                    Color(0xFFE3F2FD),
                    Color(0xFFF5F8FF),
                    Colors.white,
                    Colors.white,
                  ]
                : const [
                    Color(0xFFE8F5E9),
                    Color(0xFFF1F8E9),
                    Colors.white,
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Logo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isPatient
                            ? const Color(0xFF1664CD).withOpacity(0.15)
                            : const Color(0xFF4CAF50).withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.medical_services,
                    size: 48,
                    color: isPatient
                        ? const Color(0xFF1664CD)
                        : const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'AroggyaPath',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2C49),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your Health Companion',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 32),

                // Role selector tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: isPatient
                          ? const Color(0xFF1664CD)
                          : const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: (isPatient
                                  ? const Color(0xFF1664CD)
                                  : const Color(0xFF4CAF50))
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                    dividerColor: Colors.transparent,
                    padding: const EdgeInsets.all(4),
                    tabs: const [
                      Tab(
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person, size: 18),
                              SizedBox(width: 6),
                              Text('Patient'),
                            ]),
                      ),
                      Tab(
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.medical_services, size: 18),
                              SizedBox(width: 6),
                              Text('Doctor'),
                            ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Login form card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        isPatient
                            ? 'Sign in as Patient'
                            : 'Sign in as Doctor',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B2C49),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isPatient
                            ? 'Find and book doctors near you'
                            : 'Manage appointments and help patients',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Email
                      CustomTextfield(
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: Color(0xFF4B5563), size: 20),
                        controller: _emailController,
                        hintText: 'Email',
                        obsecureText: false,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 14),

                      // Password
                      CustomTextfield(
                        prefixIcon: const Icon(Icons.lock_outlined,
                            color: Color(0xFF4B5563), size: 20),
                        controller: _passwordController,
                        hintText: 'Password',
                        obsecureText: _obscurePassword,
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                        width: double.infinity,
                      ),
                      const SizedBox(height: 8),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForgetPassScreen()),
                          ),
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontSize: 13,
                              color: isPatient
                                  ? const Color(0xFF1664CD)
                                  : const Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Login button
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          if (auth.isLoading) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          return SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isPatient
                                    ? const Color(0xFF1664CD)
                                    : const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Log in',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Create account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?",
                              style: TextStyle(color: Color(0xFF4B5563))),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignupScreen()),
                            ),
                            child: Text(
                              ' Create Account',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPatient
                                    ? const Color(0xFF1664CD)
                                    : const Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
