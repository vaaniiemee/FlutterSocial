import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String nickname,
    String? photoUrl,
    String? country,
    Map<String, dynamic>? onboardingAnswers,
  }) async {
    final userCred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = userCred.user;
    if (user == null) return null;
    final userModel = UserModel(
      uid: user.uid,
      nickname: nickname,
      email: email,
      photoUrl: photoUrl,
      country: country,
      onboardingAnswers: onboardingAnswers,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );
    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
    return userModel;
  }

  Future<UserModel?> signInWithEmail({required String email, required String password}) async {
    final userCred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = userCred.user;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> updateProfile(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }
} 