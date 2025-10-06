import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/error_widget.dart';
import '../constants/app_constants.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    
    // Listen to auth errors
    ref.listen(authErrorProvider, (previous, next) {
      if (next != null && context.mounted) {
        ErrorSnackBar.show(context, next);
        ref.read(authErrorProvider.notifier).state = null;
      }
    });

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontWeight: AppConstants.fontWeightSemiBold,
          ),
        ),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: userData.when(
        data: (data) {
          if (data == null) {
            return const CustomErrorWidget(
              message: 'Failed to load profile data',
              icon: Icons.person_off,
            );
          }
          
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: _buildProfileHeader(data),
                ),
                SliverToBoxAdapter(
                  child: _buildProfileStats(data),
                ),
                SliverToBoxAdapter(
                  child: _buildProfileActions(data),
                ),
                SliverToBoxAdapter(
                  child: _buildTabBar(),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsTab(data),
                _buildInterestsTab(data),
                _buildAboutTab(data),
              ],
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
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLarge),
      child: Column(
        children: [
          // Banner Image
          if (data['bannerURL'] != null)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppConstants.spacingLarge),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                image: DecorationImage(
                  image: NetworkImage(data['bannerURL']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          
          // Profile Image and Info
          Row(
            children: [
              // Profile Image
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                    backgroundImage: data['photoURL'] != null
                        ? NetworkImage(data['photoURL'])
                        : null,
                    child: data['photoURL'] == null
                        ? Icon(
                            Icons.person,
                            size: AppConstants.iconSizeXXLarge,
                            color: AppConstants.primaryColor,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: AppConstants.spacingLarge),
              
              // Profile Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? 'User',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.fontSizeXLarge,
                        fontWeight: AppConstants.fontWeightBold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXSmall),
                    Text(
                      '@${data['username'] ?? 'username'}',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.fontSizeMedium,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    if (data['bio'] != null && data['bio'].isNotEmpty) ...[
                      const SizedBox(height: AppConstants.spacingSmall),
                      Text(
                        data['bio'],
                        style: GoogleFonts.poppins(
                          fontSize: AppConstants.fontSizeMedium,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                    ],
                    if (data['website'] != null && data['website'].isNotEmpty) ...[
                      const SizedBox(height: AppConstants.spacingSmall),
                      Row(
                        children: [
                          Icon(
                            Icons.link,
                            size: AppConstants.iconSizeSmall,
                            color: AppConstants.primaryColor,
                          ),
                          const SizedBox(width: AppConstants.spacingXSmall),
                          Text(
                            data['website'],
                            style: GoogleFonts.poppins(
                              fontSize: AppConstants.fontSizeSmall,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (data['location'] != null && data['location'].isNotEmpty) ...[
                      const SizedBox(height: AppConstants.spacingSmall),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: AppConstants.iconSizeSmall,
                            color: AppConstants.textSecondary,
                          ),
                          const SizedBox(width: AppConstants.spacingXSmall),
                          Text(
                            data['location'],
                            style: GoogleFonts.poppins(
                              fontSize: AppConstants.fontSizeSmall,
                              color: AppConstants.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLarge),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Posts', '0'),
          ),
          Expanded(
            child: _buildStatItem('Followers', '0'),
          ),
          Expanded(
            child: _buildStatItem('Following', '0'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: AppConstants.fontSizeXLarge,
            fontWeight: AppConstants.fontWeightBold,
            color: AppConstants.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: AppConstants.fontSizeMedium,
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileActions(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLarge),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Edit Profile',
              type: ButtonType.outline,
              icon: Icons.edit,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: AppConstants.spacingMedium),
          Expanded(
            child: CustomButton(
              text: 'Share Profile',
              type: ButtonType.outline,
              icon: Icons.share,
              onPressed: () {
                InfoSnackBar.show(context, 'Share profile feature coming soon!');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppConstants.primaryColor,
        labelColor: AppConstants.primaryColor,
        unselectedLabelColor: AppConstants.textSecondary,
        labelStyle: GoogleFonts.poppins(
          fontWeight: AppConstants.fontWeightSemiBold,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: AppConstants.fontWeightNormal,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.grid_on), text: 'Posts'),
          Tab(icon: Icon(Icons.favorite), text: 'Interests'),
          Tab(icon: Icon(Icons.info), text: 'About'),
        ],
      ),
    );
  }

  Widget _buildPostsTab(Map<String, dynamic> data) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: data['uid'])
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading posts'),
          );
        }

        final posts = snapshot.data?.docs ?? [];

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  size: AppConstants.iconSizeXXLarge,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: AppConstants.spacingMedium),
                Text(
                  'No posts yet',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.fontSizeLarge,
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingSmall),
                Text(
                  'Share your first post!',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.fontSizeMedium,
                    color: AppConstants.textTertiary,
                  ),
                ),
              ],
                    ),
                  );
                }

        return GridView.builder(
          padding: const EdgeInsets.all(AppConstants.spacingLarge),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index].data() as Map<String, dynamic>;
            final imageUrl = post['imageUrls']?.isNotEmpty == true 
                ? post['imageUrls'][0] 
                : null;
            
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? const Icon(
                      Icons.image,
                      color: Colors.grey,
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildInterestsTab(Map<String, dynamic> data) {
    final interests = List<String>.from(data['interests'] ?? []);
    
    if (interests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: AppConstants.iconSizeXXLarge,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppConstants.spacingMedium),
            Text(
              'No interests added',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.fontSizeLarge,
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingSmall),
            Text(
              'Add your interests to discover more!',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.fontSizeMedium,
                color: AppConstants.textTertiary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLarge),
            CustomButton(
              text: 'Add Interests',
              icon: Icons.add,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
            },
          ),
        ],
      ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingLarge),
      child: Wrap(
        spacing: AppConstants.spacingSmall,
        runSpacing: AppConstants.spacingSmall,
        children: interests.map((interest) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMedium,
              vertical: AppConstants.spacingSmall,
            ),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
              border: Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              interest,
              style: GoogleFonts.poppins(
                color: AppConstants.primaryColor,
                fontWeight: AppConstants.fontWeightMedium,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAboutTab(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAboutSection('Personal Information', [
            _buildAboutItem('Name', data['name'] ?? 'Not specified'),
            _buildAboutItem('Username', '@${data['username'] ?? 'username'}'),
            _buildAboutItem('Email', data['email'] ?? 'Not specified'),
            _buildAboutItem('Location', data['location'] ?? 'Not specified'),
            _buildAboutItem('Website', data['website'] ?? 'Not specified'),
          ]),
          
          const SizedBox(height: AppConstants.spacingXLarge),
          
          _buildAboutSection('Account Information', [
            _buildAboutItem('Country', data['country'] ?? 'Not specified'),
            _buildAboutItem('Goal', data['goal'] ?? 'Not specified'),
            _buildAboutItem('Member since', _formatDate(data['createdAt'])),
          ]),
          
          const SizedBox(height: AppConstants.spacingXLarge),
          
          _buildAboutSection('Bio', [
            _buildAboutItem('', data['bio'] ?? 'No bio added'),
          ]),
        ],
      ),
    );
  }

  Widget _buildAboutSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: AppConstants.fontSizeLarge,
            fontWeight: AppConstants.fontWeightSemiBold,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingMedium),
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingLarge),
          decoration: BoxDecoration(
            color: AppConstants.backgroundColor,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            boxShadow: AppConstants.defaultShadow,
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.fontSizeMedium,
                  color: AppConstants.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.spacingMedium),
          ],
          Expanded(
        child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: AppConstants.fontSizeMedium,
                color: AppConstants.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      if (timestamp is DateTime) {
        return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }
} 