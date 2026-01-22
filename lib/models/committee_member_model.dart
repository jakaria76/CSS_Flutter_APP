class CommitteeMember {
  final String id; // int থেকে String করুন (UUID এর জন্য)
  final String fullName;
  final String position;
  final String? imagePath; // nullable করুন
  final String category; // Top, Executive, Members

  CommitteeMember({
    required this.id,
    required this.fullName,
    required this.position,
    this.imagePath, // required সরিয়ে দিন
    required this.category,
  });
}