import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Explore Content',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.fontSizeLarge,
                fontWeight: AppConstants.fontWeightMedium,
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover posts and content from other users',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.fontSizeMedium,
                color: AppConstants.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}