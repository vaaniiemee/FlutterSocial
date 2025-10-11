import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../providers/post_provider.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/loading_overlay.dart';
import '../constants/app_constants.dart';
import '../models/post_model.dart';

class EditPostScreen extends ConsumerStatefulWidget {
  final Post post;
  
  const EditPostScreen({
    super.key,
    required this.post,
  });

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  
  List<File> _selectedImages = [];
  bool _isLoading = false;
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.post.content;
    _selectedCategory = widget.post.category;
  }

  @override
  void dispose() {
    _contentController.dispose();
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

  Future<void> _updatePost() async {
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
      
      // For now, we'll just update the content and category
      // Image editing would require more complex logic
      await ref.read(postNotifierProvider.notifier).updatePost(
        postId: widget.post.id,
        content: content,
        category: _selectedCategory,
        tags: tags,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post updated successfully!'),
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
          'Edit Post',
          style: GoogleFonts.poppins(
            fontWeight: AppConstants.fontWeightSemiBold,
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final isLoading = postState.isLoading || _isLoading;
              
              return TextButton(
                onPressed: isLoading ? null : _updatePost,
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
                        'Save',
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
                // Category Selector
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

                // Content Input
                CustomTextField(
                  controller: _contentController,
                  labelText: 'What\'s on your mind?',
                  hintText: 'Share your thoughts, ideas, or experiences...',
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

                // Existing Images Section
                if (widget.post.imageUrls.isNotEmpty) ...[
                  Text(
                    'Current Images',
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
                      itemCount: widget.post.imageUrls.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: AppConstants.spacingSmall),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                            child: Image.network(
                              widget.post.imageUrls[index],
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingLarge),
                ],

                // New Images Section
                if (_selectedImages.isNotEmpty) ...[
                  Text(
                    'New Images (${_selectedImages.length}/4)',
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

                // Update Button
                CustomButton(
                  text: 'Update Post',
                  onPressed: _isLoading ? null : _updatePost,
                  isLoading: _isLoading,
                  icon: Icons.save,
                ),
              ],
            ),
          ),
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
            return DropdownMenuItem<String>(
              value: category['id'],
              child: Row(
                children: [
                  Icon(
                    category['icon'],
                    size: AppConstants.iconSizeSmall,
                    color: AppConstants.primaryColor,
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
