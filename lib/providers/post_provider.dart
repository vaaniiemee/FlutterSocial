import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/post_model.dart';

final postsProvider = StreamProvider<List<Post>>((ref) {
  return FirebaseFirestore.instance
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList());
});

final searchPostsProvider = StreamProvider.family<List<Post>, String>((ref, query) {
  if (query.isEmpty) {
    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList());
  }
  
  // For text search, we'll filter on the client side
  return FirebaseFirestore.instance
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .limit(100) // Get more posts to filter on client side
      .snapshots()
      .map((snapshot) {
        final posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
        // Filter posts that contain the search query
        return posts.where((post) => 
          post.content.toLowerCase().contains(query.toLowerCase()) ||
          post.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()))
        ).toList();
      });
});

final categoryPostsProvider = StreamProvider.family<List<Post>, String>((ref, category) {
  // Use client-side filtering to avoid composite index requirements
  return FirebaseFirestore.instance
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .limit(100) // Get more posts to filter on client side
      .snapshots()
      .map((snapshot) {
        final posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
        // Filter posts by category on client side
        return posts.where((post) => post.category == category).toList();
      });
});

final searchAndCategoryPostsProvider = StreamProvider.family<List<Post>, Map<String, String>>((ref, params) {
  final query = params['query'] ?? '';
  final category = params['category'] ?? '';
  
  // Use client-side filtering to avoid composite index requirements
  return FirebaseFirestore.instance
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .limit(100) // Get more posts to filter on client side
      .snapshots()
      .map((snapshot) {
        final posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
        
        // Filter by category if specified
        var filteredPosts = posts;
        if (category.isNotEmpty && category != 'all') {
          filteredPosts = posts.where((post) => post.category == category).toList();
        }
        
        // Filter by search query if specified
        if (query.isNotEmpty) {
          filteredPosts = filteredPosts.where((post) => 
            post.content.toLowerCase().contains(query.toLowerCase()) ||
            post.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()))
          ).toList();
        }
        
        return filteredPosts;
      });
});

final postNotifierProvider = StateNotifierProvider<PostNotifier, AsyncValue<void>>((ref) {
  return PostNotifier(ref);
});

final userPostsProvider = StreamProvider.family<List<Post>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('posts')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
    final posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    
    // Sort posts by creation date on client side
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return posts;
  });
});

final postCommentsProvider = StreamProvider.family<List<Comment>, String>((ref, postId) {
  return FirebaseFirestore.instance
      .collection('posts')
      .doc(postId)
      .collection('comments')
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList());
});

final postInteractionsProvider = StreamProvider.family<List<PostInteraction>, String>((ref, postId) {
  return FirebaseFirestore.instance
      .collection('posts')
      .doc(postId)
      .collection('interactions')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => PostInteraction.fromFirestore(doc)).toList());
});

final userInteractionsProvider = StreamProvider.family<List<PostInteraction>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('interactions')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => PostInteraction.fromFirestore(doc)).toList());
});

final isPostLikedProvider = FutureProvider.family<bool, String>((ref, postId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  
  final interactionId = '${user.uid}_${postId}_like';
  final doc = await FirebaseFirestore.instance
      .collection('interactions')
      .doc(interactionId)
      .get();
  
  return doc.exists;
});

final isPostRepostedProvider = FutureProvider.family<bool, String>((ref, postId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  
  final interactionId = '${user.uid}_${postId}_repost';
  final doc = await FirebaseFirestore.instance
      .collection('interactions')
      .doc(interactionId)
      .get();
  
  return doc.exists;
});

class PostNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  PostNotifier(this._ref) : super(const AsyncValue.data(null));

  String? _getUserDataField(dynamic userData, String field) {
    if (userData is Map<String, dynamic>) {
      return userData[field]?.toString();
    }
    return null;
  }

  Future<void> createPost({
    required String content,
    List<File>? images,
    List<String>? tags,
    String? category,
    bool isThread = false,
    String? threadParentId,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      var userData = userDoc.data();
      
      // If user document doesn't exist, create it
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'username': user.displayName ?? 'User',
          'photoURL': user.photoURL,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'postsCount': 0,
          'followersCount': 0,
          'followingCount': 0,
        });
        // Re-fetch user data
        final newUserDoc = await _firestore.collection('users').doc(user.uid).get();
        userData = newUserDoc.data();
      }
      
      List<String> imageUrls = [];
      
      // Upload images if provided
      if (images != null && images.isNotEmpty) {
        try {
          for (int i = 0; i < images.length; i++) {
            final imageUrl = await _uploadPostImage(images[i], user.uid, i);
            imageUrls.add(imageUrl);
          }
        } catch (e) {
          // If image upload fails, throw a more specific error
          throw Exception('Failed to upload images: ${e.toString()}');
        }
      }

      // Create post document
      final postData = {
        'userId': user.uid,
        'username': _getUserDataField(userData, 'username') ?? user.displayName ?? 'User',
        'userPhotoUrl': _getUserDataField(userData, 'photoURL') ?? user.photoURL,
        'content': content,
        'imageUrls': imageUrls,
        'tags': tags ?? [],
        'category': category ?? '',
        'likesCount': 0,
        'commentsCount': 0,
        'repostsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isRepost': false,
        'isThread': isThread,
        'threadParentId': threadParentId,
        'threadReplies': [],
      };

      final postRef = await _firestore.collection('posts').add(postData);

      // If this is a thread reply, update the parent thread
      if (isThread && threadParentId != null) {
        await _firestore.collection('posts').doc(threadParentId).update({
          'threadReplies': FieldValue.arrayUnion([postRef.id]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update user's post count
      await _firestore.collection('users').doc(user.uid).update({
        'postsCount': FieldValue.increment(1),
      });

      // Invalidate posts provider to refresh UI
      _ref.invalidate(postsProvider);
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> repost({
    required String postId,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get original post
      final originalPost = await _firestore.collection('posts').doc(postId).get();
      if (!originalPost.exists) throw Exception('Post not found');
      
      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      // Create repost document
      final repostData = {
        'userId': user.uid,
        'username': _getUserDataField(userData, 'username') ?? user.displayName ?? 'User',
        'userPhotoUrl': _getUserDataField(userData, 'photoURL') ?? user.photoURL,
        'content': reason ?? '',
        'imageUrls': [],
        'tags': [],
        'category': '', // Reposts don't have categories
        'likesCount': 0,
        'commentsCount': 0,
        'repostsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isRepost': true,
        'originalPostId': postId,
        'repostReason': reason,
        'isThread': false,
        'threadReplies': [],
      };

      await _firestore.collection('posts').add(repostData);

      // Update original post repost count
      await _firestore.collection('posts').doc(postId).update({
        'repostsCount': FieldValue.increment(1),
      });

      // Create interaction record
      final interactionId = '${user.uid}_${postId}_repost';
      await _firestore.collection('interactions').doc(interactionId).set({
        'postId': postId,
        'userId': user.uid,
        'type': 'repost',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Invalidate posts provider to refresh UI
      _ref.invalidate(postsProvider);
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> likePost(String postId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final interactionId = '${user.uid}_${postId}_like';
      
      // Check if already liked
      final existingInteraction = await _firestore
          .collection('interactions')
          .doc(interactionId)
          .get();

      if (existingInteraction.exists) {
        // Unlike
        await existingInteraction.reference.delete();
        await _firestore.collection('posts').doc(postId).update({
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        await _firestore.collection('interactions').doc(interactionId).set({
          'postId': postId,
          'userId': user.uid,
          'type': 'like',
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _firestore.collection('posts').doc(postId).update({
          'likesCount': FieldValue.increment(1),
        });
      }

      // Invalidate posts provider to refresh UI
      _ref.invalidate(postsProvider);
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  Future<void> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      // Add comment to post's comments subcollection
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'postId': postId,
        'userId': user.uid,
        'username': _getUserDataField(userData, 'username') ?? user.displayName ?? 'User',
        'userPhotoUrl': _getUserDataField(userData, 'photoURL') ?? user.photoURL,
        'content': content,
        'likesCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'parentCommentId': parentCommentId,
        'replies': [],
      });

      // Update post comment count
      await _firestore.collection('posts').doc(postId).update({
        'commentsCount': FieldValue.increment(1),
      });

      // If replying to a comment, update parent comment
      if (parentCommentId != null) {
        final parentComment = await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(parentCommentId)
            .get();
        
        if (parentComment.exists) {
          await parentComment.reference.update({
            'replies': FieldValue.arrayUnion([postId]),
          });
        }
      }

      // Invalidate comments provider to refresh UI
      _ref.invalidate(postCommentsProvider(postId));
      _ref.invalidate(postsProvider);
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  Future<void> likeComment(String postId, String commentId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final interactionId = '${user.uid}_${commentId}_like';
      
      // Check if already liked
      final existingInteraction = await _firestore
          .collection('interactions')
          .doc(interactionId)
          .get();

      if (existingInteraction.exists) {
        // Unlike
        await existingInteraction.reference.delete();
        await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .update({
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        await _firestore.collection('interactions').doc(interactionId).set({
          'postId': postId,
          'commentId': commentId,
          'userId': user.uid,
          'type': 'comment_like',
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .update({
          'likesCount': FieldValue.increment(1),
        });
      }

      // Invalidate comments provider to refresh UI
      _ref.invalidate(postCommentsProvider(postId));
    } catch (e) {
      throw Exception('Failed to like comment: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    state = const AsyncValue.loading();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get post to verify ownership
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) throw Exception('Post not found');
      
      final postData = postDoc.data() as Map<String, dynamic>;
      if (postData['userId'] != user.uid) throw Exception('Not authorized to delete this post');

      // Delete post images from storage
      final imageUrls = List<String>.from(postData['imageUrls'] ?? []);
      for (final imageUrl in imageUrls) {
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          // Continue even if image deletion fails
        }
      }

      // Delete post
      await _firestore.collection('posts').doc(postId).delete();

      // Delete all interactions for this post
      final interactions = await _firestore
          .collection('interactions')
          .where('postId', isEqualTo: postId)
          .get();
      
      for (final interaction in interactions.docs) {
        await interaction.reference.delete();
      }

      // Update user's post count
      await _firestore.collection('users').doc(user.uid).update({
        'postsCount': FieldValue.increment(-1),
      });

      // Invalidate posts provider to refresh UI
      _ref.invalidate(postsProvider);
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updatePost({
    required String postId,
    required String content,
    required String category,
    required List<String> tags,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get post to verify ownership
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) throw Exception('Post not found');
      
      final postData = postDoc.data() as Map<String, dynamic>;
      if (postData['userId'] != user.uid) throw Exception('Not authorized to update this post');

      await _firestore.collection('posts').doc(postId).update({
        'content': content,
        'category': category,
        'tags': tags,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate providers to refresh UI
      _ref.invalidate(postsProvider);
      _ref.invalidate(userPostsProvider(user.uid));
      
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<List<File>> pickImages({int maxImages = 4}) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (images.length > maxImages) {
        throw Exception('Maximum $maxImages images allowed');
      }
      
      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      if (e.toString().contains('Permission denied')) {
        throw Exception('Camera/Gallery permission denied. Please enable permissions in settings.');
      } else if (e.toString().contains('No image selected')) {
        return []; // User cancelled, not an error
      } else if (e.toString().contains('Image source not available')) {
        throw Exception('Gallery is not available. Please try again.');
      } else {
        throw Exception('Failed to pick images: ${e.toString()}');
      }
    }
  }

  Future<String> _uploadPostImage(File imageFile, String userId, int index) async {
    try {
      final fileName = 'post_${userId}_${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
      final ref = _storage.ref().child('posts/$userId/$fileName');
      
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      // Provide more specific error messages
      if (e.toString().contains('permission-denied')) {
        throw Exception('Permission denied: Unable to upload image. Please check your authentication.');
      } else if (e.toString().contains('unauthorized')) {
        throw Exception('Unauthorized: Please sign in again to upload images.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error: Please check your internet connection and try again.');
      } else {
        throw Exception('Failed to upload image: ${e.toString()}');
      }
    }
  }

  Future<bool> isPostLiked(String postId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final interactionId = '${user.uid}_${postId}_like';
      final interaction = await _firestore
          .collection('interactions')
          .doc(interactionId)
          .get();

      return interaction.exists;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isPostReposted(String postId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final interaction = await _firestore
          .collection('interactions')
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'repost')
          .limit(1)
          .get();

      return interaction.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
