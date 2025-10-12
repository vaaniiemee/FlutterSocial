import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../providers/post_provider.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/loading_overlay.dart';
import '../constants/app_constants.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final bool isThread;
  final String? threadParentId;
  
  const CreatePostScreen({
    super.key,
    this.isThread = false,
    this.threadParentId,
  });

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  
  List<File> _selectedImages = [];
  bool _isLoading = false;
  String _postType = 'post'; // 'post', 'thread'
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    if (widget.isThread) {
      _postType = 'thread';
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final images = await ref.read(postNotifierProvider.notifier).pickImages();
      setState(() {
        _selectedImages = images;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  List<String> _extractTags(String text) {
    final regex = RegExp(r'#\w+');
    return regex.allMatches(text).map((match) => match.group(0)!).toList();
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some content'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final content = _contentController.text.trim();
      final tags = _extractTags(content);
      
      await ref.read(postNotifierProvider.notifier).createPost(
        content: content,
        images: _selectedImages.isNotEmpty ? _selectedImages : null,
        tags: tags,
        category: _selectedCategory,
        isThread: _postType == 'thread',
        threadParentId: widget.threadParentId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_postType == 'thread' ? 'Thread posted!' : 'Post created!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        Navigator.of(context).pop();
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
    final postState = ref.watch(postNotifierProvider);
    
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
        title: Text(
          widget.isThread ? 'Reply to Thread' : 'Create Post',
          style: GoogleFonts.poppins(
            fontWeight: AppConstants.fontWeightSemiBold,
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final isLoading = postState.isLoading || _isLoading;
              
              return TextButton(
                onPressed: isLoading ? null : _createPost,
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                        ),
                      )
                    : Text(
                        'Post',
                        style: GoogleFonts.poppins(
                          color: AppConstants.primaryColor,
                          fontWeight: AppConstants.fontWeightSemiBold,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post Type Selector
                if (!widget.isThread) ...[
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingSmall),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildPostTypeOption('post', 'Post', Icons.edit),
                        ),
                        const SizedBox(width: AppConstants.spacingSmall),
                        Expanded(
                          child: _buildPostTypeOption('thread', 'Thread', Icons.chat_bubble_outline),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLarge),
                ],

                // Category Selector
                if (!widget.isThread) ...[
                  Text(
                    'Category',
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.fontSizeMedium,
                      fontWeight: AppConstants.fontWeightSemiBold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingSmall),
                  _buildCategorySelector(),
                  const SizedBox(height: AppConstants.spacingLarge),
                ],

                // Content Input
                CustomTextField(
                  controller: _contentController,
                  labelText: widget.isThread ? 'Reply' : 'What\'s on your mind?',
                  hintText: widget.isThread 
                      ? 'Write your reply...' 
                      : 'Share your thoughts, ideas, or experiences...',
                  maxLines: 8,
                  maxLength: 500,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter some content';
                    }
                    if (value.length > 500) {
                      return 'Content must be less than 500 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppConstants.spacingLarge),

                // Images Section
                if (_selectedImages.isNotEmpty) ...[
                  Text(
                    'Images (${_selectedImages.length}/4)',
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.fontSizeMedium,
                      fontWeight: AppConstants.fontWeightSemiBold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMedium),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: AppConstants.spacingSmall),
                          child: Stack(
                            children: [
                              Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                                  image: DecorationImage(
                                    image: FileImage(_selectedImages[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLarge),
                ],

                // Add Images Button
                if (_selectedImages.length < 4)
                  CustomButton(
                    text: 'Add Images (${_selectedImages.length}/4)',
                    type: ButtonType.outline,
                    icon: Icons.add_photo_alternate,
                    onPressed: _pickImages,
                  ),

                const SizedBox(height: AppConstants.spacingLarge),

                // Tags Info
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingMedium),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                    border: Border.all(
                      color: AppConstants.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppConstants.primaryColor,
                        size: AppConstants.iconSizeSmall,
                      ),
                      const SizedBox(width: AppConstants.spacingSmall),
                      Expanded(
                        child: Text(
                          'Use #hashtags to categorize your post and make it discoverable',
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.fontSizeSmall,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.spacingXLarge),

                // Post Button
                CustomButton(
                  text: widget.isThread ? 'Reply to Thread' : 'Create Post',
                  onPressed: _isLoading ? null : _createPost,
                  isLoading: _isLoading,
                  icon: widget.isThread ? Icons.reply : Icons.send,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostTypeOption(String type, String label, IconData icon) {
    final isSelected = _postType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _postType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.spacingMedium,
          horizontal: AppConstants.spacingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppConstants.primaryColor,
              size: AppConstants.iconSizeSmall,
            ),
            const SizedBox(width: AppConstants.spacingXSmall),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : AppConstants.primaryColor,
                fontWeight: AppConstants.fontWeightMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingSmall),
      decoration: BoxDecoration(
        border: Border.all(color: AppConstants.textTertiary),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedCategory.isEmpty ? null : _selectedCategory,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: 'Select category (optional)',
        ),
        items: [
          // No category option
          DropdownMenuItem<String>(
            value: '',
            child: Row(
              children: [
                const Icon(
                  Icons.category_outlined,
                  size: AppConstants.iconSizeSmall,
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(width: AppConstants.spacingSmall),
                Text(
                  'No category',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.fontSizeMedium,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Category options
          ...AppConstants.postCategories.map((category) {
            final categoryColor = category['color'] as Color;
            return DropdownMenuItem<String>(
              value: category['id'],
              child: Row(
                children: [
                  Icon(
                    category['icon'],
                    size: AppConstants.iconSizeSmall,
                    color: categoryColor,
                  ),
                  const SizedBox(width: AppConstants.spacingSmall),
                  Text(
                    category['name'],
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.fontSizeMedium,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        onChanged: (value) {
          setState(() {
            _selectedCategory = value ?? '';
          });
        },
      ),
    );
  }
}
