import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

import 'package:css/pages/CommitteePage/committee_page.dart';
import 'package:css/pages/PreviousPresidentPage/PreviousPresidentPage.dart';
import 'package:css/pages/AdvisorPage/advisor_page.dart';

const _kCommitteeOrder = [
  "সভাপতি", "সহ-সভাপতি", "সাধারণ সম্পাদক", "যুগ্ম-সাধারণ সম্পাদক",
  "সাংগঠনিক সম্পাদক", "সহ-সাংগঠনিক সম্পাদক", "দপ্তর সম্পাদক",
  "সিনিয়র সহ-দপ্তর সম্পাদক", "সহ-দপ্তর সম্পাদক", "অর্থ সম্পাদক",
  "সিনিয়র অর্থ সম্পাদক", "সহ-অর্থ সম্পাদক", "শিক্ষা সম্পাদক",
  "সহ-শিক্ষা সম্পাদক", "পরিকল্পনা সম্পাদক", "সহ-পরিকল্পনা সম্পাদক",
  "মানব সম্পদ সম্পাদক", "সহ-মানব সম্পদ সম্পাদক", "পরিবেশ সম্পাদক",
  "সহ-পরিবেশ সম্পাদক", "ধর্ম সম্পাদক", "সহ-ধর্ম সম্পাদক",
  "প্রচার সম্পাদক", "সহ-প্রচার সম্পাদক", "ব্র্যান্ড ও গণমাধ্যম সম্পাদক",
  "সিনিয়র ব্র্যান্ড ও গণমাধ্যম সম্পাদক", "গ্রাফিক্স ডিজাইনার",
  "সহ-গ্রাফিক্স ডিজাইনার", "ক্রিয়া সম্পাদক", "সহ-ক্রিয়া সম্পাদক",
  "পাঠাগার সম্পাদক", "সহ-পাঠাগার সম্পাদক", "সাংস্কৃতিক সম্পাদক",
  "সহ-সাংস্কৃতিক সম্পাদক", "বিজ্ঞান ও প্রযুক্তি সম্পাদক",
  "সহ-বিজ্ঞান ও প্রযুক্তি সম্পাদক", "সমাজ কল্যাণ সম্পাদক",
  "সহ-সমাজ কল্যাণ সম্পাদক", "স্বাস্থ্য সম্পাদক", "সহ-স্বাস্থ্য সম্পাদক",
  "নারী সম্পাদক", "সহ-নারী সম্পাদক", "আন্তর্জাতিক সম্পাদক",
  "সহ-আন্তর্জাতিক সম্পাদক", "ছাত্র কল্যাণ সম্পাদক",
  "সহ-ছাত্র কল্যাণ সম্পাদক", "সাহিত্য সম্পাদক", "সহ-সাহিত্য সম্পাদক",
  "তথ্য ও গবেষণা সম্পাদক", "সহ-তথ্য ও গবেষণা সম্পাদক",
  "ত্রাণ ও দুর্যোগ সম্পাদক", "সিনিয়র ত্রাণ ও দুর্যোগ সম্পাদক",
  "সহ-ত্রাণ ও দুর্যোগ সম্পাদক", "কার্যকরী সদস্য",
];

int _committeeIndex(String? pos) {
  if (pos == null) return _kCommitteeOrder.length;
  final idx = _kCommitteeOrder.indexOf(pos);
  return idx == -1 ? _kCommitteeOrder.length : idx;
}

int _advisorPriority(ProfileModel p) {
  final type = _getAdvisorType(p);
  if (type == 'chief_advisor') return 0;
  if (type == 'advisor') return 1;
  return 2;
}

String? _getAdvisorType(ProfileModel p) {
  try {
    return (p as dynamic).advisorType as String?;
  } catch (_) {
    return null;
  }
}

enum PersonSectionType { committee, advisor, previous }

class PersonSection extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final Color themeColor;
  final PersonSectionType sectionType;
  final Function(dynamic person, String? imageUrl, Color themeColor) onPersonTap;

  const PersonSection({
    super.key,
    required this.title,
    required this.items,
    required this.themeColor,
    required this.sectionType,
    required this.onPersonTap,
  });

  bool get _isPresentSection => sectionType == PersonSectionType.committee;
  bool get _isAdvisorSection => sectionType == PersonSectionType.advisor;
  bool get _isPastSection    => sectionType == PersonSectionType.previous;

  List<dynamic> get _sortedItems {
    final list = List<dynamic>.from(items);
    if (_isAdvisorSection) {
      list.sort((a, b) {
        final pa = a is ProfileModel ? _advisorPriority(a) : 2;
        final pb = b is ProfileModel ? _advisorPriority(b) : 2;
        return pa.compareTo(pb);
      });
    } else if (_isPresentSection || _isPastSection) {
      list.sort((a, b) {
        final posA = a is ProfileModel
            ? (_isPastSection
            ? (a.previousPosition ?? a.committeePosition)
            : a.committeePosition)
            : null;
        final posB = b is ProfileModel
            ? (_isPastSection
            ? (b.previousPosition ?? b.committeePosition)
            : b.committeePosition)
            : null;
        return _committeeIndex(posA).compareTo(_committeeIndex(posB));
      });
    }
    return list;
  }

  IconData get _sectionIcon {
    if (_isPresentSection) return Icons.military_tech_rounded;
    if (_isAdvisorSection) return Icons.workspace_premium_rounded;
    if (_isPastSection) return Icons.history_edu_rounded;
    return Icons.group_rounded;
  }

  String get _sectionSubtitle {
    if (_isPresentSection) return SC.tr('leadership_subtitle');
    if (_isAdvisorSection) return SC.tr('advisor_subtitle');
    if (_isPastSection) return SC.tr('past_leadership_subtitle');
    return '';
  }

  void _navigateToSeeAll(BuildContext context) {
    Widget targetPage;
    if (_isPresentSection) {
      targetPage = const CommitteePage();
    } else if (_isAdvisorSection) {
      targetPage = const AdvisorPage();
    } else {
      targetPage = const PreviousPresidentPage();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => targetPage));
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final isDark = SC.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF4A5568);
    final sorted = _sortedItems;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, textColor, subTextColor),
          SizedBox(
            height: _isPastSection ? 215 : 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: sorted.length,
              itemBuilder: (context, index) =>
                  _buildCard(context, sorted[index], index, isDark, textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: themeColor.withValues(alpha: 0.3)),
            ),
            child: Icon(_sectionIcon, color: themeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    color: themeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5),
              ),
              const SizedBox(height: 3),
              Text(_sectionSubtitle,
                  style: TextStyle(color: subTextColor, fontSize: 11)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _navigateToSeeAll(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: themeColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Text(SC.tr('view_all_btn'),
                      style: TextStyle(
                          color: themeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: themeColor, size: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, dynamic person, int index,
      bool isDark, Color textColor) {
    final String name = (person is ProfileModel)
        ? (person.fullName ?? '')
        : (person.name ?? '');
    final String role = (person is ProfileModel)
        ? (_isPastSection
        ? (person.previousPosition ??
        person.committeePosition ??
        person.designation ??
        SC.tr('member_role'))
        : (person.committeePosition ??
        person.previousPosition ??
        person.designation ??
        SC.tr('member_role')))
        : (person.role ?? SC.tr('member_role'));

    String? tenureLabel;
    if (person is ProfileModel && _isPastSection) {
      final from = person.tenureFrom;
      final to = person.tenureTo;
      if (from != null || to != null) {
        tenureLabel = '${from ?? '?'} – ${to ?? '?'}';
      }
    }

    bool isChiefAdvisor = false;
    if (person is ProfileModel && _isAdvisorSection) {
      isChiefAdvisor = _getAdvisorType(person) == 'chief_advisor';
    }

    String? imageUrl;
    if (person is ProfileModel) {
      imageUrl = person.profileImageUrl;
    } else if (person.imageUrl != null && person.imageUrl!.isNotEmpty) {
      imageUrl = Supabase.instance.client.storage
          .from('about')
          .getPublicUrl(person.imageUrl!);
    }

    final cardAccentColor = isChiefAdvisor ? SC.amber : themeColor;

    final glassBorderColor = isDark
        ? (isChiefAdvisor
        ? SC.amber.withValues(alpha: 0.5)
        : cardAccentColor.withValues(alpha: 0.25))
        : (isChiefAdvisor
        ? SC.amber.withValues(alpha: 0.6)
        : cardAccentColor.withValues(alpha: 0.35));

    final glassBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.55);

    return GestureDetector(
      onTap: () => onPersonTap(person, imageUrl, cardAccentColor),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: glassBg,
          border: Border.all(
            color: glassBorderColor,
            width: isChiefAdvisor ? 1.5 : 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(
                  name, role, imageUrl, index, cardAccentColor, isChiefAdvisor),
              _buildNameSection(
                  name, tenureLabel, cardAccentColor, textColor, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(String name, String role, String? imageUrl,
      int index, Color cardColor, bool isChiefAdvisor) {
    return Hero(
      tag: 'person_${name}_$index',
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: Stack(
          children: [
            SizedBox(
              height: 130,
              width: double.infinity,
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    _photoPlaceholder(name, cardColor),
                errorWidget: (_, __, ___) =>
                    _photoPlaceholder(name, cardColor),
              )
                  : _photoPlaceholder(name, cardColor),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 75,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.82),
                    ],
                  ),
                ),
              ),
            ),
            if (isChiefAdvisor)
              Positioned(
                top: 8,
                right: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: SC.amber.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.military_tech_rounded,
                              color: Colors.black, size: 10),
                          const SizedBox(width: 3),
                          Text(SC.tr('chief_badge'),
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: cardColor.withValues(alpha: 0.45),
                          width: 0.8),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameSection(String name, String? tenureLabel,
      Color cardColor, Color textColor, bool isDark) {
    return Expanded(
      child: ClipRRect(
        borderRadius:
        const BorderRadius.vertical(bottom: Radius.circular(22)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : cardColor.withValues(alpha: 0.06),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : cardColor.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: tenureLabel != null ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: cardColor.withValues(alpha: 0.3),
                            width: 0.5),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 9,
                        color: cardColor,
                      ),
                    ),
                  ],
                ),
                if (tenureLabel != null) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: cardColor.withValues(alpha: 0.28),
                          width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_edu_rounded,
                            size: 10,
                            color: cardColor.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(
                          tenureLabel,
                          style: TextStyle(
                            color: cardColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ এই method টা আগে বাদ পড়ে গিয়েছিল
  Widget _photoPlaceholder(String name, Color color) {
    final initials = name.trim().isNotEmpty
        ? name
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase()
        : '?';
    return Container(
      color: color.withValues(alpha: 0.08),
      child: Center(
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}