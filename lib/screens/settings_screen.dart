import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/error_widget.dart';
import '../constants/app_constants.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: AppConstants.fontWeightSemiBold,
          ),
        ),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLarge),
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            icon: Icons.person,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip,
            title: 'Privacy',
            subtitle: 'Control your privacy settings',
            onTap: () {
              _showComingSoon(context, 'Privacy Settings');
            },
          ),
          _buildSettingsTile(
            icon: Icons.security,
            title: 'Security',
            subtitle: 'Password and security options',
            onTap: () {
              _showComingSoon(context, 'Security Settings');
            },
          ),
          
          const SizedBox(height: AppConstants.spacingXLarge),
          
          // App Section
          _buildSectionHeader('App'),
          _buildSettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage your notifications',
            onTap: () {
              _showComingSoon(context, 'Notification Settings');
            },
          ),
          _buildSettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'Change app language',
            onTap: () {
              _showComingSoon(context, 'Language Settings');
            },
          ),
          _buildSettingsTile(
            icon: Icons.dark_mode,
            title: 'Theme',
            subtitle: 'Light or dark mode',
            onTap: () {
              _showComingSoon(context, 'Theme Settings');
            },
          ),
          
          const SizedBox(height: AppConstants.spacingXLarge),
          
          // Support Section
          _buildSectionHeader('Support'),
          _buildSettingsTile(
            icon: Icons.help,
            title: 'Help Center',
            subtitle: 'Get help and support',
            onTap: () {
              _showComingSoon(context, 'Help Center');
            },
          ),
          _buildSettingsTile(
            icon: Icons.bug_report,
            title: 'Report a Bug',
            subtitle: 'Help us improve the app',
            onTap: () {
              _showComingSoon(context, 'Bug Report');
            },
          ),
          _buildSettingsTile(
            icon: Icons.info,
            title: 'About',
            subtitle: 'App version and info',
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          
          const SizedBox(height: AppConstants.spacingXLarge),
          
          // Danger Zone
          _buildSectionHeader('Danger Zone'),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            onTap: () => _showLogoutDialog(context, ref),
            isDestructive: true,
          ),
          _buildSettingsTile(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            onTap: () {
              _showComingSoon(context, 'Delete Account');
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppConstants.spacingMedium,
        top: AppConstants.spacingLarge,
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: AppConstants.fontSizeMedium,
          fontWeight: AppConstants.fontWeightSemiBold,
          color: AppConstants.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSmall),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: AppConstants.defaultShadow,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? AppConstants.errorColor : AppConstants.primaryColor,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: AppConstants.fontSizeLarge,
            fontWeight: AppConstants.fontWeightMedium,
            color: isDestructive ? AppConstants.errorColor : AppConstants.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: AppConstants.fontSizeMedium,
            color: AppConstants.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: AppConstants.iconSizeSmall,
          color: AppConstants.textTertiary,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Coming Soon',
          style: GoogleFonts.poppins(
            fontWeight: AppConstants.fontWeightSemiBold,
          ),
        ),
        content: Text(
          '$feature will be available in a future update.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: AppConstants.primaryColor,
                fontWeight: AppConstants.fontWeightSemiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 MeetPlace. All rights reserved.',
      children: [
        const SizedBox(height: AppConstants.spacingMedium),
        Text(
          'Connect with people around the world and discover new opportunities.',
          style: GoogleFonts.poppins(),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sign Out',
          style: GoogleFonts.poppins(
            fontWeight: AppConstants.fontWeightSemiBold,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppConstants.textSecondary,
                fontWeight: AppConstants.fontWeightMedium,
              ),
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authNotifierProvider);
              final isLoading = authState.isLoading;
              
              return TextButton(
                onPressed: isLoading ? null : () async {
                  Navigator.of(context).pop();
                  
                  try {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    
                    if (context.mounted) {
                      SuccessSnackBar.show(context, 'Signed out successfully');
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ErrorSnackBar.show(context, 'Failed to sign out. Please try again.');
                    }
                  }
                },
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.errorColor),
                        ),
                      )
                    : Text(
                        'Sign Out',
                        style: GoogleFonts.poppins(
                          color: AppConstants.errorColor,
                          fontWeight: AppConstants.fontWeightSemiBold,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}
