import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color secondaryColor = Color(0xFF3B82F6);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  
  // Category Colors
  static const Color buySellColor = Color(0xFF10B981); // Green
  static const Color homeColor = Color(0xFF8B5CF6); // Purple
  static const Color carsColor = Color(0xFFF59E0B); // Orange
  static const Color documentsColor = Color(0xFF6B7280); // Gray
  static const Color newsColor = Color(0xFFEF4444); // Red
  static const Color helpColor = Color(0xFF3B82F6); // Blue
  static const Color jobsColor = Color(0xFF059669); // Emerald
  static const Color eventsColor = Color(0xFFEC4899); // Pink
  static const Color foodColor = Color(0xFFF97316); // Orange
  static const Color travelColor = Color(0xFF0EA5E9); // Sky Blue
  static const Color educationColor = Color(0xFF7C3AED); // Violet
  static const Color healthColor = Color(0xFFDC2626); // Red
  static const Color technologyColor = Color(0xFF1E40AF); // Indigo
  static const Color sportsColor = Color(0xFF16A34A); // Green
  static const Color entertainmentColor = Color(0xFF9333EA); // Purple
  
  // Text Colors
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  
  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;
  
  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;
  
  // Font Sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 24.0;
  static const double fontSizeTitle = 28.0;
  static const double fontSizeHeading = 32.0;
  
  // Font Weights
  static const FontWeight fontWeightNormal = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  
  // Animation Durations
  static const Duration animationDurationFast = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 400);
  static const Duration animationDurationSlow = Duration(milliseconds: 800);
  static const Duration animationDurationVerySlow = Duration(seconds: 2);
  
  // Button Heights
  static const double buttonHeightSmall = 40.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;
  
  // Icon Sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;
  static const double iconSizeXXLarge = 64.0;
  
  // Shadow
  static List<BoxShadow> get defaultShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
  
  // App Strings
  static const String appName = 'MeetPlace';
  static const String appDescription = 'Connect with people around the world';
  
  // Error Messages
  static const String errorGeneric = 'An error occurred. Please try again.';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorLocationPermission = 'Location permission denied';
  static const String errorLocationService = 'Location services are disabled';
  
  // Success Messages
  static const String successLocationDetected = 'Location detected successfully';
  static const String successDataSaved = 'Data saved successfully';
  static const String successSignedOut = 'Signed out successfully';
  
  // Post Categories
  static const List<Map<String, dynamic>> postCategories = [
    {'id': 'buy_sell', 'name': 'Buy/Sell', 'icon': Icons.shopping_cart, 'color': buySellColor},
    {'id': 'home', 'name': 'Home', 'icon': Icons.home, 'color': homeColor},
    {'id': 'cars', 'name': 'Cars', 'icon': Icons.directions_car, 'color': carsColor},
    {'id': 'documents', 'name': 'Documents', 'icon': Icons.description, 'color': documentsColor},
    {'id': 'news', 'name': 'News', 'icon': Icons.newspaper, 'color': newsColor},
    {'id': 'help', 'name': 'Help', 'icon': Icons.help_outline, 'color': helpColor},
    {'id': 'jobs', 'name': 'Jobs', 'icon': Icons.work, 'color': jobsColor},
    {'id': 'events', 'name': 'Events', 'icon': Icons.event, 'color': eventsColor},
    {'id': 'food', 'name': 'Food', 'icon': Icons.restaurant, 'color': foodColor},
    {'id': 'travel', 'name': 'Travel', 'icon': Icons.flight, 'color': travelColor},
    {'id': 'education', 'name': 'Education', 'icon': Icons.school, 'color': educationColor},
    {'id': 'health', 'name': 'Health', 'icon': Icons.local_hospital, 'color': healthColor},
    {'id': 'technology', 'name': 'Technology', 'icon': Icons.computer, 'color': technologyColor},
    {'id': 'sports', 'name': 'Sports', 'icon': Icons.sports, 'color': sportsColor},
    {'id': 'entertainment', 'name': 'Entertainment', 'icon': Icons.movie, 'color': entertainmentColor},
  ];

  // Helper function to get category color by ID
  static Color getCategoryColor(String categoryId) {
    final category = postCategories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => {'color': primaryColor},
    );
    return category['color'] as Color;
  }
}
