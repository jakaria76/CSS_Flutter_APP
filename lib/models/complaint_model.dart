import 'package:flutter/foundation.dart';

class Complaint {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String status;
  final String? imageUrl;
  final String? adminReply;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // User info from profiles join
  final String? userFullName;
  final String? userProfileImageUrl;

  Complaint({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.imageUrl,
    this.adminReply,
    required this.createdAt,
    this.updatedAt,
    this.userFullName,
    this.userProfileImageUrl,
  });

  /// ✅ FIXED: Proper DateTime parsing with timezone handling
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    try {
      if (value is String) {
        // Parse the string and convert to local time
        final parsed = DateTime.parse(value);
        return parsed.toLocal(); // ✅ Convert UTC to local time
      }
      if (value is DateTime) {
        return value.toLocal();
      }
      return DateTime.now();
    } catch (e) {
      debugPrint('❌ Error parsing datetime: $value - $e');
      return DateTime.now();
    }
  }

  factory Complaint.fromMap(Map<String, dynamic> map) {
    return Complaint(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'feedback',
      status: map['status'] ?? 'pending',
      imageUrl: map['image_url'],
      adminReply: map['admin_reply'],
      createdAt: _parseDateTime(map['created_at']),  // ✅ Use safe parser
      updatedAt: map['updated_at'] != null
          ? _parseDateTime(map['updated_at'])
          : null,
      userFullName: map['user_full_name'],
      userProfileImageUrl: map['user_profile_image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'image_url': imageUrl,
      'admin_reply': adminReply,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }

  String getCategoryBangla() {
    switch (category) {
      case 'complaint':
        return 'অভিযোগ';
      case 'suggestion':
        return 'পরামর্শ';
      case 'feedback':
        return 'মতামত';
      default:
        return 'অন্যান্য';
    }
  }

  String getStatusBangla() {
    switch (status) {
      case 'pending':
        return 'বিবেচনাধীন';
      case 'reviewed':
        return 'পর্যালোচিত';
      case 'resolved':
        return 'সমাধানকৃত';
      default:
        return 'অজানা';
    }
  }
}

enum ComplaintCategory {
  complaint('complaint', 'অভিযোগ'),
  suggestion('suggestion', 'পরামর্শ'),
  feedback('feedback', 'মতামত');

  final String englishName;
  final String banglaName;

  const ComplaintCategory(this.englishName, this.banglaName);
}