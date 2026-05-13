import 'package:flutter/material.dart';
import '../../models/profile_model.dart';
import '../../models/member_type.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'profile_sections.dart';
import 'profile_cards.dart';

bool hasContent(String? s) =>
    s != null && s.trim().isNotEmpty && s != 'null';

String fmtDate(DateTime? d) => d == null
    ? ''
    : '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

// ── Present Body ──────────────────────────────────────────────────────────────

class PresentBody extends StatelessWidget {
  final ProfileModel p;
  final bool isDark;
  final Color textColor;
  final Color subTextColor;
  final Color cardColor;
  final Color surfaceColor;
  final Color borderColor;
  final bool isSelf;
  final VoidCallback onDelete;

  static const _blue   = Color(0xFF4A90E2);
  static const _orange = Color(0xFFFF8A65);
  static const _red    = Color(0xFFEF5350);
  static const _green  = Color(0xFF4CAF50);
  static const _teal   = Color(0xFF26A69A);
  static const _purple = Color(0xFF9C27B0);

  const PresentBody({
    super.key,
    required this.p,
    required this.isDark,
    required this.textColor,
    required this.subTextColor,
    required this.cardColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.isSelf,
    required this.onDelete,
  });

  ProfileInfoRow _row(IconData icon, String label, String? value) =>
      ProfileInfoRow(
        icon: icon, label: label, value: value,
        textColor: textColor, subTextColor: subTextColor, isDark: isDark,
      );

  @override
  Widget build(BuildContext context) {
    final t = SC.tr;
    return Column(children: [
      // ── Basic Information ─────────────────────────────────────────────────
      ProfileSection(
        title: t('basicInformation'), icon: Icons.person_rounded,
        accent: _blue, cardColor: cardColor,
        borderColor: borderColor, isDark: isDark,
        rows: [
          _row(Icons.badge_outlined,             t('fullNameEN'),        p.fullName),
          _row(Icons.translate_rounded,          t('fullNameBN'),        p.fullNameBn),
          _row(Icons.wc_rounded,                 t('gender'),            p.gender),
          _row(Icons.cake_outlined,              t('dateOfBirth'),       fmtDate(p.dateOfBirth)),
          _row(Icons.verified_user_outlined,     t('memberType'),        MemberType.label(p.memberType)),
          _row(Icons.workspace_premium_outlined, t('committeePosition'), p.committeePosition),
          _row(Icons.calendar_month_outlined,    t('memberSince'),       fmtDate(p.memberSince)),
        ],
      ),

      if (hasContent(p.presentCommitteeNote))
        NoteCard(
          note: p.presentCommitteeNote!, accent: _teal,
          icon: Icons.sticky_note_2_rounded,
          title: t('committeeNote'), textColor: textColor,
        ),

      // ── Contact Details ───────────────────────────────────────────────────
      ProfileSection(
        title: t('contactDetails'), icon: Icons.contacts_rounded,
        accent: _orange, cardColor: cardColor,
        borderColor: borderColor, isDark: isDark,
        rows: [
          _row(Icons.chat_bubble_outline_rounded, t('whatsapp'),          p.whatsappNumber),
          _row(Icons.phone_iphone_rounded,        t('alternativeMobile'), p.alternativeMobile),
          _row(Icons.email_outlined,              t('email'),             p.email),
          _row(Icons.link_rounded,                t('facebookLink'),      p.facebookLink),
          _row(Icons.home_outlined,               t('presentAddress'),    p.presentAddress),
          _row(Icons.location_city_outlined,      t('permanentAddress'),  p.permanentAddress),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _row(Icons.map_outlined,     t('district'), p.district)),
            const SizedBox(width: 10),
            Expanded(child: _row(Icons.explore_outlined, t('upazila'),  p.upazila)),
          ]),
        ],
      ),

      // ── Blood Donation ────────────────────────────────────────────────────
      ProfileSection(
        title: t('bloodDonation'), icon: Icons.favorite_rounded,
        accent: _red, cardColor: cardColor,
        borderColor: borderColor, isDark: isDark,
        rows: [
          _row(Icons.water_drop_rounded,         t('bloodGroup'),        p.bloodGroup),
          _row(Icons.history_rounded,            t('lastDonation'),      fmtDate(p.lastDonationDate)),
          _row(Icons.event_available_rounded,    t('nextAvailable'),     fmtDate(p.nextAvailableDonationDate)),
          _row(Icons.health_and_safety_outlined, t('eligibility'),       p.donationEligibility),
          _row(Icons.pin_drop_outlined,          t('preferredLocation'), p.preferredDonationLocation),
        ],
      ),

      // ── Academic Records ──────────────────────────────────────────────────
      ProfileSection(
        title: t('academicRecords'), icon: Icons.school_rounded,
        accent: _green, cardColor: cardColor,
        borderColor: borderColor, isDark: isDark,
        rows: [
          ProfileSubHeader(text: t('secondary'), isDark: isDark),
          _row(Icons.school_outlined,          t('school'),      p.schoolName),
          _row(Icons.history_edu_rounded,      t('sscGroupYear'),
              '${p.schoolGroup ?? 'N/A'} · ${p.schoolPassingYear ?? ''}'),
          _row(Icons.account_balance_outlined, t('college'),     p.collegeName),
          _row(Icons.history_edu_rounded,      t('hscGroupYear'),
              '${p.collegeGroup ?? 'N/A'} · ${p.collegePassingYear ?? ''}'),
          ProfileSubHeader(text: t('higherEducation'), isDark: isDark),
          _row(Icons.account_balance_rounded, t('university'), p.universityName),
          _row(Icons.category_outlined,       t('department'), p.department),
          _row(Icons.fingerprint_rounded,     t('studentId'),  p.studentId),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _row(Icons.layers_outlined, t('year'),     p.currentYear?.toString())),
            const SizedBox(width: 10),
            Expanded(child: _row(Icons.repeat_rounded,  t('semester'), p.currentSemester?.toString())),
          ]),
        ],
      ),

      // ── Bio & Social ──────────────────────────────────────────────────────
      ProfileSection(
        title: t('bioSocial'), icon: Icons.public_rounded,
        accent: _purple, cardColor: cardColor,
        borderColor: borderColor, isDark: isDark,
        rows: [
          _row(Icons.notes_rounded,           t('shortBio'),    p.shortBio),
          _row(Icons.flag_outlined,           t('whyJoined'),   p.whyJoined),
          _row(Icons.ads_click_rounded,       t('futureGoals'), p.futureGoals),
          _row(Icons.interests_outlined,      t('hobbies'),     p.hobbies),
          _row(Icons.alternate_email_rounded, t('facebook'),    p.facebook),
          _row(Icons.language_rounded,        t('portfolio'),   p.portfolioWebsite),
        ],
      ),

      // ── Location ──────────────────────────────────────────────────────────
      ProfileSection(
        title: t('location'), icon: Icons.location_on_rounded,
        accent: _teal, cardColor: cardColor,
        borderColor: borderColor, isDark: isDark,
        rows: [
          _row(Icons.gps_fixed_rounded,   t('coordinates'),
              '${p.latitude ?? 'N/A'}, ${p.longitude ?? 'N/A'}'),
          _row(Icons.my_location_rounded, t('locationName'), p.locationDms),
        ],
      ),

      if (isSelf) ...[
        const SizedBox(height: 8),
        DangerZone(onDelete: onDelete, subTextColor: subTextColor),
      ],
    ]);
  }
}

// ── Previous Body ─────────────────────────────────────────────────────────────

class PreviousBody extends StatelessWidget {
  final ProfileModel p;
  final bool isDark;
  final Color textColor;
  final Color subTextColor;
  final Color cardColor;
  final Color surfaceColor;
  final Color borderColor;
  final bool isSelf;
  final VoidCallback onDelete;

  static const _blue   = Color(0xFF4A90E2);
  static const _orange = Color(0xFFFF8A65);
  static const _red    = Color(0xFFEF5350);
  static const _green  = Color(0xFF4CAF50);
  static const _purple = Color(0xFF9C27B0);

  const PreviousBody({
    super.key,
    required this.p,
    required this.isDark,
    required this.textColor,
    required this.subTextColor,
    required this.cardColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.isSelf,
    required this.onDelete,
  });

  ProfileInfoRow _row(IconData icon, String label, String? value) =>
      ProfileInfoRow(
        icon: icon, label: label, value: value,
        textColor: textColor, subTextColor: subTextColor, isDark: isDark,
      );

  @override
  Widget build(BuildContext context) {
    final t = SC.tr;
    return Column(children: [
      // ── Tenure Card ───────────────────────────────────────────────────────
      TenureCard(
        previousPosition: p.previousPosition,
        tenureLabel: p.tenureLabel,
        textColor: textColor,
        subTextColor: subTextColor,
      ),
      const SizedBox(height: 20),

      // ── Basic Information ─────────────────────────────────────────────────
      ProfileSection(
        title: t('basicInformation'), icon: Icons.person_rounded,
        accent: _blue, cardColor: cardColor,
        borderColor: borderColor, isDark: isDark,
        rows: [
          _row(Icons.badge_outlined,          t('fullNameEN'),  p.fullName),
          _row(Icons.translate_rounded,       t('fullNameBN'),  p.fullNameBn),
          _row(Icons.wc_rounded,              t('gender'),      p.gender),
          _row(Icons.cake_outlined,           t('dateOfBirth'), fmtDate(p.dateOfBirth)),
          _row(Icons.verified_user_outlined,  t('memberType'),  MemberType.label(p.memberType)),
          _row(Icons.calendar_month_outlined, t('memberSince'), fmtDate(p.memberSince)),
        ],
      ),

      if (hasContent(p.previousCommitteeNote))
        NoteCard(
          note: p.previousCommitteeNote!, accent: _purple,
          icon: Icons.sticky_note_2_rounded,
          title: t('previousMemberNote'), textColor: textColor,
        ),

      // ── Contact Details ───────────────────────────────────────────────────
      ProfileSection(
        title: t('contactDetails'), icon: Icons.contacts_rounded,
        accent: _orange, cardColor: cardColor,
        borderColor: borderColor, isDark: isDark,
        rows: [
          _row(Icons.chat_bubble_outline_rounded, t('whatsapp'),          p.whatsappNumber),
          _row(Icons.phone_iphone_rounded,        t('alternativeMobile'), p.alternativeMobile),
          _row(Icons.email_outlined,              t('email'),             p.email),
          _row(Icons.link_rounded,                t('facebookLink'),      p.facebookLink),
          _row(Icons.home_outlined,               t('presentAddress'),    p.presentAddress),
          _row(Icons.location_city_outlined,      t('permanentAddress'),  p.permanentAddress),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _row(Icons.map_outlined,     t('district'), p.district)),
            const SizedBox(width: 10),
            Expanded(child: _row(Icons.explore_outlined, t('upazila'),  p.upazila)),
          ]),
        ],
      ),

      // ── Blood Donation ────────────────────────────────────────────────────
      ProfileSection(
        title: t('bloodDonation'), icon: Icons.favorite_rounded,
        accent: _red, cardColor: cardColor,
        borderColor: borderColor, isDark: isDark,
        rows: [
          _row(Icons.water_drop_rounded,         t('bloodGroup'),        p.bloodGroup),
          _row(Icons.history_rounded,            t('lastDonation'),      fmtDate(p.lastDonationDate)),
          _row(Icons.event_available_rounded,    t('nextAvailable'),     fmtDate(p.nextAvailableDonationDate)),
          _row(Icons.health_and_safety_outlined, t('eligibility'),       p.donationEligibility),
          _row(Icons.pin_drop_outlined,          t('preferredLocation'), p.preferredDonationLocation),
        ],
      ),

      // ── Academic Records ──────────────────────────────────────────────────
      ProfileSection(
        title: t('academicRecords'), icon: Icons.school_rounded,
        accent: _green, cardColor: cardColor,
        borderColor: borderColor, isDark: isDark,
        rows: [
          ProfileSubHeader(text: t('secondary'), isDark: isDark),
          _row(Icons.school_outlined,          t('school'),  p.schoolName),
          _row(Icons.history_edu_rounded,      t('ssc'),
              '${p.schoolGroup ?? 'N/A'} · ${p.schoolPassingYear ?? ''}'),
          _row(Icons.account_balance_outlined, t('college'), p.collegeName),
          _row(Icons.history_edu_rounded,      t('hsc'),
              '${p.collegeGroup ?? 'N/A'} · ${p.collegePassingYear ?? ''}'),
          ProfileSubHeader(text: t('higherEducation'), isDark: isDark),
          _row(Icons.account_balance_rounded, t('university'), p.universityName),
          _row(Icons.category_outlined,       t('department'), p.department),
        ],
      ),

      // ── Bio & Social ──────────────────────────────────────────────────────
      ProfileSection(
        title: t('bioSocial'), icon: Icons.public_rounded,
        accent: _purple, cardColor: cardColor,
        borderColor: borderColor, isDark: isDark,
        rows: [
          _row(Icons.notes_rounded,           t('shortBio'),  p.shortBio),
          _row(Icons.flag_outlined,           t('whyJoined'), p.whyJoined),
          _row(Icons.interests_outlined,      t('hobbies'),   p.hobbies),
          _row(Icons.alternate_email_rounded, t('facebook'),  p.facebook),
        ],
      ),

      if (isSelf) ...[
        const SizedBox(height: 8),
        DangerZone(onDelete: onDelete, subTextColor: subTextColor),
      ],
    ]);
  }
}

// ── Advisor Body ──────────────────────────────────────────────────────────────

class AdvisorBody extends StatelessWidget {
  final ProfileModel p;
  final bool isDark;
  final Color textColor;
  final Color subTextColor;
  final Color cardColor;
  final Color surfaceColor;
  final Color borderColor;
  final bool isSelf;
  final VoidCallback onDelete;

  static const _blue   = Color(0xFF4A90E2);
  static const _orange = Color(0xFFFF8A65);
  static const _red    = Color(0xFFEF5350);
  static const _amber  = Color(0xFFFFB300);

  const AdvisorBody({
    super.key,
    required this.p,
    required this.isDark,
    required this.textColor,
    required this.subTextColor,
    required this.cardColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.isSelf,
    required this.onDelete,
  });

  ProfileInfoRow _row(IconData icon, String label, String? value) =>
      ProfileInfoRow(
        icon: icon, label: label, value: value,
        textColor: textColor, subTextColor: subTextColor, isDark: isDark,
      );

  @override
  Widget build(BuildContext context) {
    final t = SC.tr;
    return Column(children: [
      // ── Basic Information ─────────────────────────────────────────────────
      ProfileSection(
        title: t('basicInformation'), icon: Icons.person_rounded,
        accent: _blue, cardColor: cardColor,
        borderColor: borderColor, isDark: isDark,
        rows: [
          _row(Icons.badge_outlined,          t('fullNameEN'),  p.fullName),
          _row(Icons.translate_rounded,       t('fullNameBN'),  p.fullNameBn),
          _row(Icons.wc_rounded,              t('gender'),      p.gender),
          _row(Icons.cake_outlined,           t('dateOfBirth'), fmtDate(p.dateOfBirth)),
          _row(Icons.verified_user_outlined,  t('role'),        MemberType.label(p.memberType)),
          _row(Icons.calendar_month_outlined, t('since'),       fmtDate(p.memberSince)),
        ],
      ),

      // ── Professional Information ──────────────────────────────────────────
      ProfileSection(
        title: t('professionalInformation'), icon: Icons.work_rounded,
        accent: _amber, cardColor: cardColor,
        borderColor: borderColor, isDark: isDark,
        rows: [
          _row(Icons.work_outline_rounded,     t('occupation'),  p.occupation),
          _row(Icons.account_balance_outlined, t('institution'), p.institution),
          _row(Icons.military_tech_outlined,   t('designation'), p.designation),
          _row(Icons.stars_outlined,           t('expertise'),   p.expertise),
        ],
      ),

      if (hasContent(p.advisorNote))
        NoteCard(
          note: p.advisorNote!, accent: _amber,
          icon: Icons.lightbulb_outline_rounded,
          title: t('advisorNote'), textColor: textColor,
        ),

      // ── Contact Details ───────────────────────────────────────────────────
      ProfileSection(
        title: t('contactDetails'), icon: Icons.contacts_rounded,
        accent: _orange, cardColor: cardColor,
        borderColor: borderColor, isDark: isDark,
        rows: [
          _row(Icons.chat_bubble_outline_rounded, t('whatsapp'),          p.whatsappNumber),
          _row(Icons.phone_iphone_rounded,        t('alternativeMobile'), p.alternativeMobile),
          _row(Icons.email_outlined,              t('email'),             p.email),
          _row(Icons.link_rounded,                t('facebook'),          p.facebookLink),
          _row(Icons.language_rounded,            t('portfolio'),         p.portfolioWebsite),
        ],
      ),

      // ── Blood Donation ────────────────────────────────────────────────────
      ProfileSection(
        title: t('bloodDonation'), icon: Icons.favorite_rounded,
        accent: _red, cardColor: cardColor,
        borderColor: borderColor, isDark: isDark,
        rows: [
          _row(Icons.water_drop_rounded,         t('bloodGroup'),    p.bloodGroup),
          _row(Icons.history_rounded,            t('lastDonation'),  fmtDate(p.lastDonationDate)),
          _row(Icons.event_available_rounded,    t('nextAvailable'), fmtDate(p.nextAvailableDonationDate)),
          _row(Icons.health_and_safety_outlined, t('eligibility'),   p.donationEligibility),
        ],
      ),

      if (isSelf) ...[
        const SizedBox(height: 8),
        DangerZone(onDelete: onDelete, subTextColor: subTextColor),
      ],
    ]);
  }
}