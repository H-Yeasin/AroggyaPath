import 'package:arogya_path3/widgets/common/custom_button.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            ),
            icon: const Icon(Icons.clear),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text("Registration Successful!",
                  style: Theme.of(context).textTheme.headlineMedium),
              Image.asset('assets/images/emailVerify.png'),
              const SizedBox(height: 35),
              const Text(
                "Your account has been created. Please log in.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CustomButton2(
                  buttonText: "Go to Login",
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
