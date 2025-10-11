import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String? username;
  final String? userPhotoUrl;
  final String content;
  final List<String> imageUrls;
  final List<String> tags;
  final String category;
  final int likesCount;
  final int commentsCount;
  final int repostsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRepost;
  final String? originalPostId;
  final String? repostReason;
  final bool isThread;
  final String? threadParentId;
  final List<String> threadReplies;

  Post({
    required this.id,
    required this.userId,
    this.username,
    this.userPhotoUrl,
    required this.content,
    this.imageUrls = const [],
    this.tags = const [],
    required this.category,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.repostsCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isRepost = false,
    this.originalPostId,
    this.repostReason,
    this.isThread = false,
    this.threadParentId,
    this.threadReplies = const [],
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'],
      userPhotoUrl: data['userPhotoUrl'],
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      category: data['category'] ?? '',
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      repostsCount: data['repostsCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isRepost: data['isRepost'] ?? false,
      originalPostId: data['originalPostId'],
      repostReason: data['repostReason'],
      isThread: data['isThread'] ?? false,
      threadParentId: data['threadParentId'],
      threadReplies: List<String>.from(data['threadReplies'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'imageUrls': imageUrls,
      'tags': tags,
      'category': category,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'repostsCount': repostsCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isRepost': isRepost,
      'originalPostId': originalPostId,
      'repostReason': repostReason,
      'isThread': isThread,
      'threadParentId': threadParentId,
      'threadReplies': threadReplies,
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    String? username,
    String? userPhotoUrl,
    String? content,
    List<String>? imageUrls,
    List<String>? tags,
    String? category,
    int? likesCount,
    int? commentsCount,
    int? repostsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRepost,
    String? originalPostId,
    String? repostReason,
    bool? isThread,
    String? threadParentId,
    List<String>? threadReplies,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      repostsCount: repostsCount ?? this.repostsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRepost: isRepost ?? this.isRepost,
      originalPostId: originalPostId ?? this.originalPostId,
      repostReason: repostReason ?? this.repostReason,
      isThread: isThread ?? this.isThread,
      threadParentId: threadParentId ?? this.threadParentId,
      threadReplies: threadReplies ?? this.threadReplies,
    );
  }
}

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String? username;
  final String? userPhotoUrl;
  final String content;
  final int likesCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? parentCommentId;
  final List<String> replies;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    this.username,
    this.userPhotoUrl,
    required this.content,
    this.likesCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.parentCommentId,
    this.replies = const [],
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      username: data['username'],
      userPhotoUrl: data['userPhotoUrl'],
      content: data['content'] ?? '',
      likesCount: data['likesCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      parentCommentId: data['parentCommentId'],
      replies: List<String>.from(data['replies'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'username': username,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'likesCount': likesCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'parentCommentId': parentCommentId,
      'replies': replies,
    };
  }
}

class PostInteraction {
  final String id;
  final String postId;
  final String userId;
  final String type; // 'like', 'repost', 'bookmark'
  final DateTime createdAt;

  PostInteraction({
    required this.id,
    required this.postId,
    required this.userId,
    required this.type,
    required this.createdAt,
  });

  factory PostInteraction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostInteraction(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
