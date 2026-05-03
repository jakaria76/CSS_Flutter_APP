// lib/models/about_models.dart

/// 1️⃣ Organization Overview Model
class AboutOverview {
  final int id;
  final String description;
  final int foundedYear;
  final String focus;
  final DateTime createdAt;

  AboutOverview({
    required this.id,
    required this.description,
    required this.foundedYear,
    required this.focus,
    required this.createdAt,
  });

  factory AboutOverview.fromJson(Map<String, dynamic> json) {
    return AboutOverview(
      id: json['id'] as int,
      description: (json['description'] as String?) ?? '',
      foundedYear: (json['founded_year'] as int?) ?? 2022,
      focus: (json['focus'] as String?) ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'founded_year': foundedYear,
      'focus': focus,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// 2️⃣ Mission Point Model
class MissionPoint {
  final int id;
  final String text;
  final int orderIndex;
  final DateTime createdAt;

  MissionPoint({
    required this.id,
    required this.text,
    required this.orderIndex,
    required this.createdAt,
  });

  factory MissionPoint.fromJson(Map<String, dynamic> json) {
    return MissionPoint(
      id: json['id'] as int,
      text: (json['text'] as String?) ?? '',
      orderIndex: (json['order_index'] as int?) ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// 3️⃣ Activity Model
class Activity {
  final int id;
  final String title;
  final String icon;
  final int orderIndex;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.title,
    required this.icon,
    required this.orderIndex,
    required this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      icon: (json['icon'] as String?) ?? 'bolt',
      orderIndex: (json['order_index'] as int?) ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// 4️⃣ Story Timeline Model
class StoryEvent {
  final int id;
  final DateTime eventDate;
  final String description;
  final int? orderIndex;
  final DateTime createdAt;

  StoryEvent({
    required this.id,
    required this.eventDate,
    required this.description,
    this.orderIndex,
    required this.createdAt,
  });

  factory StoryEvent.fromJson(Map<String, dynamic> json) {
    return StoryEvent(
      id: json['id'] as int,
      eventDate: json['event_date'] != null
          ? DateTime.parse(json['event_date'] as String)
          : DateTime.now(),
      description: (json['description'] as String?) ?? '',
      orderIndex: json['order_index'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

/// 5️⃣ Contact Info Model
class ContactInfo {
  final int id;
  final String email;
  final String phone;
  final String address;
  final String? facebook;
  final String? website;
  final DateTime createdAt;

  ContactInfo({
    required this.id,
    required this.email,
    required this.phone,
    required this.address,
    this.facebook,
    this.website,
    required this.createdAt,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      id: json['id'] as int,
      email: (json['email'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      facebook: json['facebook'] as String?,
      website: json['website'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}