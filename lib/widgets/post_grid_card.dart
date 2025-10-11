import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../constants/app_constants.dart';

class PostGridCard extends ConsumerWidget {
  final Post post;
  final VoidCallback? onTap;

  const PostGridCard({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          child: Stack(
            children: [
              // Main content
              _buildMainContent(),
              
              // Overlay with stats
              _buildOverlay(),
              
              // Category badge
              if (post.category.isNotEmpty) _buildCategoryBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (post.imageUrls.isNotEmpty) {
      // Post with images
      return CachedNetworkImage(
        imageUrl: post.imageUrls.first,
        width: double.infinity,
        height: double.infinity,
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
            size: 32,
          ),
        ),
      );
    } else {
      // Text-only post
      return Container(
        color: Colors.grey[50],
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                    backgroundImage: post.userPhotoUrl != null
                        ? CachedNetworkImageProvider(post.userPhotoUrl!)
                        : null,
                    child: post.userPhotoUrl == null
                        ? const Icon(
                            Icons.person,
                            color: AppConstants.primaryColor,
                            size: 16,
                          )
                        : null,
                  ),
                  const SizedBox(width: AppConstants.spacingSmall),
                  Expanded(
                    child: Text(
                      post.username ?? 'User',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: AppConstants.fontWeightSemiBold,
                        color: AppConstants.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppConstants.spacingSmall),
              
              // Content preview
              Expanded(
                child: Text(
                  post.content,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppConstants.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppConstants.spacingSmall),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Likes
            _buildStatItem(
              icon: Icons.favorite,
              count: post.likesCount,
              color: Colors.white,
            ),
            
            // Comments
            _buildStatItem(
              icon: Icons.chat_bubble_outline,
              count: post.commentsCount,
              color: Colors.white,
            ),
            
            // Reposts
            _buildStatItem(
              icon: Icons.repeat,
              count: post.repostsCount,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          _formatCount(count),
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: color,
            fontWeight: AppConstants.fontWeightMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBadge() {
    final categoryData = AppConstants.postCategories.firstWhere(
      (cat) => cat['id'] == post.category,
      orElse: () => {'name': post.category, 'icon': Icons.category},
    );

    return Positioned(
      top: AppConstants.spacingSmall,
      left: AppConstants.spacingSmall,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingSmall,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              categoryData['icon'],
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              categoryData['name'],
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white,
                fontWeight: AppConstants.fontWeightMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}
