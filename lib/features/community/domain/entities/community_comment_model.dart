import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityCommentModel {
  String id;
  String postId;
  String userId;
  String userName;
  String? userAvatarUrl;
  String message;
  String? parentCommentId; // For nested replies (null if top-level comment)
  int likes;
  int replies;
  List<String> likedBy;
  DateTime createdAt;
  DateTime? updatedAt;

  CommunityCommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.message,
    this.parentCommentId,
    this.likes = 0,
    this.replies = 0,
    List<String>? likedBy,
    DateTime? createdAt,
    this.updatedAt,
  }) : likedBy = likedBy ?? [],
       createdAt = createdAt ?? DateTime.now();

  // Check if a user has liked this comment
  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }

  // Get time ago string
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Get avatar color based on user name
  int getAvatarColorValue() {
    final hash = userName.hashCode;
    final colors = [
      0xFF2196F3, // Blue
      0xFFE91E63, // Pink
      0xFF4CAF50, // Green
      0xFFFF9800, // Orange
      0xFF9C27B0, // Purple
      0xFF00BCD4, // Cyan
      0xFFFF5722, // Deep Orange
      0xFF795548, // Brown
    ];
    return colors[hash.abs() % colors.length];
  }

  // Check if this is a reply (has a parent comment)
  bool get isReply => parentCommentId != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'message': message,
      'parentCommentId': parentCommentId,
      'likes': likes,
      'replies': replies,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory CommunityCommentModel.fromJson(Map<String, dynamic> json) {
    return CommunityCommentModel(
      id: json['id'] as String? ?? '',
      postId: json['postId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatarUrl: json['userAvatarUrl'] as String?,
      message: json['message'] as String,
      parentCommentId: json['parentCommentId'] as String?,
      likes: json['likes'] as int? ?? 0,
      replies: json['replies'] as int? ?? 0,
      likedBy: json['likedBy'] != null
          ? List<String>.from(json['likedBy'] as List)
          : [],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory CommunityCommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityCommentModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }
}

