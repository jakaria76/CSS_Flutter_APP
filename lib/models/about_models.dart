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
      description: json['description'] as String,
      foundedYear: json['founded_year'] as int,
      focus: json['focus'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
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
      text: json['text'] as String,
      orderIndex: json['order_index'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
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
      title: json['title'] as String,
      icon: json['icon'] as String,
      orderIndex: json['order_index'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
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

/// 🌟 Base Person Model for Advisors, Presidents, and Leadership
/// Common fields to avoid code duplication
class PersonBase {
  final int id;
  final String name;
  final String role; // Acts as 'role' for Advisors/Leaders and 'term' for Presidents
  final String? imageUrl;
  final String? message; // What the person said (Quotes)
  final String? bio;     // Short biography
  final Map<String, dynamic>? socialLinks; // Facebook, LinkedIn, etc.
  final int orderIndex;
  final DateTime createdAt;

  PersonBase({
    required this.id,
    required this.name,
    required this.role,
    this.imageUrl,
    this.message,
    this.bio,
    this.socialLinks,
    required this.orderIndex,
    required this.createdAt,
  });

  // RoleKey determines if we should look for 'role' or 'term' in the JSON
  factory PersonBase.fromJson(Map<String, dynamic> json, {required String roleKey}) {
    return PersonBase(
      id: json['id'] as int,
      name: json['name'] as String,
      role: json[roleKey] as String,
      imageUrl: json['image_url'] as String?,
      message: json['message'] as String?,
      bio: json['bio'] as String?,
      socialLinks: json['social_links'] as Map<String, dynamic>?,
      orderIndex: json['order_index'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// 4️⃣ Advisor Model (Extends PersonBase logic)
class Advisor extends PersonBase {
  Advisor({
    required super.id,
    required super.name,
    required super.role,
    super.imageUrl,
    super.message,
    super.bio,
    super.socialLinks,
    required super.orderIndex,
    required super.createdAt,
  });

  factory Advisor.fromJson(Map<String, dynamic> json) {
    return Advisor(
      id: json['id'] as int,
      name: json['name'] as String,
      role: json['role'] as String,
      imageUrl: json['image_url'] as String?,
      message: json['message'] as String?,
      bio: json['bio'] as String?,
      socialLinks: json['social_links'] as Map<String, dynamic>?,
      orderIndex: json['order_index'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// 5️⃣ Previous President Model
class PreviousPresident extends PersonBase {
  PreviousPresident({
    required super.id,
    required super.name,
    required super.role, // role is the 'term'
    super.imageUrl,
    super.message,
    super.bio,
    super.socialLinks,
    required super.orderIndex,
    required super.createdAt,
  });

  factory PreviousPresident.fromJson(Map<String, dynamic> json) {
    return PreviousPresident(
      id: json['id'] as int,
      name: json['name'] as String,
      role: json['term'] as String, // Mapping 'term' to 'role'
      imageUrl: json['image_url'] as String?,
      message: json['message'] as String?,
      bio: json['bio'] as String?,
      socialLinks: json['social_links'] as Map<String, dynamic>?,
      orderIndex: json['order_index'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// 6️⃣ Leadership Model
class Leadership extends PersonBase {
  Leadership({
    required super.id,
    required super.name,
    required super.role,
    super.imageUrl,
    super.message,
    super.bio,
    super.socialLinks,
    required super.orderIndex,
    required super.createdAt,
  });

  factory Leadership.fromJson(Map<String, dynamic> json) {
    return Leadership(
      id: json['id'] as int,
      name: json['name'] as String,
      role: json['role'] as String,
      imageUrl: json['image_url'] as String?,
      message: json['message'] as String?,
      bio: json['bio'] as String?,
      socialLinks: json['social_links'] as Map<String, dynamic>?,
      orderIndex: json['order_index'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// 7️⃣ Story Timeline Model
class StoryEvent {
  final int id;
  final DateTime eventDate;
  final String description;
  final int orderIndex;
  final DateTime createdAt;

  StoryEvent({
    required this.id,
    required this.eventDate,
    required this.description,
    required this.orderIndex,
    required this.createdAt,
  });

  factory StoryEvent.fromJson(Map<String, dynamic> json) {
    return StoryEvent(
      id: json['id'] as int,
      eventDate: DateTime.parse(json['event_date'] as String),
      description: json['description'] as String,
      orderIndex: json['order_index'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// 8️⃣ Contact Info Model
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
      email: json['email'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      facebook: json['facebook'] as String?,
      website: json['website'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}