class Video {
  final int id;
  final String title;
  final String youtubeUrl;
  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;
  final String? createdBy;

  Video({
    required this.id,
    required this.title,
    required this.youtubeUrl,
    this.sortOrder = 0,
    this.isActive = true,
    this.createdAt,
    this.createdBy,
  });

  factory Video.fromMap(Map<String, dynamic> map) {
    return Video(
      id: map['id'] as int,
      title: map['title'] as String,
      youtubeUrl: map['youtube_url'] as String,
      sortOrder: map['sort_order'] as int? ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      createdBy: map['created_by'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'youtube_url': youtubeUrl,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  Video copyWith({
    int? id,
    String? title,
    String? youtubeUrl,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Video(
      id: id ?? this.id,
      title: title ?? this.title,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}