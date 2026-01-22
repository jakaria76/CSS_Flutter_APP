class Notice {
  final String id;
  final String title;
  final DateTime publishDate;
  final String? pdfUrl;

  Notice({
    required this.id,
    required this.title,
    required this.publishDate,
    this.pdfUrl,
  });

  factory Notice.fromMap(Map<String, dynamic> map) {
    return Notice(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      publishDate: DateTime.parse(map['publish_date']),
      pdfUrl: map['pdf_url'],
    );
  }
}
