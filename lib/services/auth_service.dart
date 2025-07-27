import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> register({
    required String email,
    required String password,
    required String nickname,
    String? photoUrl,
  }) async {
    final userCred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await _db.collection('users').doc(userCred.user!.uid).set({
      'email': email,
      'nickname': nickname,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return userCred.user;
  }

  Future<User?> login(String email, String password) async {
    final userCred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return userCred.user;
  }

  Future<void> logout() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Future<bool> checkNicknameUnique(String nickname) async {
    final snap = await _db.collection('users').where('nickname', isEqualTo: nickname).get();
    return snap.docs.isEmpty;
  }

  Future<void> updateProfile(String uid, {String? nickname, String? photoUrl}) async {
    final data = <String, dynamic>{};
    if (nickname != null) data['nickname'] = nickname;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (data.isNotEmpty) {
      await _db.collection('users').doc(uid).update(data);
    }
  }

  Future<User?> googleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;
      if (user != null) {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _db.collection('users').doc(user.uid).set({
            'email': user.email,
            'nickname': user.displayName ?? 'User',
            'photoUrl': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }
} 