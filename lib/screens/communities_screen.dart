import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/error_widget.dart';
import 'chat_screen.dart';
import 'user_profile_view_screen.dart';

class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  ConsumerState<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primaryColor,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: AppConstants.textSecondary,
          labelStyle: GoogleFonts.poppins(
            fontWeight: AppConstants.fontWeightSemiBold,
          ),
          tabs: const [
            Tab(text: 'Search Users'),
            Tab(text: 'Chats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchUsersTab(),
          _buildChatsTab(),
        ],
      ),
    );
  }

  Widget _buildSearchUsersTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMedium),
          child: CustomTextField(
            controller: _searchController,
            hintText: 'Search users...',
            prefixIcon: const Icon(Icons.search),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim();
              });
            },
          ),
        ),
        
        // Search Results
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _searchQuery.isEmpty
          ? FirebaseFirestore.instance
              .collection('users')
              .limit(50)
              .snapshots()
          : FirebaseFirestore.instance
              .collection('users')
              .where('username', isGreaterThanOrEqualTo: _searchQuery)
              .where('username', isLessThan: '${_searchQuery}z')
              .limit(20)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return CustomErrorWidget(
            message: 'Error searching users: ${snapshot.error}',
            onRetry: () => setState(() {}),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: AppConstants.spacingLarge),
                Text(
                  _searchQuery.isEmpty ? 'No users have registered yet' : 'No users found',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.fontSizeLarge,
                    fontWeight: AppConstants.fontWeightMedium,
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingSmall),
                Text(
                  _searchQuery.isEmpty 
                      ? 'Be the first to join the community!'
                      : 'Try a different search term',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.fontSizeMedium,
                    color: AppConstants.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMedium),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final user = snapshot.data!.docs[index];
            final userData = user.data() as Map<String, dynamic>;
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            
            // Don't show current user in search results
            if (user.id == currentUserId) {
              return const SizedBox.shrink();
            }

            return _buildUserCard(userData, user.id);
          },
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData, String userId) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileViewScreen(
                userId: userId,
                userData: userData,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: ListTile(
          contentPadding: const EdgeInsets.all(AppConstants.spacingMedium),
          leading: CircleAvatar(
            radius: 30,
            backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
            backgroundImage: userData['photoURL'] != null
                ? NetworkImage(userData['photoURL'] as String)
                : null,
            child: userData['photoURL'] == null
                ? Text(
                    (userData['name'] ?? 'U')[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.fontSizeLarge,
                      fontWeight: AppConstants.fontWeightSemiBold,
                      color: AppConstants.primaryColor,
                    ),
                  )
                : null,
          ),
          title: Text(
            userData['name'] ?? 'Unknown User',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.fontSizeLarge,
              fontWeight: AppConstants.fontWeightSemiBold,
              color: AppConstants.textPrimary,
            ),
          ),
          subtitle: Text(
            '@${userData['username'] ?? 'unknown'}',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.fontSizeMedium,
              color: AppConstants.textSecondary,
            ),
          ),
          trailing: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    userId: userId,
                    userData: userData,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat),
            tooltip: 'Start Chat',
          ),
        ),
      ),
    );
  }

  Widget _buildChatsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return CustomErrorWidget(
            message: 'Error loading chats: ${snapshot.error}',
            onRetry: () => setState(() {}),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: AppConstants.spacingLarge),
                Text(
                  'No chats yet',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.fontSizeLarge,
                    fontWeight: AppConstants.fontWeightMedium,
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingSmall),
                Text(
                  'Start a conversation with someone',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.fontSizeMedium,
                    color: AppConstants.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        // Get all chats without sorting to avoid errors
        final chats = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.spacingLarge),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final chatData = chat.data() as Map<String, dynamic>;
            return _buildChatCard(chatData, chat.id);
          },
        );
      },
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chatData, String chatId) {
    final participants = List<String>.from(chatData['participants'] ?? []);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    if (participants.isEmpty || currentUserId == null) {
      return const SizedBox.shrink();
    }
    
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participants.isNotEmpty ? participants.first : '',
    );
    
    if (otherUserId.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppConstants.spacingMedium),
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
              backgroundImage: userData['photoURL'] != null
                  ? NetworkImage(userData['photoURL'] as String)
                  : null,
              child: userData['photoURL'] == null
                  ? Text(
                      (userData['name'] ?? 'U')[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.fontSizeLarge,
                        fontWeight: AppConstants.fontWeightSemiBold,
                        color: AppConstants.primaryColor,
                      ),
                    )
                  : null,
            ),
            title: Text(
              userData['name'] ?? 'Unknown User',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.fontSizeLarge,
                fontWeight: AppConstants.fontWeightSemiBold,
                color: AppConstants.textPrimary,
              ),
            ),
            subtitle: Text(
              chatData['lastMessage'] ?? 'No messages yet',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.fontSizeMedium,
                color: AppConstants.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(chatData['lastMessageTime']),
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.fontSizeSmall,
                    color: AppConstants.textTertiary,
                  ),
                ),
                if (chatData['unreadCount'] != null && 
                    chatData['unreadCount'] is Map && 
                    (chatData['unreadCount'] as Map).values.any((unreadCount) => unreadCount > 0))
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_getUnreadCount(chatData['unreadCount'])}',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.fontSizeSmall,
                        color: Colors.white,
                        fontWeight: AppConstants.fontWeightSemiBold,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    userId: otherUserId,
                    userData: userData,
                    chatId: chatId,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    
    final DateTime time = timestamp is Timestamp 
        ? timestamp.toDate() 
        : DateTime.fromMillisecondsSinceEpoch(timestamp);
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  int _getUnreadCount(dynamic unreadCount) {
    if (unreadCount == null) return 0;
    if (unreadCount is Map) {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null && unreadCount.containsKey(currentUserId)) {
        return unreadCount[currentUserId] as int? ?? 0;
      }
      return 0;
    }
    return unreadCount as int? ?? 0;
  }
} 