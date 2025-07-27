import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_provider.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

class AuthState {
  final User? user;
  AuthState({this.user});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();
  final Ref ref;

  AuthNotifier(this.ref) : super(AuthState(user: FirebaseAuth.instance.currentUser)) {
    if (state.user != null) {
      ref.read(userProvider.notifier).loadUser(state.user!.uid);
    }
  }

  Future<User?> register({required String email, required String password, required String nickname, String? photoUrl}) async {
    final user = await _authService.register(email: email, password: password, nickname: nickname, photoUrl: photoUrl);
    if (user != null) {
      state = AuthState(user: user);
      ref.read(userProvider.notifier).loadUser(user.uid);
    }
    return user;
  }

  Future<User?> login(String email, String password) async {
    final user = await _authService.login(email, password);
    if (user != null) {
      state = AuthState(user: user);
      ref.read(userProvider.notifier).loadUser(user.uid);
    }
    return user;
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState(user: null);
    ref.read(userProvider.notifier).state = null;
  }

  Future<bool> checkNicknameUnique(String nickname) async {
    return await _authService.checkNicknameUnique(nickname);
  }

  Future<User?> googleSignIn() async {
    final user = await _authService.googleSignIn();
    if (user != null) {
      state = AuthState(user: user);
      await ref.read(userProvider.notifier).loadOrCreateUser(user);
    }
    return user;
  }

  void setUser(User? user) {
    state = AuthState(user: user);
    if (user != null) {
      ref.read(userProvider.notifier).loadUser(user.uid);
    }
  }
} 