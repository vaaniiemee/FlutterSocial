import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/common/loading_overlay.dart';
import '../constants/app_constants.dart';
import 'country_selection_screen.dart';


class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLogin = true;
  bool _obscurePassword = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isLogin) {
      await ref.read(authNotifierProvider.notifier).signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      await ref.read(authNotifierProvider.notifier).createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
    }
    
    // Listen to auth state changes to navigate
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const CountrySelectionScreen(),
            ),
          );
        }
      });
    });
  }

  Future<void> _signInWithGoogle() async {
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    
    // Listen to auth state changes to navigate
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const CountrySelectionScreen(),
            ),
          );
        }
      });
    });
  }

  Future<void> _signInWithApple() async {
    await ref.read(authNotifierProvider.notifier).signInWithApple();
    
    // Listen to auth state changes to navigate
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const CountrySelectionScreen(),
            ),
          );
        }
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);
    
    // Listen to auth errors
    ref.listen(authErrorProvider, (previous, next) {
      if (next != null && mounted) {
        ErrorSnackBar.show(context, next);
        ref.read(authErrorProvider.notifier).state = null;
      }
    });

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.spacingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppConstants.spacingXXLarge),
                    
                    Text(
                      AppConstants.appName,
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.fontSizeHeading,
                        fontWeight: AppConstants.fontWeightBold,
                        color: AppConstants.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: AppConstants.spacingSmall),
                    
                    Text(
                      _isLogin ? 'Welcome back!' : 'Create your account',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.fontSizeLarge,
                        color: AppConstants.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: AppConstants.spacingXXLarge),
                    
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacingLarge),
                      decoration: BoxDecoration(
                        color: AppConstants.backgroundColor,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                        boxShadow: AppConstants.elevatedShadow,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (!_isLogin) ...[
                              CustomTextField(
                                controller: _nameController,
                                labelText: 'Full Name',
                                prefixIcon: const Icon(Icons.person),
                                isRequired: true,
                                validator: (value) {
                                  if (!_isLogin && (value == null || value.isEmpty)) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppConstants.spacingMedium),
                            ],
                            
                            CustomTextField(
                              controller: _emailController,
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: const Icon(Icons.email),
                              isRequired: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: AppConstants.spacingMedium),
                            
                            CustomTextField(
                              controller: _passwordController,
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              obscureText: _obscurePassword,
                              prefixIcon: const Icon(Icons.lock),
                              isRequired: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: AppConstants.spacingLarge),
                            
                            CustomButton(
                              text: _isLogin ? 'Sign In' : 'Sign Up',
                              onPressed: _submitForm,
                              isLoading: isLoading,
                            ),
                            
                            const SizedBox(height: AppConstants.spacingMedium),
                            
                            TextButton(
                              onPressed: _toggleAuthMode,
                              child: Text(
                                _isLogin
                                    ? 'Don\'t have an account? Sign Up'
                                    : 'Already have an account? Sign In',
                                style: GoogleFonts.poppins(
                                  color: AppConstants.primaryColor,
                                  fontWeight: AppConstants.fontWeightMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.spacingXLarge),
                    
                    Text(
                      'Or continue with',
                      style: GoogleFonts.poppins(
                        color: AppConstants.textSecondary,
                        fontSize: AppConstants.fontSizeMedium,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: AppConstants.spacingLarge),
                    
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Google',
                            type: ButtonType.outline,
                            onPressed: isLoading ? null : _signInWithGoogle,
                            height: AppConstants.buttonHeightLarge,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/icons/google.png',
                                  height: AppConstants.iconSizeMedium,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.g_mobiledata, size: AppConstants.iconSizeMedium);
                                  },
                                ),
                                const SizedBox(width: AppConstants.spacingSmall),
                                Text(
                                  'Google',
                                  style: GoogleFonts.poppins(
                                    fontSize: AppConstants.fontSizeMedium,
                                    fontWeight: AppConstants.fontWeightSemiBold,
                                    color: AppConstants.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: AppConstants.spacingMedium),
                        
                        Expanded(
                          child: CustomButton(
                            text: 'Apple',
                            type: ButtonType.outline,
                            onPressed: isLoading ? null : _signInWithApple,
                            height: AppConstants.buttonHeightLarge,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.apple, size: AppConstants.iconSizeMedium),
                                const SizedBox(width: AppConstants.spacingSmall),
                                Text(
                                  'Apple',
                                  style: GoogleFonts.poppins(
                                    fontSize: AppConstants.fontSizeLarge,
                                    fontWeight: AppConstants.fontWeightSemiBold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
//flutter flow
 