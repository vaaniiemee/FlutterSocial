import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/auth_screen.dart';
import 'screens/country_selection_screen.dart';
import 'screens/goals_selection_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeetPlace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        print('AuthWrapper: connectionState = ${snapshot.connectionState}');
        print('AuthWrapper: hasData = ${snapshot.hasData}');
        print('AuthWrapper: data = ${snapshot.data}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          print('AuthWrapper: User authenticated, showing OnboardingWrapper');
          return const OnboardingWrapper();
        }
        
        print('AuthWrapper: No user, showing AuthScreen');
        return const AuthScreen();
      },
    );
  }
}

class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  bool _isLoading = true;
  bool _hasCompletedOnboarding = false;
  String? _currentStep;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    print('OnboardingWrapper: Starting _checkOnboardingStatus');
    try {
      final user = FirebaseAuth.instance.currentUser;
      print('OnboardingWrapper: Current user = ${user?.uid}');
      
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        print('OnboardingWrapper: Document exists = ${doc.exists}');
        
        if (doc.exists) {
          final data = doc.data()!;
          final hasCountry = data['country'] != null;
          final hasGoal = data['goal'] != null;
          final hasCompletedOnboarding = data['hasCompletedOnboarding'] ?? false;
          
          print('OnboardingWrapper: hasCountry = $hasCountry');
          print('OnboardingWrapper: hasGoal = $hasGoal');
          print('OnboardingWrapper: hasCompletedOnboarding = $hasCompletedOnboarding');
          
          if (mounted) {
            setState(() {
              if (hasCompletedOnboarding && hasCountry && hasGoal) {
                _hasCompletedOnboarding = true;
                _currentStep = 'completed';
                print('OnboardingWrapper: User completed onboarding');
              } else if (!hasCountry) {
                _hasCompletedOnboarding = false;
                _currentStep = 'country';
                print('OnboardingWrapper: User needs country selection');
              } else if (!hasGoal) {
                _hasCompletedOnboarding = false;
                _currentStep = 'goal';
                print('OnboardingWrapper: User needs goal selection');
              } else {
                _hasCompletedOnboarding = false;
                _currentStep = 'country';
                print('OnboardingWrapper: User needs country selection (fallback)');
              }
              _isLoading = false;
            });
          }
        } else {
          print('OnboardingWrapper: Document does not exist');
          if (mounted) {
            setState(() {
              _hasCompletedOnboarding = false;
              _currentStep = 'country';
              _isLoading = false;
            });
          }
        }
      } else {
        print('OnboardingWrapper: No user found');
        if (mounted) {
          setState(() {
            _hasCompletedOnboarding = false;
            _currentStep = 'country';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('OnboardingWrapper: Error in _checkOnboardingStatus: $e');
      if (mounted) {
        setState(() {
          _hasCompletedOnboarding = false;
          _currentStep = 'country';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('OnboardingWrapper: build called, _isLoading = $_isLoading');
    
    if (_isLoading) {
      print('OnboardingWrapper: Showing loading indicator');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    print('OnboardingWrapper: _hasCompletedOnboarding = $_hasCompletedOnboarding');
    print('OnboardingWrapper: _currentStep = $_currentStep');

    try {
      if (_hasCompletedOnboarding) {
        print('OnboardingWrapper: Returning HomeScreen');
        return const HomeScreen();
        // Временно для тестирования:
        // return const Scaffold(
        //   body: Center(
        //     child: Text('TEST: HomeScreen should be here'),
        //   ),
        // );
      } else {
        if (_currentStep == 'goal') {
          print('OnboardingWrapper: Returning GoalsSelectionScreen');
          return const GoalsSelectionScreen();
        } else {
          print('OnboardingWrapper: Returning CountrySelectionScreen');
          return const CountrySelectionScreen();
        }
      }
    } catch (e) {
      print('OnboardingWrapper: Error in build: $e');
      return const Scaffold(
        body: Center(
          child: Text('Error loading screen'),
        ),
      );
    }
  }
}


