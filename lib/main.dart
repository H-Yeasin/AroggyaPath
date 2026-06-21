import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_theme.dart';
import 'firebase_options.dart';
import 'providers/appointment_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dependent_provider.dart';
import 'providers/doctor_provider.dart';
import 'providers/medical_record_provider.dart';
import 'providers/user_provider.dart';
import 'screens/doctor/navigation/doctor_main_navigation.dart';
import 'screens/onboarding/select_profile_screen.dart';
import 'screens/patient/navigation/patient_main_navigation.dart';
import 'screens/patient/profile/add_dependents_screen.dart';
import 'screens/patient/profile/change_password_screen.dart';
import 'screens/patient/profile/dependents_list_screen.dart';
import 'screens/patient/profile/edit_dependent_screen.dart';
import 'screens/patient/profile/personal_info_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

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
        ChangeNotifierProvider(create: (_) => MedicalRecordProvider()),
        ChangeNotifierProvider(create: (_) => DependentProvider()),
      ],
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final role = userProvider.user?.role ?? 'patient';
          final isDoctor = role == 'doctor';
          final colors =
              isDoctor ? AroggyaColors.doctor() : AroggyaColors.patient();

          return MaterialApp(
            title: 'AroggyaPath',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: colors.primary,
                brightness: Brightness.light,
              ),
              extensions: [colors],
              useMaterial3: true,
            ),
            home: const SplashScreen(),
            routes: {
              '/splash': (_) => const SplashScreen(),
              '/patient-home': (_) => const PatientMainNavigation(),
              '/doctor-home': (_) => const DoctorMainNavigation(),
              '/personal-info': (_) => const PersonalInfoScreen(),
              '/dependents-list': (_) => const DependentsListScreen(),
              '/add-dependent': (_) => const AddDependentScreen(),
              '/change-password': (_) => const ChangePasswordScreen(),
              '/select-profile': (_) => const SelectProfileScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/edit-dependent') {
                final dep = settings.arguments;
                if (dep != null) {
                  return MaterialPageRoute(
                    builder: (_) =>
                        EditDependentScreen(dependent: dep as dynamic),
                  );
                }
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
