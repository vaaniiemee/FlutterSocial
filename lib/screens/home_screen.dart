import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    print('HomeScreen: build called');
    try {
      return Scaffold(
        appBar: AppBar(
          title: const Text('MeetPlace'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                print('HomeScreen: Sign out button pressed');
                try {
                  await AuthService().signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Signed out successfully'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  print('HomeScreen: Error signing out: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error signing out: $e'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
        body: const Center(
          child: Text('Welcome to MeetPlace!'),
        ),
      );
    } catch (e) {
      print('HomeScreen: Error in build: $e');
      return Scaffold(
        body: Center(
          child: Text('Error loading HomeScreen: $e'),
        ),
      );
    }
  }
} 