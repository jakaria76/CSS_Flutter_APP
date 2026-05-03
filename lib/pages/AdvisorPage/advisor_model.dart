class Advisor {
  final String id;
  final String fullName;
  final String? fullNameBn;
  final String? imagePath;
  final String? occupation;
  final String? institution;
  final String? designation;
  final String? expertise;
  final String? note;

  Advisor({
    required this.id,
    required this.fullName,
    this.fullNameBn,
    this.imagePath,
    this.occupation,
    this.institution,
    this.designation,
    this.expertise,
    this.note,
  });

  String get badgeLabel {
    if (designation != null && designation!.isNotEmpty) return designation!;
    if (occupation != null && occupation!.isNotEmpty) return occupation!;
    return 'Advisor';
  }

  String get institutionLabel =>
      institution != null && institution!.isNotEmpty ? institution! : '';
}