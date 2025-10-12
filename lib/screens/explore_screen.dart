import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../providers/post_provider.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Category Tabs
          _buildCategoryTabs(),
          
          // Tab Bar
          Container(
            color: AppConstants.backgroundColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppConstants.primaryColor,
              labelColor: AppConstants.primaryColor,
              unselectedLabelColor: AppConstants.textSecondary,
              labelStyle: GoogleFonts.poppins(
                fontWeight: AppConstants.fontWeightSemiBold,
                fontSize: AppConstants.fontSizeMedium,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: AppConstants.fontWeightNormal,
                fontSize: AppConstants.fontSizeMedium,
              ),
              tabs: const [
                Tab(text: 'For You'),
                Tab(text: 'Following'),
                Tab(text: 'Trending'),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildForYouTab(),
                _buildFollowingTab(),
                _buildTrendingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMedium),
      color: AppConstants.backgroundColor,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search posts...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            borderSide: const BorderSide(color: AppConstants.textTertiary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            borderSide: const BorderSide(color: AppConstants.primaryColor),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMedium,
            vertical: AppConstants.spacingMedium,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMedium),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppConstants.postCategories.length + 1, // +1 for "All" tab
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" tab
            final isSelected = _selectedCategory == 'all';
            return _buildCategoryChip('all', 'All', Icons.apps, isSelected);
          }
          
          final category = AppConstants.postCategories[index - 1];
          final isSelected = _selectedCategory == category['id'];
          return _buildCategoryChip(
            category['id'],
            category['name'],
            category['icon'],
            isSelected,
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String id, String name, IconData icon, bool isSelected) {
    final categoryColor = id == 'all' 
        ? AppConstants.primaryColor 
        : AppConstants.getCategoryColor(id);
    
    return Container(
      margin: const EdgeInsets.only(right: AppConstants.spacingSmall),
      child: FilterChip(
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? id : 'all';
          });
        },
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppConstants.iconSizeSmall,
              color: isSelected ? Colors.white : categoryColor,
            ),
            const SizedBox(width: AppConstants.spacingXSmall),
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: AppConstants.fontSizeSmall,
                color: isSelected ? Colors.white : categoryColor,
                fontWeight: isSelected 
                    ? AppConstants.fontWeightSemiBold 
                    : AppConstants.fontWeightNormal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        selectedColor: categoryColor,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? categoryColor : AppConstants.textTertiary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
      ),
    );
  }

  Widget _buildForYouTab() {
    // Use different providers based on what's selected
    final postsAsync = _searchQuery.isNotEmpty && _selectedCategory != 'all'
        ? ref.watch(searchAndCategoryPostsProvider({
            'query': _searchQuery,
            'category': _selectedCategory,
          }))
        : _searchQuery.isNotEmpty
            ? ref.watch(searchPostsProvider(_searchQuery))
            : _selectedCategory != 'all'
                ? ref.watch(categoryPostsProvider(_selectedCategory))
                : ref.watch(postsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        if (_searchQuery.isNotEmpty && _selectedCategory != 'all') {
          ref.invalidate(searchAndCategoryPostsProvider({
            'query': _searchQuery,
            'category': _selectedCategory,
          }));
        } else if (_searchQuery.isNotEmpty) {
          ref.invalidate(searchPostsProvider(_searchQuery));
        } else if (_selectedCategory != 'all') {
          ref.invalidate(categoryPostsProvider(_selectedCategory));
        } else {
          ref.invalidate(postsProvider);
        }
      },
      child: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            String title, subtitle;
            IconData icon;
            
            if (_searchQuery.isNotEmpty && _selectedCategory != 'all') {
              title = 'No posts found';
              subtitle = 'Try adjusting your search or category filter';
              icon = Icons.search_off;
            } else if (_searchQuery.isNotEmpty) {
              title = 'No posts found';
              subtitle = 'Try different search terms';
              icon = Icons.search_off;
            } else if (_selectedCategory != 'all') {
              title = 'No posts in this category';
              subtitle = 'Be the first to post in this category!';
              icon = Icons.category_outlined;
            } else {
              title = 'No posts yet';
              subtitle = 'Be the first to share something!';
              icon = Icons.explore_outlined;
            }
            
            return _buildEmptyState(
              icon: icon,
              title: title,
              subtitle: subtitle,
              actionText: 'Create Post',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                );
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingMedium),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(post: post);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
          ),
        ),
        error: (error, stack) => _buildErrorState(
          error: error,
          onRetry: () {
            ref.invalidate(postsProvider);
          },
        ),
      ),
    );
  }

  Widget _buildFollowingTab() {
    // For now, show the same as For You tab
    // In a real app, this would filter posts from users you follow
    return _buildForYouTab();
  }

  Widget _buildTrendingTab() {
    // For now, show the same as For You tab
    // In a real app, this would show trending posts based on likes, comments, etc.
    return _buildForYouTab();
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingXLarge * 2,
          vertical: AppConstants.spacingXLarge,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingXLarge),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppConstants.iconSizeXXLarge,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXLarge * 1.5),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: AppConstants.fontSizeXLarge,
                fontWeight: AppConstants.fontWeightSemiBold,
                color: AppConstants.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingMedium),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMedium),
              child: Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.fontSizeMedium,
                  color: AppConstants.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXLarge * 1.5),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingXLarge,
                    vertical: AppConstants.spacingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                  ),
                ),
                child: Text(
                  actionText,
                  style: GoogleFonts.poppins(
                    fontWeight: AppConstants.fontWeightSemiBold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState({
    required Object error,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingXLarge * 2,
          vertical: AppConstants.spacingXLarge,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: AppConstants.iconSizeXXLarge,
              color: AppConstants.errorColor,
            ),
            const SizedBox(height: AppConstants.spacingXLarge * 1.5),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.fontSizeXLarge,
                fontWeight: AppConstants.fontWeightSemiBold,
                color: AppConstants.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingMedium),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMedium),
              child: Text(
                error.toString(),
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.fontSizeMedium,
                  color: AppConstants.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXLarge * 1.5),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingXLarge,
                    vertical: AppConstants.spacingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                  ),
                ),
                child: Text(
                  'Try Again',
                  style: GoogleFonts.poppins(
                    fontWeight: AppConstants.fontWeightSemiBold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}