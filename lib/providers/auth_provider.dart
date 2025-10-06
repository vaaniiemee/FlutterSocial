import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

final isLoadingProvider = StateProvider<bool>((ref) => false);

final authErrorProvider = StateProvider<String?>((ref) => null);

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(const AsyncValue.data(null));

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncValue.loading();
    _ref.read(isLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      await _authService.signInWithEmailAndPassword(email, password);
      state = const AsyncValue.data(null);
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      _ref.read(authErrorProvider.notifier).state = errorMessage;
      state = AsyncValue.error(e, StackTrace.current);
    } finally {
      _ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> createUserWithEmailAndPassword(String email, String password, String name) async {
    state = const AsyncValue.loading();
    _ref.read(isLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      await _authService.createUserWithEmailAndPassword(email, password, name);
      state = const AsyncValue.data(null);
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      _ref.read(authErrorProvider.notifier).state = errorMessage;
      state = AsyncValue.error(e, StackTrace.current);
    } finally {
      _ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    _ref.read(isLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        state = const AsyncValue.data(null);
      } else {
        _ref.read(authErrorProvider.notifier).state = 'Google sign-in was cancelled';
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      _ref.read(authErrorProvider.notifier).state = errorMessage;
      state = AsyncValue.error(e, StackTrace.current);
    } finally {
      _ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    _ref.read(isLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      final result = await _authService.signInWithApple();
      if (result != null) {
        state = const AsyncValue.data(null);
      } else {
        _ref.read(authErrorProvider.notifier).state = 'Apple sign-in was cancelled';
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      _ref.read(authErrorProvider.notifier).state = errorMessage;
      state = AsyncValue.error(e, StackTrace.current);
    } finally {
      _ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    _ref.read(isLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      _ref.read(authErrorProvider.notifier).state = errorMessage;
      state = AsyncValue.error(e, StackTrace.current);
    } finally {
      _ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    _ref.read(isLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      await _authService.resetPassword(email);
      state = const AsyncValue.data(null);
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      _ref.read(authErrorProvider.notifier).state = errorMessage;
      state = AsyncValue.error(e, StackTrace.current);
    } finally {
      _ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  void clearError() {
    _ref.read(authErrorProvider.notifier).state = null;
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'User not found. Please check your email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Wrong password. Please try again.';
        case 'email-already-in-use':
          return 'Email already exists. Please sign in instead.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        case 'popup-closed-by-user':
        case 'cancelled':
          return 'Sign in cancelled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'user-disabled':
          return 'Account is disabled. Please contact support.';
        case 'operation-not-allowed':
          return 'Sign in method not enabled.';
        case 'rejected':
          return 'Sign in was rejected. Please try again.';
        case 'recaptcha-token-expired':
          return 'Security check expired. Please try again.';
        case 'recaptcha-token-invalid':
          return 'Security check failed. Please try again.';
        default:
          return 'An error occurred. Please try again.';
      }
    }
    
    String errorString = error.toString().toLowerCase();
    
    if (errorString.contains('user-not-found')) {
      return 'User not found. Please check your email.';
    } else if (errorString.contains('wrong-password') || errorString.contains('invalid-credential')) {
      return 'Wrong password. Please try again.';
    } else if (errorString.contains('email-already-in-use')) {
      return 'Email already exists. Please sign in instead.';
    } else if (errorString.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    } else if (errorString.contains('invalid-email')) {
      return 'Invalid email address.';
    } else if (errorString.contains('network-request-failed')) {
      return 'Network error. Please check your connection.';
    } else if (errorString.contains('rejected')) {
      return 'Sign in was rejected. Please try again.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});
