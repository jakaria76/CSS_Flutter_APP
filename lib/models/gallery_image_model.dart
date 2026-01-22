// ============================================
// FILE 1: lib/models/gallery_image_model.dart
// ============================================

class GalleryImage {
  final String id;
  final String? title;
  final String category;
  final String imageUrl;
  final String? thumbnailUrl;
  final String? uploadedBy;
  final DateTime createdAt;

  GalleryImage({
    required this.id,
    this.title,
    required this.category,
    required this.imageUrl,
    this.thumbnailUrl,
    this.uploadedBy,
    required this.createdAt,
  });

  factory GalleryImage.fromMap(Map<String, dynamic> map) {
    return GalleryImage(
      id: map['id'] as String,
      title: map['title'] as String?,
      category: map['category'] as String,
      imageUrl: map['image_url'] as String,
      thumbnailUrl: map['thumbnail_url'] as String?,
      uploadedBy: map['uploaded_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}