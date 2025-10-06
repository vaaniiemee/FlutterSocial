import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/error_widget.dart';
import 'chat_screen.dart';

class UserProfileViewScreen extends ConsumerStatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserProfileViewScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  ConsumerState<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends ConsumerState<UserProfileViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkFollowStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkFollowStatus() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final followDoc = await FirebaseFirestore.instance
          .collection('follows')
          .doc('${currentUserId}_${widget.userId}')
          .get();
      
      if (mounted) {
        setState(() {
          _isFollowing = followDoc.exists;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final followRef = FirebaseFirestore.instance
          .collection('follows')
          .doc('${currentUserId}_${widget.userId}');

      if (_isFollowing) {
        // Unfollow
        await followRef.delete();
        
        // Update follower count
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({
          'followersCount': FieldValue.increment(-1),
        });
        
        // Update following count
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
          'followingCount': FieldValue.increment(-1),
        });
      } else {
        // Follow
        await followRef.set({
          'followerId': currentUserId,
          'followingId': widget.userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Update follower count
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({
          'followersCount': FieldValue.increment(1),
        });
        
        // Update following count
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
          'followingCount': FieldValue.increment(1),
        });
      }

      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.userData['name'] ?? 'Profile',
          style: GoogleFonts.poppins(
            fontSize: AppConstants.fontSizeLarge,
            fontWeight: AppConstants.fontWeightSemiBold,
            color: AppConstants.textPrimary,
          ),
        ),
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    userId: widget.userId,
                    userData: widget.userData,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat),
            tooltip: 'Start Chat',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return CustomErrorWidget(
              message: 'Error loading profile: ${snapshot.error}',
              onRetry: () => setState(() {}),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('User not found'),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(userData),
                _buildProfileStats(userData),
                _buildActionButtons(),
                _buildTabBar(),
                _buildTabContent(userData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppConstants.borderRadiusLarge),
          bottomRight: Radius.circular(AppConstants.borderRadiusLarge),
        ),
        image: userData['bannerURL'] != null
            ? DecorationImage(
                image: NetworkImage(userData['bannerURL'] as String),
                fit: BoxFit.cover,
              )
            : null,
        color: userData['bannerURL'] == null 
            ? AppConstants.primaryColor.withValues(alpha: 0.1)
            : null,
      ),
      child: Stack(
        children: [
          if (userData['bannerURL'] == null)
            Center(
              child: Icon(
                Icons.landscape,
                size: 60,
                color: AppConstants.primaryColor.withValues(alpha: 0.3),
              ),
            ),
          Positioned(
            bottom: -50,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                backgroundImage: userData['photoURL'] != null && userData['photoURL'].toString().isNotEmpty
                    ? NetworkImage(userData['photoURL'] as String)
                    : null,
                child: userData['photoURL'] == null || userData['photoURL'].toString().isEmpty
                    ? Icon(
                        Icons.person,
                        size: 50,
                        color: AppConstants.primaryColor,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats(Map<String, dynamic> userData) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userData['name'] ?? 'Unknown User',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.fontSizeXXLarge,
              fontWeight: AppConstants.fontWeightBold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${userData['username'] ?? 'unknown'}',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.fontSizeLarge,
              color: AppConstants.textSecondary,
            ),
          ),
          if (userData['bio'] != null && userData['bio'].isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              userData['bio'],
              style: GoogleFonts.poppins(
                fontSize: AppConstants.fontSizeMedium,
                color: AppConstants.textPrimary,
              ),
            ),
          ],
          if (userData['website'] != null && userData['website'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.link,
                  size: 16,
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  userData['website'],
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.fontSizeMedium,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ],
          if (userData['location'] != null && userData['location'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  userData['location'],
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.fontSizeMedium,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem(
                'Posts',
                '${userData['postsCount'] ?? 0}',
              ),
              const SizedBox(width: 30),
              _buildStatItem(
                'Followers',
                '${userData['followersCount'] ?? 0}',
              ),
              const SizedBox(width: 30),
              _buildStatItem(
                'Following',
                '${userData['followingCount'] ?? 0}',
              ),
            ],
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
            fontSize: AppConstants.fontSizeLarge,
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

  Widget _buildActionButtons() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnProfile = currentUserId == widget.userId;

    if (isOwnProfile) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: _isFollowing ? 'Following' : 'Follow',
              type: _isFollowing ? ButtonType.outline : ButtonType.primary,
              onPressed: _isLoading ? null : _toggleFollow,
              isLoading: _isLoading,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomButton(
              text: 'Message',
              type: ButtonType.outline,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      userId: widget.userId,
                      userData: widget.userData,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppConstants.primaryColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppConstants.textSecondary,
        labelStyle: GoogleFonts.poppins(
          fontWeight: AppConstants.fontWeightSemiBold,
        ),
        tabs: const [
          Tab(text: 'Posts'),
          Tab(text: 'Interests'),
          Tab(text: 'About'),
        ],
      ),
    );
  }

  Widget _buildTabContent(Map<String, dynamic> userData) {
    return SizedBox(
      height: 400,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsTab(userData),
          _buildInterestsTab(userData),
          _buildAboutTab(userData),
        ],
      ),
    );
  }

  Widget _buildPostsTab(Map<String, dynamic> userData) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.grid_on,
                  size: 60,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.fontSizeLarge,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final post = snapshot.data!.docs[index];
            final postData = post.data() as Map<String, dynamic>;
            
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: postData['imageUrls'] != null && 
                     (postData['imageUrls'] as List).isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        (postData['imageUrls'] as List).first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image,
                            color: Colors.grey[400],
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.image,
                      color: Colors.grey[400],
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildInterestsTab(Map<String, dynamic> userData) {
    final interests = List<String>.from(userData['interests'] ?? []);
    
    if (interests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.interests,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No interests added',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.fontSizeLarge,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: interests.map((interest) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              interest,
              style: GoogleFonts.poppins(
                fontSize: AppConstants.fontSizeMedium,
                color: AppConstants.primaryColor,
                fontWeight: AppConstants.fontWeightMedium,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAboutTab(Map<String, dynamic> userData) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAboutItem('Name', userData['name'] ?? 'Not provided'),
          _buildAboutItem('Username', '@${userData['username'] ?? 'unknown'}'),
          _buildAboutItem('Bio', userData['bio'] ?? 'No bio available'),
          _buildAboutItem('Website', userData['website'] ?? 'Not provided'),
          _buildAboutItem('Location', userData['location'] ?? 'Not provided'),
          _buildAboutItem('Joined', _formatDate(userData['createdAt'])),
        ],
      ),
    );
  }

  Widget _buildAboutItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.fontSizeMedium,
              fontWeight: AppConstants.fontWeightSemiBold,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.fontSizeMedium,
              color: AppConstants.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    final DateTime date = timestamp is Timestamp 
        ? timestamp.toDate() 
        : DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    return '${date.day}/${date.month}/${date.year}';
  }
}
