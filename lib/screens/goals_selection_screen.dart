import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/common/loading_overlay.dart';
import '../constants/app_constants.dart';
import 'home_screen.dart';
import 'country_selection_screen.dart';

class GoalsSelectionScreen extends ConsumerStatefulWidget {
  const GoalsSelectionScreen({super.key});

  @override
  ConsumerState<GoalsSelectionScreen> createState() => _GoalsSelectionScreenState();
}

class _GoalsSelectionScreenState extends ConsumerState<GoalsSelectionScreen> {
  String? _selectedGoal;
  String? _customGoal;
  bool _showCustomInput = false;
  final TextEditingController _customGoalController = TextEditingController();

  final List<Map<String, dynamic>> _goals = [
    {
      'id': 'study',
      'title': 'Study',
      'description': 'Academic and educational purposes',
      'icon': Icons.school,
      'color': const Color(0xFF4CAF50),
    },
    {
      'id': 'travel',
      'title': 'Travel',
      'description': 'Exploring new places and cultures',
      'icon': Icons.flight,
      'color': const Color(0xFF2196F3),
    },
    {
      'id': 'work',
      'title': 'Work',
      'description': 'Professional and career development',
      'icon': Icons.work,
      'color': const Color(0xFFFF9800),
    },
    {
      'id': 'social',
      'title': 'Social',
      'description': 'Meeting new people and networking',
      'icon': Icons.people,
      'color': const Color(0xFF9C27B0),
    },
    {
      'id': 'hobby',
      'title': 'Hobby',
      'description': 'Pursuing personal interests',
      'icon': Icons.sports_esports,
      'color': const Color(0xFFE91E63),
    },
    {
      'id': 'business',
      'title': 'Business',
      'description': 'Entrepreneurship and startups',
      'icon': Icons.business,
      'color': const Color(0xFF607D8B),
    },
    {
      'id': 'dating',
      'title': 'Dating',
      'description': 'Romantic relationships',
      'icon': Icons.favorite,
      'color': const Color(0xFFF44336),
    },
    {
      'id': 'other',
      'title': 'Other',
      'description': 'Other personal goals',
      'icon': Icons.more_horiz,
      'color': const Color(0xFF795548),
    },
  ];

  Future<void> _saveGoalSelection() async {
    if (_selectedGoal == null) return;

    final goalToSave = _selectedGoal == 'other' && _customGoal != null 
        ? _customGoal 
        : _selectedGoal;
        
    await ref.read(userNotifierProvider.notifier).updateGoal(goalToSave!);
    
    // Listen to the update result
    ref.listen(userNotifierProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          }
        },
        error: (error, stack) {
          if (mounted) {
            ErrorSnackBar.show(context, 'Failed to save goal selection');
          }
        },
      );
    });
  }



  @override
  void dispose() {
    _customGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userUpdateState = ref.watch(userNotifierProvider);
    
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: LoadingOverlay(
        isLoading: userUpdateState.isLoading,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLarge),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const CountrySelectionScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingLarge),
                    Text(
                      'What are your goals?',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.fontSizeTitle,
                        fontWeight: AppConstants.fontWeightBold,
                        color: AppConstants.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.spacingSmall),
                    Text(
                      'Select your primary goal to help us personalize your experience',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.fontSizeLarge,
                        color: AppConstants.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.spacingXLarge),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingSmall),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingLarge),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLarge),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppConstants.spacingMedium,
                      mainAxisSpacing: AppConstants.spacingMedium,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _goals.length,
                    itemBuilder: (context, index) {
                      final goal = _goals[index];
                      final isSelected = _selectedGoal == goal['id'] || 
                          (goal['id'] == 'other' && _customGoal != null);

                      return GestureDetector(
                        onTap: () {
                          if (goal['id'] == 'other') {
                            setState(() {
                              _showCustomInput = true;
                              _selectedGoal = 'other';
                              _customGoal = null;
                            });
                          } else {
                            setState(() {
                              _selectedGoal = goal['id'];
                              _customGoal = null;
                              _showCustomInput = false;
                            });
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? goal['color'] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                            border: Border.all(
                              color: isSelected ? goal['color'] : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: goal['color'].withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppConstants.spacingMedium),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  goal['icon'],
                                  size: AppConstants.iconSizeLarge,
                                  color: isSelected ? Colors.white : goal['color'],
                                ),
                                const SizedBox(height: AppConstants.spacingSmall),
                                Text(
                                  goal['id'] == 'other' && _customGoal != null 
                                      ? _customGoal! 
                                      : goal['title'],
                                  style: GoogleFonts.poppins(
                                    fontSize: AppConstants.fontSizeMedium,
                                    fontWeight: AppConstants.fontWeightSemiBold,
                                    color: isSelected ? Colors.white : AppConstants.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppConstants.spacingXSmall),
                                Text(
                                  goal['description'],
                                  style: GoogleFonts.poppins(
                                    fontSize: AppConstants.fontSizeSmall,
                                    color: isSelected ? Colors.white70 : AppConstants.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_showCustomInput)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLarge),
                  child: Column(
                    children: [
                      const SizedBox(height: AppConstants.spacingMedium),
                      CustomTextField(
                        controller: _customGoalController,
                        hintText: 'Type your goal here...',
                        onChanged: (value) {
                          setState(() {
                            _customGoal = value.trim();
                          });
                        },
                      ),
                      const SizedBox(height: AppConstants.spacingMedium),
                    ],
                  ),
                ),
              if (_selectedGoal != null || _customGoal != null)
                Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingLarge),
                  child: CustomButton(
                    text: 'Continue',
                    onPressed: userUpdateState.isLoading ? null : _saveGoalSelection,
                    isLoading: userUpdateState.isLoading,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 