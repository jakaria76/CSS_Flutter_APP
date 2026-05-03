import 'member_type.dart';

class ProfileModel {
  // ================= BASIC =================
  final String id;

  // ================= PROFILE IMAGE =================
  String? profileImageUrl;

  String? fullName;
  String? fullNameBn;

  /// Values: 'present_committee' | 'previous_committee' | 'advisor'
  /// Use MemberType.isAdvisor() / isCommittee() / isPrevious() to branch logic.
  String? memberType;

  String? committeePosition;
  DateTime? memberSince;

  // ================= PERSONAL =================
  String? gender;
  DateTime? dateOfBirth;

  // ================= CONTACT =================
  String? alternativeMobile;
  String? presentAddress;
  String? permanentAddress;
  String? district;
  String? upazila;
  String? facebookLink;
  String? whatsappNumber;
  String? email; // advisor এর জন্য বিশেষভাবে দরকার; committee ও রাখতে পারে

  // ================= BLOOD / DONATION =================
  String? bloodGroup;
  DateTime? lastDonationDate;
  DateTime? nextAvailableDonationDate;
  String? donationEligibility;
  int? totalDonationCount;
  String? preferredDonationLocation;

  // ================= EDUCATION – SCHOOL =================
  String? schoolName;
  String? schoolGroup;
  int? schoolPassingYear;

  // ================= EDUCATION – COLLEGE =================
  String? collegeName;
  String? collegeGroup;
  int? collegePassingYear;

  // ================= EDUCATION – UNIVERSITY =================
  String? universityName;
  String? department;
  String? studentId;
  int? currentYear;
  int? currentSemester;

  // ================= BIO =================
  String? shortBio;
  String? whyJoined;
  String? futureGoals;
  String? hobbies;

  // ================= SOCIAL =================
  String? facebook;
  String? portfolioWebsite;

  // ================= PREVIOUS COMMITTEE (only when memberType == 'previous_committee') =====
  /// কোন position এ ছিলেন — committee position এর same list থেকে
  String? previousPosition;
  /// কত সাল থেকে — যেমন 2021
  int? tenureFrom;
  /// কত সাল পর্যন্ত — যেমন 2022
  int? tenureTo;

  // ================= NOTES — প্রতিটি member type এর জন্য আলাদা নোট ======================
  /// বর্তমান কমিটি সদস্য সম্পর্কে বিশেষ নোট/মন্তব্য
  String? presentCommitteeNote;
  /// প্রাক্তন কমিটি সদস্য সম্পর্কে বিশেষ নোট/মন্তব্য
  String? previousCommitteeNote;

  // ================= ADVISOR (only when memberType == 'advisor') ==========================
  /// পেশা — যেমন "Assistant Professor", "Software Engineer", "Doctor"
  String? occupation;
  /// প্রতিষ্ঠান — যেমন "BUET", "Dhaka Medical College"
  String? institution;
  /// পদবি/title — যেমন "PhD", "MBBS", "Senior Engineer"
  String? designation;
  /// বিশেষজ্ঞতার ক্ষেত্র — যেমন "Civil Engineering, Project Management"
  String? expertise;
  /// কেন/কীভাবে advisor হলেন বা কী বিষয়ে পরামর্শ দেন
  String? advisorNote;
  /// উপদেষ্টা ক্যাটাগরি — যেমন "Chief", "Academic", "Legal", "Medical" (EditProfilePage এর এরর ফিক্স)
  String? advisorType;

  // ================= SYSTEM =================
  String? accountStatus;
  DateTime? lastUpdatedDate;
  String? updatedBy;

  // ================= LOCATION =================
  double? latitude;
  double? longitude;
  String? locationDms;

  ProfileModel({
    required this.id,
    this.profileImageUrl,
    this.fullName,
    this.fullNameBn,
    this.memberType,
    this.committeePosition,
    this.memberSince,
    this.gender,
    this.dateOfBirth,
    this.alternativeMobile,
    this.presentAddress,
    this.permanentAddress,
    this.district,
    this.upazila,
    this.facebookLink,
    this.whatsappNumber,
    this.email,
    this.bloodGroup,
    this.lastDonationDate,
    this.nextAvailableDonationDate,
    this.donationEligibility,
    this.totalDonationCount,
    this.preferredDonationLocation,
    this.schoolName,
    this.schoolGroup,
    this.schoolPassingYear,
    this.collegeName,
    this.collegeGroup,
    this.collegePassingYear,
    this.universityName,
    this.department,
    this.studentId,
    this.currentYear,
    this.currentSemester,
    this.shortBio,
    this.whyJoined,
    this.futureGoals,
    this.hobbies,
    this.facebook,
    this.portfolioWebsite,
    // previous committee
    this.previousPosition,
    this.tenureFrom,
    this.tenureTo,
    // notes
    this.presentCommitteeNote,
    this.previousCommitteeNote,
    // advisor
    this.occupation,
    this.institution,
    this.designation,
    this.expertise,
    this.advisorNote,
    this.advisorType, // ← Added here
    // system
    this.accountStatus,
    this.lastUpdatedDate,
    this.updatedBy,
    // location
    this.latitude,
    this.longitude,
    this.locationDms,
  });

  // ── Convenience getters ──────────────────────────────────────────────────

  bool get isAdvisor        => MemberType.isAdvisor(memberType);
  bool get isCommittee      => MemberType.isCommittee(memberType);
  bool get isPreviousMember => MemberType.isPrevious(memberType);

  /// "2021 – 2022" format, previous committee card এ দেখাবে
  String get tenureLabel {
    if (tenureFrom == null && tenureTo == null) return '';
    final from = tenureFrom?.toString() ?? '?';
    final to   = tenureTo?.toString()   ?? '?';
    return '$from – $to';
  }

  // ── Safe parsers ─────────────────────────────────────────────────────────

  static String?   _asString(dynamic v) => v == null ? null : v.toString();
  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    try { return DateTime.parse(v.toString()); } catch (_) { return null; }
  }
  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  // ── fromMap ──────────────────────────────────────────────────────────────

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: _asString(map['id']) ?? '',

      profileImageUrl: _asString(map['profile_image_url']),

      fullName:          _asString(map['full_name']),
      fullNameBn:        _asString(map['full_name_bn']),
      memberType:        _asString(map['member_type']),
      committeePosition: _asString(map['committee_position']),
      memberSince:       _asDate(map['member_since']),

      gender:      _asString(map['gender']),
      dateOfBirth: _asDate(map['date_of_birth']),

      alternativeMobile: _asString(map['alternative_mobile']),
      presentAddress:    _asString(map['present_address']),
      permanentAddress:  _asString(map['permanent_address']),
      district:          _asString(map['district']),
      upazila:           _asString(map['upazila']),
      facebookLink:      _asString(map['facebook_link']),
      whatsappNumber:    _asString(map['whatsapp_number']),
      email:             _asString(map['email']),

      bloodGroup:                  _asString(map['blood_group']),
      lastDonationDate:            _asDate(map['last_donation_date']),
      nextAvailableDonationDate:   _asDate(map['next_available_donation_date']),
      donationEligibility:         _asString(map['donation_eligibility']),
      totalDonationCount:          _asInt(map['total_donation_count']),
      preferredDonationLocation:   _asString(map['preferred_donation_location']),

      schoolName:        _asString(map['school_name']),
      schoolGroup:       _asString(map['school_group']),
      schoolPassingYear: _asInt(map['school_passing_year']),

      collegeName:        _asString(map['college_name']),
      collegeGroup:       _asString(map['college_group']),
      collegePassingYear: _asInt(map['college_passing_year']),

      universityName:  _asString(map['university_name']),
      department:      _asString(map['department']),
      studentId:       _asString(map['student_id']),
      currentYear:     _asInt(map['current_year']),
      currentSemester: _asInt(map['current_semester']),

      shortBio:    _asString(map['short_bio']),
      whyJoined:   _asString(map['why_joined']),
      futureGoals: _asString(map['future_goals']),
      hobbies:     _asString(map['hobbies']),

      facebook:         _asString(map['facebook']),
      portfolioWebsite: _asString(map['portfolio_website']),

      // previous committee
      previousPosition: _asString(map['previous_position']),
      tenureFrom:       _asInt(map['tenure_from']),
      tenureTo:         _asInt(map['tenure_to']),

      // notes
      presentCommitteeNote:  _asString(map['present_committee_note']),
      previousCommitteeNote: _asString(map['previous_committee_note']),

      // advisor
      occupation:  _asString(map['occupation']),
      institution: _asString(map['institution']),
      designation: _asString(map['designation']),
      expertise:   _asString(map['expertise']),
      advisorNote: _asString(map['advisor_note']),
      advisorType: _asString(map['advisor_type']), // ← Added here

      // system
      accountStatus:   _asString(map['account_status']),
      lastUpdatedDate: _asDate(map['updated_at']),
      updatedBy:       _asString(map['updated_by']),

      // location
      latitude:    _asDouble(map['latitude']),
      longitude:   _asDouble(map['longitude']),
      locationDms: _asString(map['location_dms']),
    );
  }

  // ── toMap ────────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,

      'profile_image_url': profileImageUrl,

      'full_name':          fullName,
      'full_name_bn':       fullNameBn,
      'member_type':        memberType,
      'committee_position': committeePosition,
      'member_since':       memberSince?.toIso8601String(),
      'gender':             gender,
      'date_of_birth':      dateOfBirth?.toIso8601String(),

      'alternative_mobile': alternativeMobile,
      'present_address':    presentAddress,
      'permanent_address':  permanentAddress,
      'district':           district,
      'upazila':            upazila,
      'facebook_link':      facebookLink,
      'whatsapp_number':    whatsappNumber,
      'email':              email,

      'blood_group':                  bloodGroup,
      'last_donation_date':           lastDonationDate?.toIso8601String(),
      'next_available_donation_date': nextAvailableDonationDate?.toIso8601String(),
      'donation_eligibility':         donationEligibility,
      'total_donation_count':         totalDonationCount,
      'preferred_donation_location':  preferredDonationLocation,

      'school_name':         schoolName,
      'school_group':        schoolGroup,
      'school_passing_year': schoolPassingYear,

      'college_name':         collegeName,
      'college_group':        collegeGroup,
      'college_passing_year': collegePassingYear,

      'university_name':  universityName,
      'department':       department,
      'student_id':       studentId,
      'current_year':     currentYear,
      'current_semester': currentSemester,

      'short_bio':    shortBio,
      'why_joined':   whyJoined,
      'future_goals': futureGoals,
      'hobbies':      hobbies,

      'facebook':          facebook,
      'portfolio_website': portfolioWebsite,

      // previous committee
      'previous_position': previousPosition,
      'tenure_from':       tenureFrom,
      'tenure_to':         tenureTo,

      // notes
      'present_committee_note':  presentCommitteeNote,
      'previous_committee_note': previousCommitteeNote,

      // advisor
      'occupation':   occupation,
      'institution':  institution,
      'designation':  designation,
      'expertise':    expertise,
      'advisor_note': advisorNote,
      'advisor_type': advisorType, // ← Added here

      // location
      'latitude':     latitude,
      'longitude':    longitude,
      'location_dms': locationDms,
    };
  }
}