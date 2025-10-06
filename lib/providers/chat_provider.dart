import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final chatProvider = Provider<ChatService>((ref) => ChatService());

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get or create a chat between two users
  Future<String> getOrCreateChat(String otherUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    // Check if chat already exists
    final existingChats = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (final chat in existingChats.docs) {
      final participants = List<String>.from(chat.data()['participants'] ?? []);
      if (participants.contains(otherUserId)) {
        return chat.id;
      }
    }

    // Create new chat
    final chatRef = await _firestore.collection('chats').add({
      'participants': [currentUserId, otherUserId],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': {currentUserId: 0, otherUserId: 0},
    });

    return chatRef.id;
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      // Add message to messages subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });

      // Update chat document
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {
          currentUserId: 0,
          // Increment unread count for other participants
        },
      });

      // Get other participants and update their unread count
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        final participants = List<String>.from(chatDoc.data()!['participants'] ?? []);
        final otherParticipants = participants.where((id) => id != currentUserId).toList();
        
        final unreadUpdate = <String, dynamic>{};
        for (final participant in otherParticipants) {
          unreadUpdate['unreadCount.$participant'] = FieldValue.increment(1);
        }
        
        if (unreadUpdate.isNotEmpty) {
          await _firestore.collection('chats').doc(chatId).update(unreadUpdate);
        }
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Mark messages as read
  Future<void> markAsRead(String chatId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$currentUserId': 0,
      });
    } catch (e) {
      // Handle error silently
    }
  }

  // Get user's chats
  Stream<QuerySnapshot> getUserChats() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots();
  }

  // Get messages for a specific chat
  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Search users
  Stream<QuerySnapshot> searchUsers(String query) {
    if (query.isEmpty) {
      return Stream.empty();
    }

    return _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: query + 'z')
        .limit(20)
        .snapshots();
  }

  // Get user data
  Future<DocumentSnapshot> getUserData(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  // Follow/Unfollow user
  Future<void> toggleFollow(String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    final followRef = _firestore
        .collection('follows')
        .doc('${currentUserId}_$userId');

    final followDoc = await followRef.get();

    if (followDoc.exists) {
      // Unfollow
      await followRef.delete();
      
      // Update follower count
      await _firestore.collection('users').doc(userId).update({
        'followersCount': FieldValue.increment(-1),
      });
      
      // Update following count
      await _firestore.collection('users').doc(currentUserId).update({
        'followingCount': FieldValue.increment(-1),
      });
    } else {
      // Follow
      await followRef.set({
        'followerId': currentUserId,
        'followingId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update follower count
      await _firestore.collection('users').doc(userId).update({
        'followersCount': FieldValue.increment(1),
      });
      
      // Update following count
      await _firestore.collection('users').doc(currentUserId).update({
        'followingCount': FieldValue.increment(1),
      });
    }
  }

  // Check if user is following another user
  Future<bool> isFollowing(String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;

    final followDoc = await _firestore
        .collection('follows')
        .doc('${currentUserId}_$userId')
        .get();

    return followDoc.exists;
  }
}
