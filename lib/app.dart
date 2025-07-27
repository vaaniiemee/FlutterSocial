import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/auth_provider.dart';
import 'state/user_provider.dart';
import 'features/auth/presentation/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/home/home_screen.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userProfile = ref.watch(userProvider);

    Widget startScreen;
    if (authState.user == null) {
      startScreen = const RegisterScreen();
    } else if (userProfile == null || userProfile.fromCountry == null || userProfile.toCountry == null || userProfile.purpose == null) {
      startScreen = const OnboardingScreen();
    } else {
      startScreen = const HomeScreen();
    }

    return MaterialApp(
      title: 'MeetPlace',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        // TODO: кастомная тема
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
      ),
      home: startScreen,
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
} 