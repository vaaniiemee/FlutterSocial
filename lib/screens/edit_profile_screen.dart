import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../providers/profile_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/common/loading_overlay.dart';
import '../constants/app_constants.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _websiteController = TextEditingController();
  final _locationController = TextEditingController();
  
  File? _selectedProfileImage;
  File? _selectedBannerImage;
  bool _isLoading = false;
  List<String> _selectedInterests = [];
  List<String> _availableInterests = [
    'Photography', 'Travel', 'Food', 'Fitness', 'Music', 'Art', 'Technology',
    'Fashion', 'Sports', 'Reading', 'Gaming', 'Cooking', 'Dancing', 'Writing',
    'Design', 'Business', 'Education', 'Health', 'Nature', 'Movies', 'Fashion',
    'Beauty', 'Pets', 'Gardening', 'Crafting', 'Volunteering', 'Meditation'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userData = ref.read(userDataProvider);
    userData.whenData((data) {
      if (data != null) {
        _nameController.text = data['name'] ?? '';
        _usernameController.text = data['username'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _websiteController.text = data['website'] ?? '';
        _locationController.text = data['location'] ?? '';
        _selectedInterests = List<String>.from(data['interests'] ?? []);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isBanner}) async {
    try {
      final file = await ref.read(profileNotifierProvider.notifier).pickImage(isBanner: isBanner);
      if (file != null) {
        setState(() {
          if (isBanner) {
            _selectedBannerImage = file;
          } else {
            _selectedProfileImage = file;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, e.toString());
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload images first
      if (_selectedProfileImage != null) {
        await ref.read(profileNotifierProvider.notifier)
            .uploadProfileImage(_selectedProfileImage!, isBanner: false);
      }

      if (_selectedBannerImage != null) {
        await ref.read(profileNotifierProvider.notifier)
            .uploadProfileImage(_selectedBannerImage!, isBanner: true);
      }

      // Update profile data
      await ref.read(profileNotifierProvider.notifier).updateProfile(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        website: _websiteController.text.trim(),
        location: _locationController.text.trim(),
        interests: _selectedInterests,
      );

      if (mounted) {
        SuccessSnackBar.show(context, 'Profile updated successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: AppConstants.fontWeightSemiBold,
          ),
        ),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: AppConstants.primaryColor,
                fontWeight: AppConstants.fontWeightSemiBold,
              ),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: userData.when(
          data: (data) {
            if (data == null) {
              return const CustomErrorWidget(
                message: 'Failed to load profile data',
                icon: Icons.person_off,
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Banner Image
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                        color: Colors.grey[200],
                        image: _selectedBannerImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedBannerImage!) as ImageProvider<Object>,
                                fit: BoxFit.cover,
                              )
                            : data['bannerURL'] != null
                                ? DecorationImage(
                                    image: NetworkImage(data['bannerURL'] as String) as ImageProvider<Object>,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: Stack(
                        children: [
                          if (_selectedBannerImage == null && data['bannerURL'] == null)
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: AppConstants.iconSizeXXLarge,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: AppConstants.spacingSmall),
                                  Text(
                                    'Add Banner',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Positioned(
                            bottom: AppConstants.spacingMedium,
                            right: AppConstants.spacingMedium,
                            child: FloatingActionButton.small(
                              onPressed: () => _pickImage(isBanner: true),
                              backgroundColor: AppConstants.primaryColor,
                              child: const Icon(Icons.camera_alt, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.spacingLarge),
                    
                    // Profile Image
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _selectedProfileImage != null
                                ? FileImage(_selectedProfileImage!) as ImageProvider<Object>?
                                : data['photoURL'] != null
                                    ? NetworkImage(data['photoURL'] as String) as ImageProvider<Object>?
                                    : null,
                            child: _selectedProfileImage == null && data['photoURL'] == null
                                ? Icon(
                                    Icons.person,
                                    size: AppConstants.iconSizeXXLarge,
                                    color: Colors.grey[400],
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: FloatingActionButton.small(
                              onPressed: () => _pickImage(isBanner: false),
                              backgroundColor: AppConstants.primaryColor,
                              child: const Icon(Icons.camera_alt, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.spacingXLarge),
                    
                    // Profile Form
                    CustomTextField(
                      controller: _nameController,
                      labelText: 'Name',
                      isRequired: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: AppConstants.spacingMedium),
                    
                    CustomTextField(
                      controller: _usernameController,
                      labelText: 'Username',
                      hintText: '@username',
                      isRequired: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        if (value.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                          return 'Username can only contain letters, numbers, and underscores';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: AppConstants.spacingMedium),
                    
                    CustomTextField(
                      controller: _bioController,
                      labelText: 'Bio',
                      hintText: 'Tell us about yourself',
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: AppConstants.spacingMedium),
                    
                    CustomTextField(
                      controller: _websiteController,
                      labelText: 'Website',
                      hintText: 'https://example.com',
                      keyboardType: TextInputType.url,
                    ),
                    
                    const SizedBox(height: AppConstants.spacingMedium),
                    
                    CustomTextField(
                      controller: _locationController,
                      labelText: 'Location',
                      hintText: 'City, Country',
                    ),
                    
                    const SizedBox(height: AppConstants.spacingLarge),
                    
                    // Interests Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Interests',
                        style: GoogleFonts.poppins(
                          fontSize: AppConstants.fontSizeLarge,
                          fontWeight: AppConstants.fontWeightSemiBold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.spacingMedium),
                    
                    Wrap(
                      spacing: AppConstants.spacingSmall,
                      runSpacing: AppConstants.spacingSmall,
                      children: _availableInterests.map((interest) {
                        final isSelected = _selectedInterests.contains(interest);
                        return FilterChip(
                          label: Text(interest),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedInterests.add(interest);
                              } else {
                                _selectedInterests.remove(interest);
                              }
                            });
                          },
                          selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
                          checkmarkColor: AppConstants.primaryColor,
                          labelStyle: GoogleFonts.poppins(
                            color: isSelected ? AppConstants.primaryColor : AppConstants.textPrimary,
                            fontWeight: isSelected ? AppConstants.fontWeightSemiBold : AppConstants.fontWeightNormal,
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: AppConstants.spacingXXLarge),
                    
                    CustomButton(
                      text: 'Save Changes',
                      onPressed: _isLoading ? null : _saveProfile,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
            ),
          ),
          error: (error, stack) => CustomErrorWidget(
            message: 'Failed to load profile data',
            onRetry: () {
              ref.invalidate(userDataProvider);
            },
          ),
        ),
      ),
    );
  }
}
