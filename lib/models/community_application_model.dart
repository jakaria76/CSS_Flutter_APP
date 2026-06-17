class CommunityApplicationModel {
  final String? id;
  final String? userId;

  final String fullName;
  final String fatherName;
  final String motherName;
  final String bloodGroup;
  final String photoUrl;
  final String reasonToJoin;

  final String village;
  final String upazila;
  final String district;

  final String? eduPrimary;
  final String? eduSecondary;
  final String? eduHigherSecondary;
  final String? eduGraduate;

  final String mobileNumber;
  final String? facebookLink;

  final String paymentNumber;
  final String transactionId;
  final String paymentScreenshotUrl;
  final num paymentAmount;

  final String? email;

  final String status; // pending | approved | rejected
  final String? adminNote;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  CommunityApplicationModel({
    this.id,
    this.userId,
    required this.fullName,
    required this.fatherName,
    required this.motherName,
    required this.bloodGroup,
    required this.photoUrl,
    required this.reasonToJoin,
    required this.village,
    required this.upazila,
    required this.district,
    this.eduPrimary,
    this.eduSecondary,
    this.eduHigherSecondary,
    this.eduGraduate,
    required this.mobileNumber,
    this.facebookLink,
    required this.paymentNumber,
    required this.transactionId,
    required this.paymentScreenshotUrl,
    this.paymentAmount = 100,
    this.email,
    this.status = 'pending',
    this.adminNote,
    this.createdAt,
    this.reviewedAt,
  });

  factory CommunityApplicationModel.fromMap(Map<String, dynamic> map) {
    return CommunityApplicationModel(
      id:                    map['id']?.toString(),
      userId:                map['user_id']?.toString(),
      fullName:              map['full_name'] ?? '',
      fatherName:            map['father_name'] ?? '',
      motherName:            map['mother_name'] ?? '',
      bloodGroup:            map['blood_group'] ?? '',
      photoUrl:              map['photo_url'] ?? '',
      reasonToJoin:          map['reason_to_join'] ?? '',
      village:               map['village'] ?? '',
      upazila:               map['upazila'] ?? '',
      district:              map['district'] ?? '',
      eduPrimary:            map['edu_primary'],
      eduSecondary:          map['edu_secondary'],
      eduHigherSecondary:    map['edu_higher_secondary'],
      eduGraduate:           map['edu_graduate'],
      mobileNumber:          map['mobile_number'] ?? '',
      facebookLink:          map['facebook_link'],
      paymentNumber:         map['payment_number'] ?? '',
      transactionId:         map['transaction_id'] ?? '',
      paymentScreenshotUrl:  map['payment_screenshot_url'] ?? '',
      paymentAmount:         map['payment_amount'] ?? 100,
      email:                 map['email'],
      status:                map['status'] ?? 'pending',
      adminNote:             map['admin_note'],
      createdAt:             map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
      reviewedAt:            map['reviewed_at'] != null
          ? DateTime.tryParse(map['reviewed_at'])
          : null,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id':                userId,
      'full_name':              fullName,
      'father_name':            fatherName,
      'mother_name':            motherName,
      'blood_group':            bloodGroup,
      'photo_url':               photoUrl,
      'reason_to_join':         reasonToJoin,
      'village':                village,
      'upazila':                upazila,
      'district':               district,
      'edu_primary':            eduPrimary,
      'edu_secondary':          eduSecondary,
      'edu_higher_secondary':   eduHigherSecondary,
      'edu_graduate':           eduGraduate,
      'mobile_number':          mobileNumber,
      'facebook_link':          facebookLink,
      'payment_number':         paymentNumber,
      'transaction_id':         transactionId,
      'payment_screenshot_url': paymentScreenshotUrl,
      'payment_amount':         paymentAmount,
      'email':                  email,
      'status':                 status,
    };
  }

  /// CSV row হিসেবে export করার জন্য (অ্যাডমিন)
  List<String> toCsvRow() {
    return [
      id ?? '',
      fullName,
      fatherName,
      motherName,
      bloodGroup,
      reasonToJoin,
      village,
      upazila,
      district,
      eduPrimary ?? '',
      eduSecondary ?? '',
      eduHigherSecondary ?? '',
      eduGraduate ?? '',
      mobileNumber,
      facebookLink ?? '',
      paymentNumber,
      transactionId,
      paymentAmount.toString(),
      email ?? '',
      status,
      photoUrl,
      paymentScreenshotUrl,
      createdAt?.toIso8601String() ?? '',
    ];
  }

  static List<String> csvHeaders() => [
    'ID',
    'নাম',
    'পিতার নাম',
    'মাতার নাম',
    'ব্লাড গ্রুপ',
    'যুক্ত হওয়ার কারণ',
    'গ্রাম',
    'উপজেলা',
    'জেলা',
    'প্রাথমিক',
    'মাধ্যমিক',
    'উচ্চ মাধ্যমিক',
    'স্নাতক',
    'মোবাইল',
    'ফেইসবুক',
    'পেমেন্ট নম্বর',
    'ট্রানজেকশন আইডি',
    'টাকার পরিমাণ',
    'ইমেইল',
    'স্ট্যাটাস',
    'ছবি URL',
    'পেমেন্ট স্ক্রিনশট URL',
    'তৈরির তারিখ',
  ];
}