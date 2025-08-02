import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'country_selection_screen.dart';

class GoalsSelectionScreen extends StatefulWidget {
  const GoalsSelectionScreen({super.key});

  @override
  State<GoalsSelectionScreen> createState() => _GoalsSelectionScreenState();
}

class _GoalsSelectionScreenState extends State<GoalsSelectionScreen> {
  String? _selectedGoal;
  String? _customGoal;
  bool _isLoading = false;
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

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final goalToSave = _selectedGoal == 'other' && _customGoal != null 
            ? _customGoal 
            : _selectedGoal;
            
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'goal': goalToSave,
          'hasCompletedOnboarding': true,
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save goal selection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }



  @override
  void dispose() {
    _customGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
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
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'What are your goals?',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select your primary goal to help us personalize your experience',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
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
                      const SizedBox(width: 8),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                                     const SizedBox(height: 24),
                 ],
               ),
             ),
             Expanded(
               child: Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 24),
                 child: GridView.builder(
                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                     crossAxisCount: 2,
                     crossAxisSpacing: 12,
                     mainAxisSpacing: 12,
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
                          borderRadius: BorderRadius.circular(16),
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
                           padding: const EdgeInsets.all(12),
                           child: Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Icon(
                                 goal['icon'],
                                 size: 28,
                                 color: isSelected ? Colors.white : goal['color'],
                               ),
                               const SizedBox(height: 8),
                                                             Text(
                                 goal['id'] == 'other' && _customGoal != null 
                                     ? _customGoal! 
                                     : goal['title'],
                                                                  style: GoogleFonts.poppins(
                                   fontSize: 14,
                                   fontWeight: FontWeight.w600,
                                   color: isSelected ? Colors.white : Colors.black,
                                 ),
                                 textAlign: TextAlign.center,
                                 maxLines: 2,
                                 overflow: TextOverflow.ellipsis,
                               ),
                               const SizedBox(height: 2),
                               Text(
                                 goal['description'],
                                 style: GoogleFonts.poppins(
                                   fontSize: 10,
                                   color: isSelected ? Colors.white70 : Colors.black54,
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
                 padding: const EdgeInsets.symmetric(horizontal: 24),
                 child: Column(
                   children: [
                     const SizedBox(height: 16),
                     TextField(
                       controller: _customGoalController,
                       decoration: InputDecoration(
                         hintText: 'Type your goal here...',
                         border: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(12),
                         ),
                         focusedBorder: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(12),
                           borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
                         ),
                         filled: true,
                         fillColor: Colors.grey[50],
                       ),
                       onChanged: (value) {
                         setState(() {
                           _customGoal = value.trim();
                         });
                       },
                     ),
                     const SizedBox(height: 16),
                   ],
                 ),
               ),
             if (_selectedGoal != null || _customGoal != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveGoalSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Continue',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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