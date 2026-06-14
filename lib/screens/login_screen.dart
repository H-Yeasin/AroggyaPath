import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';
import 'forgatepass_screen.dart';
import '../arogyascreens/main_page.dart';
import '../components/custom_button.dart';
import '../components/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } else if (mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 145, 218, 252),
              Color.fromARGB(255, 193, 233, 251),
              Colors.white,
              Colors.white,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(255, 166, 217, 240),
                    spreadRadius: 3,
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.login, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              "Sign in with email",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              textAlign: TextAlign.center,
              "Provide your email and password",
              style: TextStyle(
                fontSize: 15,
                color: Color.fromARGB(255, 153, 161, 83),
              ),
            ),
            const SizedBox(height: 20),
            CustomTextfield(
              prefixIcon: const Icon(Icons.email,
                  color: Color.fromARGB(255, 153, 161, 83), size: 20),
              controller: _emailController,
              hintText: "Email",
              obsecureText: false,
              width: 350,
            ),
            const SizedBox(height: 10),
            CustomTextfield(
              prefixIcon: const Icon(Icons.lock,
                  color: Color.fromARGB(255, 153, 161, 83), size: 20),
              controller: _passwordController,
              hintText: "Password",
              obsecureText: _obscurePassword,
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: const Color.fromARGB(255, 239, 86, 86),
                ),
              ),
              width: 350,
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(right: 32.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgetPassScreen()),
                  ),
                  child: const Text(
                    "Forgot password?",
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.isLoading) {
                  return const CircularProgressIndicator();
                }
                return CustomButton(
                  buttonText: "Log in",
                  onPressed: _signIn,
                );
              },
            ),
            const SizedBox(height: 15),
            CustomButton2(
              buttonText: "Create an Account",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignupScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
