import 'package:flutter/foundation.dart';

class Post {
  final String id;
  final String adminId;
  final String caption;
  final DateTime createdAt;
  final List<String> images;
  final int commentCount;

  Post({
    required this.id,
    required this.adminId,
    this.caption = '',
    required this.createdAt,
    this.images = const [],
    this.commentCount = 0,
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

  factory Post.fromMap(Map<String, dynamic> json) {
    // Extract images from post_images relation
    List<String> imageUrls = [];
    if (json['post_images'] != null && json['post_images'] is List) {
      final images = json['post_images'] as List;
      imageUrls = images
          .map((img) => img['image_url'] as String)
          .toList()
        ..sort((a, b) {
          final imgA = images.firstWhere((i) => i['image_url'] == a);
          final imgB = images.firstWhere((i) => i['image_url'] == b);
          final orderA = imgA['display_order'] ?? 0;
          final orderB = imgB['display_order'] ?? 0;
          return orderA.compareTo(orderB);
        });
    }

    // Extract comment count
    int commentCount = 0;
    if (json['comment_count'] != null) {
      commentCount = json['comment_count'] as int;
    } else if (json['comments'] != null && json['comments'] is List) {
      final comments = json['comments'] as List;
      if (comments.isNotEmpty && comments[0] is Map) {
        commentCount = comments[0]['count'] ?? 0;
      }
    }

    return Post(
      id: json['id'] as String,
      adminId: json['admin_id'] as String,
      caption: json['caption'] as String? ?? '',
      createdAt: _parseDateTime(json['created_at']),
      images: imageUrls,
      commentCount: commentCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'admin_id': adminId,
      'caption': caption.isEmpty ? null : caption,
      'created_at': createdAt.toUtc().toIso8601String(),
      'comment_count': commentCount,
    };
  }

  Post copyWith({
    String? id,
    String? adminId,
    String? caption,
    DateTime? createdAt,
    List<String>? images,
    int? commentCount,
  }) {
    return Post(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      images: images ?? this.images,
      commentCount: commentCount ?? this.commentCount,
    );
  }

  @override
  String toString() {
    return 'Post(id: $id, caption: $caption, images: ${images.length}, comments: $commentCount)';
  }
}