import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      final userDoc = await _firestore.collection('users').doc(result.user!.uid).get();
      
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'name': result.user!.displayName ?? 'User',
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'photoURL': null,
          'hasCompletedOnboarding': false,
        });
      }
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      await result.user?.updateDisplayName(name);
      
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'photoURL': null,
        'hasCompletedOnboarding': false,
      });
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      
      final userDoc = await _firestore.collection('users').doc(result.user!.uid).get();
      
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'name': result.user!.displayName,
          'email': result.user!.email,
          'photoURL': result.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'hasCompletedOnboarding': false,
        });
      }
      
      return result;
    } catch (e) {
      String errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('network_error') || 
          errorMessage.contains('sign_in_failed') ||
          errorMessage.contains('unknown') ||
          errorMessage.contains('developer_error') ||
          errorMessage.contains('invalid_account')) {
        throw Exception('Google Sign-In is not available on this device. Please use email/password instead.');
      }
      rethrow;
    }
  }

  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      UserCredential result = await _auth.signInWithCredential(oauthCredential);
      
      if (result.additionalUserInfo?.isNewUser == true) {
        String displayName = '';
        if (appleCredential.givenName != null && appleCredential.familyName != null) {
          displayName = '${appleCredential.givenName} ${appleCredential.familyName}';
        }
        
        await result.user?.updateDisplayName(displayName);
        
        await _firestore.collection('users').doc(result.user!.uid).set({
          'name': displayName.isNotEmpty ? displayName : 'Apple User',
          'email': result.user!.email,
          'photoURL': null,
          'createdAt': FieldValue.serverTimestamp(),
          'hasCompletedOnboarding': false,
        });
      }
      
      return result;
    } catch (e) {
      String errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('not_available') || 
          errorMessage.contains('sign_in_failed') ||
          errorMessage.contains('cancelled') ||
          errorMessage.contains('not_supported')) {
        throw Exception('Apple Sign-In is not available on this device. Please use email/password instead.');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<bool> hasCompletedOnboarding() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;
      
      return doc.data()?['hasCompletedOnboarding'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateOnboardingStatus(bool completed) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      await _firestore.collection('users').doc(user.uid).update({
        'hasCompletedOnboarding': completed,
      });
    } catch (e) {
      rethrow;
    }
  }
} 