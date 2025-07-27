class UserModel {
  final String uid;
  final String nickname;
  final String email;
  final String? photoUrl;
  final String? country;
  final Map<String, dynamic>? onboardingAnswers;
  final DateTime createdAt;
  final DateTime lastActive;

  UserModel({
    required this.uid,
    required this.nickname,
    required this.email,
    this.photoUrl,
    this.country,
    this.onboardingAnswers,
    required this.createdAt,
    required this.lastActive,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      nickname: map['nickname'] as String,
      email: map['email'] as String,
      photoUrl: map['photoUrl'] as String?,
      country: map['country'] as String?,
      onboardingAnswers: map['onboardingAnswers'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastActive: DateTime.parse(map['lastActive'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nickname': nickname,
      'email': email,
      'photoUrl': photoUrl,
      'country': country,
      'onboardingAnswers': onboardingAnswers,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
    };
  }
} 