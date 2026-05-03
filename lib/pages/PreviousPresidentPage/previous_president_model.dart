class PreviousPresident {
  final String id;
  final String fullName;
  final String? fullNameBn;
  final String? imagePath;
  final int? tenureFrom;
  final int? tenureTo;
  final String? previousPosition;
  final String? note;

  PreviousPresident({
    required this.id,
    required this.fullName,
    this.fullNameBn,
    this.imagePath,
    this.tenureFrom,
    this.tenureTo,
    this.previousPosition,
    this.note,
  });

  String get tenureLabel {
    if (tenureFrom != null && tenureTo != null) return '$tenureFrom – $tenureTo';
    if (tenureFrom != null) return '$tenureFrom –';
    if (tenureTo != null) return '– $tenureTo';
    return 'Tenure N/A';
  }
}