import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../providers/post_provider.dart';
import '../providers/auth_provider.dart';
import '../constants/app_constants.dart';
import '../screens/user_profile_view_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/edit_post_screen.dart';

class PostCard extends ConsumerStatefulWidget {
  final Post post;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _isLoadingInteraction = false;

  Future<void> _handleLike() async {
    if (_isLoadingInteraction) return;
    
    setState(() {
      _isLoadingInteraction = true;
    });

    try {
      await ref.read(postNotifierProvider.notifier).likePost(widget.post.id);
      // Invalidate the like status provider to refresh the UI
      ref.invalidate(isPostLikedProvider(widget.post.id));
      ref.invalidate(postsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInteraction = false;
        });
      }
    }
  }

  Future<void> _handleRepost() async {
    if (_isLoadingInteraction) return;
    
    setState(() {
      _isLoadingInteraction = true;
    });

    try {
      await ref.read(postNotifierProvider.notifier).repost(
        postId: widget.post.id,
        reason: 'Reposted',
      );
      // Invalidate the repost status provider to refresh the UI
      ref.invalidate(isPostRepostedProvider(widget.post.id));
      ref.invalidate(postsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post reposted successfully!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInteraction = false;
        });
      }
    }
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(postId: widget.post.id),
    );
  }

  void _navigateToUserProfile() async {
    try {
      final currentUser = ref.read(authStateProvider).value;
      
      // If it's the current user's own post, navigate to ProfileScreen
      if (currentUser != null && currentUser.uid == widget.post.userId) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(),
          ),
        );
        return;
      }
      
      // Get user data from Firestore for other users
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.post.userId)
          .get();
      
      if (userDoc.exists && mounted) {
        final userData = userDoc.data() as Map<String, dynamic>;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UserProfileViewScreen(
              userId: widget.post.userId,
              userData: userData,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load user profile: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: AppConstants.defaultShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLarge),
            child: Row(
              children: [
                // Profile Picture
                GestureDetector(
                  onTap: _navigateToUserProfile,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                    backgroundImage: widget.post.userPhotoUrl != null
                        ? CachedNetworkImageProvider(widget.post.userPhotoUrl!)
                        : null,
                    child: widget.post.userPhotoUrl == null
                        ? const Icon(
                            Icons.person,
                            color: AppConstants.primaryColor,
                            size: AppConstants.iconSizeMedium,
                          )
                        : null,
                  ),
                ),
                
                const SizedBox(width: AppConstants.spacingMedium),
                
                // User Info
                Expanded(
                  child: GestureDetector(
                    onTap: _navigateToUserProfile,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.username ?? 'User',
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.fontSizeMedium,
                            fontWeight: AppConstants.fontWeightSemiBold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        Text(
                          _formatTime(widget.post.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.fontSizeSmall,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // More Options
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditPostScreen(post: widget.post),
                          ),
                        );
                        break;
                      case 'delete':
                        _showDeleteDialog();
                        break;
                      case 'report':
                        _showReportDialog();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (widget.post.userId == ref.read(currentUserProvider)?.uid) ...[
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: AppConstants.primaryColor),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: AppConstants.errorColor),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.report, color: AppConstants.warningColor),
                          SizedBox(width: 8),
                          Text('Report'),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(
                    Icons.more_vert,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Content
          if (widget.post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLarge),
              child: Text(
                widget.post.content,
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.fontSizeMedium,
                  color: AppConstants.textPrimary,
                  height: 1.5,
                ),
              ),
            ),

          // Images
          if (widget.post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingMedium),
            _buildImageGrid(),
          ],

          // Tags
          if (widget.post.tags.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingMedium),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLarge),
              child: Wrap(
                spacing: AppConstants.spacingXSmall,
                children: widget.post.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingSmall,
                      vertical: AppConstants.spacingXSmall,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.fontSizeSmall,
                        color: AppConstants.primaryColor,
                        fontWeight: AppConstants.fontWeightMedium,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Repost Info
          if (widget.post.isRepost) ...[
            const SizedBox(height: AppConstants.spacingMedium),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLarge),
              padding: const EdgeInsets.all(AppConstants.spacingMedium),
              decoration: BoxDecoration(
                color: AppConstants.backgroundColor,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                border: Border.all(
                  color: AppConstants.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.repeat,
                    color: AppConstants.primaryColor,
                    size: AppConstants.iconSizeSmall,
                  ),
                  const SizedBox(width: AppConstants.spacingSmall),
                  Expanded(
                    child: Text(
                      widget.post.repostReason ?? 'Reposted',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.fontSizeSmall,
                        color: AppConstants.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppConstants.spacingMedium),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLarge),
            child: Row(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final isLikedAsync = ref.watch(isPostLikedProvider(widget.post.id));
                    return isLikedAsync.when(
                      data: (isLiked) => _buildActionButton(
                        icon: isLiked ? Icons.favorite : Icons.favorite_border,
                        label: widget.post.likesCount.toString(),
                        color: isLiked ? AppConstants.errorColor : AppConstants.textSecondary,
                        onTap: _handleLike,
                        isLoading: _isLoadingInteraction,
                      ),
                      loading: () => _buildActionButton(
                        icon: Icons.favorite_border,
                        label: widget.post.likesCount.toString(),
                        color: AppConstants.textSecondary,
                        onTap: _handleLike,
                        isLoading: _isLoadingInteraction,
                      ),
                      error: (_, __) => _buildActionButton(
                        icon: Icons.favorite_border,
                        label: widget.post.likesCount.toString(),
                        color: AppConstants.textSecondary,
                        onTap: _handleLike,
                        isLoading: _isLoadingInteraction,
                      ),
                    );
                  },
                ),
                
                const SizedBox(width: AppConstants.spacingXLarge),
                
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: widget.post.commentsCount.toString(),
                  onTap: _showComments,
                ),
                
                const SizedBox(width: AppConstants.spacingXLarge),
                
                Consumer(
                  builder: (context, ref, child) {
                    final isRepostedAsync = ref.watch(isPostRepostedProvider(widget.post.id));
                    return isRepostedAsync.when(
                      data: (isReposted) => _buildActionButton(
                        icon: isReposted ? Icons.repeat : Icons.repeat_outlined,
                        label: widget.post.repostsCount.toString(),
                        color: isReposted ? AppConstants.successColor : AppConstants.textSecondary,
                        onTap: _handleRepost,
                        isLoading: _isLoadingInteraction,
                      ),
                      loading: () => _buildActionButton(
                        icon: Icons.repeat_outlined,
                        label: widget.post.repostsCount.toString(),
                        color: AppConstants.textSecondary,
                        onTap: _handleRepost,
                        isLoading: _isLoadingInteraction,
                      ),
                      error: (_, __) => _buildActionButton(
                        icon: Icons.repeat_outlined,
                        label: widget.post.repostsCount.toString(),
                        color: AppConstants.textSecondary,
                        onTap: _handleRepost,
                        isLoading: _isLoadingInteraction,
                      ),
                    );
                  },
                ),
                
                const SizedBox(width: AppConstants.spacingXLarge),
                
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () {
                    // TODO: Implement share functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share functionality coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spacingLarge),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    if (widget.post.imageUrls.length == 1) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLarge),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          child: CachedNetworkImage(
            imageUrl: widget.post.imageUrls.first,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 300,
            placeholder: (context, url) => Container(
              height: 300,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 300,
              color: Colors.grey[200],
              child: const Icon(Icons.error),
            ),
          ),
        ),
      );
    } else if (widget.post.imageUrls.length == 2) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLarge),
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadiusMedium),
                  bottomLeft: Radius.circular(AppConstants.borderRadiusMedium),
                ),
                child: CachedNetworkImage(
                  imageUrl: widget.post.imageUrls[0],
                  fit: BoxFit.cover,
                  height: 200,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(AppConstants.borderRadiusMedium),
                  bottomRight: Radius.circular(AppConstants.borderRadiusMedium),
                ),
                child: CachedNetworkImage(
                  imageUrl: widget.post.imageUrls[1],
                  fit: BoxFit.cover,
                  height: 200,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLarge),
        height: 200,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: widget.post.imageUrls.length > 4 ? 4 : widget.post.imageUrls.length,
          itemBuilder: (context, index) {
            if (index == 3 && widget.post.imageUrls.length > 4) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                    child: CachedNetworkImage(
                      imageUrl: widget.post.imageUrls[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                    ),
                    child: Center(
                      child: Text(
                        '+${widget.post.imageUrls.length - 3}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: AppConstants.fontWeightBold,
                          fontSize: AppConstants.fontSizeLarge,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
              child: CachedNetworkImage(
                imageUrl: widget.post.imageUrls[index],
                fit: BoxFit.cover,
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingSmall,
          vertical: AppConstants.spacingXSmall,
        ),
        decoration: BoxDecoration(
          color: color?.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color ?? AppConstants.textSecondary,
                  ),
                ),
              )
            else
              Icon(
                icon,
                size: AppConstants.iconSizeSmall,
                color: color ?? AppConstants.textSecondary,
              ),
            const SizedBox(width: AppConstants.spacingXSmall),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: AppConstants.fontSizeSmall,
                color: color ?? AppConstants.textSecondary,
                fontWeight: AppConstants.fontWeightMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              try {
                await ref.read(postNotifierProvider.notifier).deletePost(widget.post.id);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Post deleted'),
                      backgroundColor: AppConstants.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppConstants.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: const Text('Are you sure you want to report this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Post reported. Thank you for your feedback.'),
                  backgroundColor: AppConstants.successColor,
                ),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final String postId;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(postNotifierProvider.notifier).addComment(
        postId: widget.postId,
        content: _commentController.text.trim(),
      );
      
      _commentController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppConstants.errorColor,
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
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLarge),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.fontSizeLarge,
                    fontWeight: AppConstants.fontWeightSemiBold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Comments List
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: AppConstants.spacingMedium),
                        Text(
                          'No comments yet',
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.fontSizeLarge,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingSmall),
                        Text(
                          'Be the first to comment!',
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
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLarge),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return CommentCard(comment: comment);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading comments: $error'),
              ),
            ),
          ),
          
          // Comment Input
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingMedium,
                        vertical: AppConstants.spacingSmall,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSmall),
                IconButton(
                  onPressed: _isLoading ? null : _addComment,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommentCard extends ConsumerWidget {
  final Comment comment;

  const CommentCard({
    super.key,
    required this.comment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
            backgroundImage: comment.userPhotoUrl != null
                ? CachedNetworkImageProvider(comment.userPhotoUrl!)
                : null,
            child: comment.userPhotoUrl == null
                ? const Icon(
                    Icons.person,
                    color: AppConstants.primaryColor,
                    size: 16,
                  )
                : null,
          ),
          
          const SizedBox(width: AppConstants.spacingSmall),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username ?? 'User',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.fontSizeSmall,
                        fontWeight: AppConstants.fontWeightSemiBold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingXSmall),
                    Text(
                      _formatTime(comment.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.fontSizeSmall,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppConstants.spacingXSmall),
                
                Text(
                  comment.content,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.fontSizeSmall,
                    color: AppConstants.textPrimary,
                  ),
                ),
                
                const SizedBox(height: AppConstants.spacingXSmall),
                
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // TODO: Implement comment like
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.favorite_border,
                            size: 14,
                            color: AppConstants.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            comment.likesCount.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: AppConstants.fontSizeSmall,
                              color: AppConstants.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: AppConstants.spacingMedium),
                    
                    GestureDetector(
                      onTap: () {
                        // TODO: Implement reply to comment
                      },
                      child: Text(
                        'Reply',
                        style: GoogleFonts.poppins(
                          fontSize: AppConstants.fontSizeSmall,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
