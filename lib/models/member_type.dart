/// Member type constants — Supabase এর enum values এর সাথে exact match করতে হবে।
/// UI label এবং DB value আলাদা রাখা হয়েছে।
class MemberType {
  MemberType._();

  static const String presentCommittee  = 'present_committee';
  static const String previousCommittee = 'previous_committee';
  static const String advisor           = 'advisor';

  static const List<String> all = [
    presentCommittee,
    previousCommittee,
    advisor,
  ];

  /// Dropdown এ দেখানোর জন্য বাংলা লেবেল
  static String label(String? value) {
    switch (value) {
      case presentCommittee:  return 'বর্তমান কমিটি সদস্য';
      case previousCommittee: return 'প্রাক্তন কমিটি সদস্য';
      case advisor:           return 'উপদেষ্টা (Advisor)';
      default:                return 'অজানা';
    }
  }

  /// Profile page এ badge এ দেখাবে (ছোট)
  static String shortLabel(String? value) {
    switch (value) {
      case presentCommittee:  return 'বর্তমান কমিটি';
      case previousCommittee: return 'প্রাক্তন কমিটি';
      case advisor:           return 'উপদেষ্টা';
      default:                return '';
    }
  }

  static bool isAdvisor(String? value)   => value == advisor;
  static bool isPresent(String? value)   => value == presentCommittee;
  static bool isPrevious(String? value)  => value == previousCommittee;
  static bool isCommittee(String? value) =>
      value == presentCommittee || value == previousCommittee;
}