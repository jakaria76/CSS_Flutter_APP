class ConstitutionFile {
  final String id;
  final String name;
  final String pdfUrl;
  final DateTime uploadedAt;

  ConstitutionFile({
    required this.id,
    required this.name,
    required this.pdfUrl,
    required this.uploadedAt,
  });

  factory ConstitutionFile.fromMap(Map<String, dynamic> map) {
    return ConstitutionFile(
      id:         map['id']?.toString() ?? '',
      name:       map['name'] as String? ?? '',
      pdfUrl:     map['pdf_url'] as String? ?? '',
      uploadedAt: map['uploaded_at'] != null
          ? DateTime.parse(map['uploaded_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name'       : name,
    'pdf_url'    : pdfUrl,
    'uploaded_at': uploadedAt.toIso8601String(),
  };
}