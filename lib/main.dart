import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/doctor_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/dependent_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/patient/navigation/patient_main_navigation.dart';
import 'screens/patient/profile/personal_info_screen.dart';
import 'screens/patient/profile/dependents_list_screen.dart';
import 'screens/patient/profile/add_dependents_screen.dart';
import 'screens/patient/profile/edit_dependent_screen.dart';
import 'screens/patient/profile/change_password_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only for push notifications (FCM)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Initialize API service for JWT auth
  await ApiService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => DependentProvider()),
      ],
      child: MaterialApp(
        title: 'AroggyaPath',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CAF50),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/patient-home': (context) => const PatientMainNavigation(),
          '/personal-info': (context) => const PersonalInfoScreen(),
          '/dependents-list': (context) => const DependentsListScreen(),
          '/add-dependent': (context) => const AddDependentScreen(),
          '/change-password': (context) => const ChangePasswordScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/edit-dependent') {
            final dep = settings.arguments;
            if (dep != null) {
              return MaterialPageRoute(
                builder: (context) => EditDependentScreen(dependent: dep as dynamic),
              );
            }
          }
          return null;
        },
      ),
    );
  }
}
