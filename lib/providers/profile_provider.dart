import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'user_provider.dart';

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<void>>((ref) {
  return ProfileNotifier(ref);
});

final interestsProvider = StateProvider<List<String>>((ref) => []);
final selectedInterestsProvider = StateProvider<Set<String>>((ref) => {});

class ProfileNotifier extends StateNotifier<AsyncValue<void>> {
  ProfileNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> updateProfile({
    String? name,
    String? username,
    String? bio,
    String? website,
    String? location,
    List<String>? interests,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{};
      
      if (name != null) {
        updateData['name'] = name;
        await user.updateDisplayName(name);
      }
      
      if (username != null) {
        // Check if username is available (only if it's different from current username)
        final currentUserData = await _firestore.collection('users').doc(user.uid).get();
        final currentUsername = currentUserData.data()?['username'];
        
        if (username != currentUsername) {
          final usernameExists = await _checkUsernameAvailability(username);
          if (usernameExists) {
            throw Exception('Username is already taken');
          }
        }
        updateData['username'] = username;
      }
      
      if (bio != null) updateData['bio'] = bio;
      if (website != null) updateData['website'] = website;
      if (location != null) updateData['location'] = location;
      if (interests != null) updateData['interests'] = interests;
      
      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updateData);
        // Invalidate user data to refresh UI
        _ref.invalidate(userDataProvider);
      }
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<String> uploadProfileImage(File imageFile, {bool isBanner = false}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fileName = isBanner ? 'banner_${user.uid}' : 'profile_${user.uid}';
      final ref = _storage.ref().child('users/${user.uid}/$fileName');
      
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Update user document with new image URL
      await _firestore.collection('users').doc(user.uid).update({
        isBanner ? 'bannerURL' : 'photoURL': downloadUrl,
      });
      
      // Invalidate user data to refresh UI
      _ref.invalidate(userDataProvider);
      
      return downloadUrl;
    } catch (e) {
      // Handle specific Firebase Storage errors
      if (e.toString().contains('permission-denied')) {
        throw Exception('Permission denied. Please check your account permissions.');
      } else if (e.toString().contains('unauthenticated')) {
        throw Exception('Please sign in again to upload images.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error. Please check your internet connection.');
      } else if (e.toString().contains('quota')) {
        throw Exception('Storage quota exceeded. Please try a smaller image.');
      } else {
        throw Exception('Failed to upload image: ${e.toString()}');
      }
    }
  }

  Future<File?> pickImage({bool isBanner = false}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: isBanner ? 1200 : 400,
        maxHeight: isBanner ? 400 : 400,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      // Handle specific image picker errors
      if (e.toString().contains('Permission denied')) {
        throw Exception('Camera/Gallery permission denied. Please enable permissions in settings.');
      } else if (e.toString().contains('No image selected')) {
        return null; // User cancelled, not an error
      } else if (e.toString().contains('Image source not available')) {
        throw Exception('Gallery is not available. Please try again.');
      } else {
        throw Exception('Failed to pick image: ${e.toString()}');
      }
    }
  }

  Future<bool> _checkUsernameAvailability(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return true; // Assume taken if error occurs
    }
  }

  Future<void> loadInterests() async {
    try {
      await _firestore.collection('interests').get();
      // final interests = snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
      // This would need to be handled by a separate provider
    } catch (e) {
      // Handle error
    }
  }

  Future<void> addPost({
    required String caption,
    required List<String> imageUrls,
    List<String>? tags,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('posts').add({
        'userId': user.uid,
        'caption': caption,
        'imageUrls': imageUrls,
        'tags': tags ?? [],
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
      });
    } catch (e) {
      throw Exception('Failed to add post: $e');
    }
  }

  // Note: Follow/unfollow functionality is handled in chat_provider.dart
  // using the 'follows' collection instead of subcollections
}
