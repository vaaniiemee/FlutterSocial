import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile {
  final String uid;
  final String email;
  final String nickname;
  final String? photoUrl;
  final String? fromCountry;
  final String? toCountry;
  final String? purpose;

  UserProfile({
    required this.uid,
    required this.email,
    required this.nickname,
    this.photoUrl,
    this.fromCountry,
    this.toCountry,
    this.purpose,
  });

  UserProfile copyWith({
    String? nickname,
    String? photoUrl,
    String? fromCountry,
    String? toCountry,
    String? purpose,
  }) => UserProfile(
    uid: uid,
    email: email,
    nickname: nickname ?? this.nickname,
    photoUrl: photoUrl ?? this.photoUrl,
    fromCountry: fromCountry ?? this.fromCountry,
    toCountry: toCountry ?? this.toCountry,
    purpose: purpose ?? this.purpose,
  );

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) => UserProfile(
    uid: uid,
    email: data['email'] ?? '',
    nickname: data['nickname'] ?? '',
    photoUrl: data['photoUrl'],
    fromCountry: data['fromCountry'],
    toCountry: data['toCountry'],
    purpose: data['purpose'],
  );
}

final userProvider = StateNotifierProvider<UserNotifier, UserProfile?>((ref) => UserNotifier());

class UserNotifier extends StateNotifier<UserProfile?> {
  UserNotifier() : super(null);
  final _db = FirebaseFirestore.instance;

  Future<void> loadUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      state = UserProfile.fromMap(uid, doc.data()!);
    }
  }

  Future<void> saveOnboarding(String uid, String fromCountry, String toCountry, String purpose) async {
    await _db.collection('users').doc(uid).update({
      'fromCountry': fromCountry,
      'toCountry': toCountry,
      'purpose': purpose,
    });
    if (state != null) {
      state = state!.copyWith(
        fromCountry: fromCountry,
        toCountry: toCountry,
        purpose: purpose,
      );
    }
  }

  Future<void> updateProfile(String uid, {String? nickname, String? photoUrl}) async {
    final data = <String, dynamic>{};
    if (nickname != null) data['nickname'] = nickname;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (data.isNotEmpty) {
      await _db.collection('users').doc(uid).update(data);
      if (state != null) {
        state = state!.copyWith(nickname: nickname, photoUrl: photoUrl);
      }
    }
  }

  Future<void> loadOrCreateUser(User user) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      state = UserProfile(
        uid: user.uid,
        email: doc['email'],
        nickname: doc['nickname'],
        photoUrl: doc['photoUrl'],
        fromCountry: doc['fromCountry'],
        toCountry: doc['toCountry'],
        purpose: doc['purpose'],
      );
    } else {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'nickname': user.displayName ?? 'User',
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
      state = UserProfile(
        uid: user.uid,
        email: user.email!,
        nickname: user.displayName ?? 'User',
        photoUrl: user.photoURL,
        fromCountry: null,
        toCountry: null,
        purpose: null,
      );
    }
  }

  Future<void> followUser(String myUid, String otherUid) async {
    final db = FirebaseFirestore.instance;
    await db.collection('users').doc(myUid).collection('following').doc(otherUid).set({'uid': otherUid});
    await db.collection('users').doc(otherUid).collection('followers').doc(myUid).set({'uid': myUid});
  }

  Future<void> unfollowUser(String myUid, String otherUid) async {
    final db = FirebaseFirestore.instance;
    await db.collection('users').doc(myUid).collection('following').doc(otherUid).delete();
    await db.collection('users').doc(otherUid).collection('followers').doc(myUid).delete();
  }

  Future<int> getFollowersCount(String uid) async {
    final db = FirebaseFirestore.instance;
    final snap = await db.collection('users').doc(uid).collection('followers').get();
    return snap.size;
  }

  Future<int> getFollowingCount(String uid) async {
    final db = FirebaseFirestore.instance;
    final snap = await db.collection('users').doc(uid).collection('following').get();
    return snap.size;
  }
} 