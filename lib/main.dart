import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/country_selection_screen.dart';
import 'screens/goals_selection_screen.dart';
import 'screens/home_screen.dart';
import 'constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  } catch (e) {
    // App Check is optional for development
  }
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: GoogleFonts.poppins().fontFamily,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: AppConstants.backgroundColor,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: AppConstants.fontSizeXLarge,
            fontWeight: AppConstants.fontWeightSemiBold,
            color: AppConstants.textPrimary,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            elevation: 2,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (user) {
        if (user != null) {
          return const OnboardingWrapper();
        }
        return const AuthScreen();
      },
      loading: () => const Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: AppConstants.iconSizeXXLarge,
                color: AppConstants.errorColor,
              ),
              const SizedBox(height: AppConstants.spacingLarge),
              Text(
                'Authentication Error',
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.fontSizeXLarge,
                  fontWeight: AppConstants.fontWeightSemiBold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSmall),
              Text(
                'Please restart the app',
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.fontSizeMedium,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingWrapper extends ConsumerWidget {
  const OnboardingWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider);
    
    return userData.when(
      data: (data) {
        if (data == null) {
          return const CountrySelectionScreen();
        }
        
        final hasCountry = data['country'] != null;
        final hasGoal = data['goal'] != null;

        if (hasCountry && hasGoal) {
          return const HomeScreen();
        } else if (hasCountry && !hasGoal) {
          return const GoalsSelectionScreen();
        } else {
          return const CountrySelectionScreen();
        }
      },
      loading: () => const Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: AppConstants.iconSizeXXLarge,
                color: AppConstants.errorColor,
              ),
              const SizedBox(height: AppConstants.spacingLarge),
              Text(
                'Error loading user data',
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.fontSizeXLarge,
                  fontWeight: AppConstants.fontWeightSemiBold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSmall),
              Text(
                'Please try again',
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.fontSizeMedium,
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingLarge),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(userDataProvider);
                },
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    fontWeight: AppConstants.fontWeightSemiBold,
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


