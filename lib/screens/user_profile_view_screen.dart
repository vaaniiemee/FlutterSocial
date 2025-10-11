import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
      if (currentUserId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to follow users'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Use transaction for data consistency
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final followRef = FirebaseFirestore.instance
            .collection('follows')
            .doc('${currentUserId}_${widget.userId}');
        
        final currentUserRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId);
        final targetUserRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId);

        if (_isFollowing) {
          // Unfollow
          transaction.delete(followRef);
          transaction.update(targetUserRef, {
            'followersCount': FieldValue.increment(-1),
          });
          transaction.update(currentUserRef, {
            'followingCount': FieldValue.increment(-1),
          });
        } else {
          // Follow
          transaction.set(followRef, {
            'followerId': currentUserId,
            'followingId': widget.userId,
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(targetUserRef, {
            'followersCount': FieldValue.increment(1),
          });
          transaction.update(currentUserRef, {
            'followingCount': FieldValue.increment(1),
          });
        }
      });

      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing ? 'Following user' : 'Unfollowed user'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
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
      backgroundColor: Colors.white,
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
          
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(userData),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildProfileInfo(userData),
                    _buildActionButtons(),
                    _buildTabBar(),
                    _buildTabContent(userData),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(Map<String, dynamic> userData) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            image: userData['bannerURL'] != null && userData['bannerURL'].toString().isNotEmpty
                ? DecorationImage(
                    image: CachedNetworkImageProvider(userData['bannerURL'] as String),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Handle image loading error
                    },
                  )
                : null,
            color: userData['bannerURL'] == null || userData['bannerURL'].toString().isEmpty
                ? Colors.grey[100]
                : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: Stack(
              children: [
                if (userData['bannerURL'] == null || userData['bannerURL'].toString().isEmpty)
                  Center(
                    child: Icon(
                      Icons.landscape,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                  ),
                Positioned(
                  bottom: -40,
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
                      radius: 45,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: userData['photoURL'] != null && userData['photoURL'].toString().isNotEmpty
                          ? CachedNetworkImageProvider(userData['photoURL'] as String)
                          : null,
                      child: userData['photoURL'] == null || userData['photoURL'].toString().isEmpty
                          ? Icon(
                              Icons.person,
                              size: 45,
                              color: Colors.grey[600],
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(Map<String, dynamic> userData) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData['name'] ?? 'Unknown User',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${userData['username'] ?? 'unknown'}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (userData['bio'] != null && userData['bio'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  userData['bio'].toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
          if (userData['website'] != null && userData['website'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.link,
                  size: 16,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    userData['website'].toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.blue[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (userData['location'] != null && userData['location'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    userData['location'].toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: CustomButton(
              text: _isFollowing ? 'Following' : 'Follow',
              type: _isFollowing ? ButtonType.outline : ButtonType.primary,
              onPressed: _isLoading ? null : _toggleFollow,
              isLoading: _isLoading,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
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
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppConstants.primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
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
      height: MediaQuery.of(context).size.height * 0.4,
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
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .limit(20)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading posts: ${snapshot.error}'),
          );
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
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This user hasn\'t shared any posts yet',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Sort posts by creation date on client side
        final posts = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            
            return bTime.compareTo(aTime); // Descending order
          });

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final postData = post.data() as Map<String, dynamic>;
            
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: postData['imageUrls'] != null && 
                       (postData['imageUrls'] as List).isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: (postData['imageUrls'] as List).first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      ),
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
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This user hasn\'t added any interests yet',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: interests.map((interest) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              interest,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAboutTab(Map<String, dynamic> userData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAboutItem(
            'Name', 
            userData['name'] ?? 'Not provided',
            Icons.person,
          ),
          _buildAboutItem(
            'Username', 
            '@${userData['username'] ?? 'unknown'}',
            Icons.alternate_email,
          ),
          _buildAboutItem(
            'Bio', 
            userData['bio']?.toString() ?? 'No bio available',
            Icons.info,
          ),
          _buildAboutItem(
            'Website', 
            userData['website']?.toString() ?? 'Not provided',
            Icons.link,
          ),
          _buildAboutItem(
            'Location', 
            userData['location']?.toString() ?? 'Not provided',
            Icons.location_on,
          ),
          _buildAboutItem(
            'Joined', 
            _formatDate(userData['createdAt']),
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutItem(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),
              ],
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