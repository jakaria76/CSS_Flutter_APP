class CommitteeMember {
  final String id;
  final String fullName;
  final String position;
  final String? imagePath;
  final String category;

  CommitteeMember({
    required this.id,
    required this.fullName,
    required this.position,
    this.imagePath,
    required this.category,
  });
}