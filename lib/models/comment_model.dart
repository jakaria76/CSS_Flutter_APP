import 'package:flutter/foundation.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String commentText;
  final DateTime createdAt;

  // User profile info from profiles table
  final String? userName;
  final String? userImage;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.commentText,
    required this.createdAt,
    this.userName,
    this.userImage,
  });

  /// ✅ FIXED: Parse DateTime with timezone handling
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    try {
      if (value is String) {
        final parsed = DateTime.parse(value);
        return parsed.toLocal(); // ✅ UTC → Local
      }
      if (value is DateTime) {
        return value.toLocal();
      }
      return DateTime.now();
    } catch (e) {
      debugPrint('❌ DateTime parse error: $value - $e');
      return DateTime.now();
    }
  }

  factory Comment.fromMap(Map<String, dynamic> json) {
    // Extract user profile info from joined profiles table
    String? userName;
    String? userImage;

    if (json['profiles'] != null && json['profiles'] is Map) {
      final profile = json['profiles'] as Map<String, dynamic>;
      userName = profile['full_name'] as String?;
      userImage = profile['profile_image_url'] as String?;
    }

    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      commentText: json['comment_text'] as String,
      createdAt: _parseDateTime(json['created_at']),
      userName: userName,
      userImage: userImage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'comment_text': commentText,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? commentText,
    DateTime? createdAt,
    String? userName,
    String? userImage,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      commentText: commentText ?? this.commentText,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
    );
  }

  /// ✅ Get display name (fallback to "User" if null)
  String getDisplayName() {
    if (userName != null && userName!.isNotEmpty) {
      return userName!;
    }
    return 'User';
  }

  /// ✅ Check if user has profile image
  bool hasProfileImage() {
    return userImage != null && userImage!.isNotEmpty;
  }

  @override
  String toString() {
    return 'Comment(id: $id, userId: $userId, userName: $userName, text: ${commentText.length > 20 ? commentText.substring(0, 20) + "..." : commentText})';
  }
}