import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  Future<String> createChat(String userId1, String userId2) async {
    final chats = await _db.collection('chats')
      .where('members', arrayContains: userId1)
      .get();
    for (final doc in chats.docs) {
      final members = List<String>.from(doc['members']);
      if (members.contains(userId2)) return doc.id;
    }
    final doc = await _db.collection('chats').add({
      'members': [userId1, userId2],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getUserChats(String userId) {
    return _db.collection('chats')
      .where('members', arrayContains: userId)
      .orderBy('lastMessageAt', descending: true)
      .snapshots();
  }

  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _db.collection('chats').doc(chatId).collection('messages')
      .orderBy('createdAt', descending: false)
      .snapshots();
  }
} 