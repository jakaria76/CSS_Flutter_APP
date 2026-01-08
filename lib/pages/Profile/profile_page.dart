import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/profile_model.dart';
import '../../services/profile_service.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  final String? id; // অন্য ডোনারের প্রোফাইল দেখার জন্য আইডি

  // id নাল থাকলে এটি নিজের প্রোফাইল দেখাবে
  const ProfilePage({super.key, this.id});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  final ProfileService _service = ProfileService();
  late Future<ProfileModel?> _profileFuture;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _reload();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      if (widget.id != null) {
        // আইডি থাকলে নির্দিষ্ট ইউজারের প্রোফাইল ফেচ করবে
        _profileFuture = _service.getProfileById(widget.id!);
      } else {
        // আইডি না থাকলে নিজের প্রোফাইল ফেচ করবে
        _profileFuture = _service.getProfile();
      }
    });
  }

  String _fmtDate(DateTime? d) =>
      d == null ? "Not provided" : "${d.day}/${d.month}/${d.year}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // অন্য ইউজারের প্রোফাইল দেখলে ব্যাক বাটন সহ AppBar দেখাবে
      appBar: widget.id != null
          ? AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white))
          : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: FutureBuilder<ProfileModel?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('Profile not found', style: TextStyle(color: Colors.white)));
            }

            final p = snapshot.data!;

            return RefreshIndicator(
              onRefresh: () async => _reload(),
              edgeOffset: 80,
              backgroundColor: const Color(0xFF203A43),
              color: Colors.cyanAccent,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAnimatedHeader(p),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildQuickStats(p),
                        const SizedBox(height: 25),

                        _buildSectionCard("Basic Information", Icons.person_rounded, Colors.blueAccent, [
                          _buildInfoRow(Icons.badge_outlined, "Full Name (EN)", p.fullName),
                          _buildInfoRow(Icons.translate_rounded, "নাম (বাংলা)", p.fullNameBn),
                          _buildInfoRow(Icons.wc_rounded, "Gender", p.gender),
                          _buildInfoRow(Icons.cake_outlined, "Date of Birth", _fmtDate(p.dateOfBirth)),
                          _buildInfoRow(Icons.verified_user_outlined, "Member Type", p.memberType),
                          _buildInfoRow(Icons.workspace_premium_outlined, "Committee Position", p.committeePosition),
                          _buildInfoRow(Icons.calendar_month_outlined, "Member Since", _fmtDate(p.memberSince)),
                        ]),

                        _buildSectionCard("Contact Details", Icons.alternate_email_rounded, Colors.orangeAccent, [
                          _buildInfoRow(Icons.chat_bubble_outline_rounded, "WhatsApp", p.whatsappNumber),
                          _buildInfoRow(Icons.phone_iphone_rounded, "Alt Mobile", p.alternativeMobile),
                          _buildInfoRow(Icons.home_outlined, "Present Address", p.presentAddress),
                          _buildInfoRow(Icons.location_city_outlined, "Permanent Address", p.permanentAddress),
                          Row(children: [
                            Expanded(child: _buildInfoRow(Icons.map_outlined, "District", p.district)),
                            Expanded(child: _buildInfoRow(Icons.explore_outlined, "Upazila", p.upazila)),
                          ]),
                        ]),

                        _buildSectionCard("Blood Donation Status", Icons.favorite_rounded, Colors.redAccent, [
                          _buildInfoRow(Icons.history_rounded, "Last Donation", _fmtDate(p.lastDonationDate)),
                          _buildInfoRow(Icons.event_available_rounded, "Next Available", _fmtDate(p.nextAvailableDonationDate)),
                          _buildInfoRow(Icons.health_and_safety_outlined, "Eligibility", p.donationEligibility),
                          _buildInfoRow(Icons.pin_drop_outlined, "Preferred Location", p.preferredDonationLocation),
                        ]),

                        _buildSectionCard("Academic Records", Icons.auto_stories_rounded, Colors.greenAccent, [
                          _buildSubHeader("SSC & HSC"),
                          _buildInfoRow(Icons.school_outlined, "School", p.schoolName),
                          _buildInfoRow(Icons.history_edu_rounded, "SSC Group/Year", "${p.schoolGroup ?? 'N/A'} - ${p.schoolPassingYear ?? ''}"),
                          _buildInfoRow(Icons.account_balance_outlined, "College", p.collegeName),
                          _buildInfoRow(Icons.history_edu_rounded, "HSC Group/Year", "${p.collegeGroup ?? 'N/A'} - ${p.collegePassingYear ?? ''}"),
                          _buildSubHeader("University"),
                          _buildInfoRow(Icons.account_balance_rounded, "University", p.universityName),
                          _buildInfoRow(Icons.category_outlined, "Department", p.department),
                        ]),

                        _buildSectionCard("Geographic Location", Icons.map_rounded, Colors.tealAccent, [
                          _buildInfoRow(Icons.gps_fixed_rounded, "Coordinates", "${p.latitude ?? 'N/A'}, ${p.longitude ?? 'N/A'}"),
                          _buildInfoRow(Icons.my_location_rounded, "Location Name", p.locationDms),
                        ]),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      // এডিট বাটন শুধুমাত্র নিজের প্রোফাইলের ক্ষেত্রে দেখাবে
      floatingActionButton: widget.id == null ? _buildFab(context) : null,
    );
  }

  // --- Premium Widgets ---
  Widget _buildAnimatedHeader(ProfileModel p) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) => Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white10, width: 2)),
                    child: CircularProgressIndicator(value: _rotationController.value, strokeWidth: 2, color: Colors.cyanAccent.withOpacity(0.5)),
                  ),
                ),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF1A2A3A),
                  backgroundImage: p.profileImageUrl != null ? NetworkImage(p.profileImageUrl!) : null,
                  child: p.profileImageUrl == null ? const Icon(Icons.person, size: 60, color: Colors.white24) : null,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(p.fullName?.toUpperCase() ?? "MEMBER NAME", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.cyanAccent.withOpacity(0.2), Colors.blueAccent.withOpacity(0.2)]), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.cyanAccent.withOpacity(0.3))),
              child: Text(p.committeePosition ?? "Volunteer", style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(ProfileModel p) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        _statBox("BLOOD", p.bloodGroup ?? "--", Colors.redAccent),
        _statBox("DONATIONS", p.totalDonationCount?.toString() ?? "0", Colors.orangeAccent),
        _statBox("ELIGIBILITY", p.donationEligibility ?? "Check", Colors.greenAccent),
      ]),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(5), padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.08))),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(color: const Color(0xFF1E2E3A).withOpacity(0.7), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))),
          child: Row(children: [Icon(icon, color: color, size: 22), const SizedBox(width: 12), Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16))]),
        ),
        Padding(padding: const EdgeInsets.all(20), child: Column(children: children)),
      ]),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    bool hasValue = value != null && value.isNotEmpty && value != "null";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: Colors.white38),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.bold)),
          Text(hasValue ? value : "Not provided", style: TextStyle(color: hasValue ? Colors.white.withOpacity(0.9) : Colors.white24, fontWeight: FontWeight.w600, fontSize: 14)),
        ])),
      ]),
    );
  }

  Widget _buildSubHeader(String text) {
    return Padding(padding: const EdgeInsets.only(top: 20, bottom: 10), child: Row(children: [Text(text, style: TextStyle(color: Colors.cyanAccent.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)), const SizedBox(width: 10), const Expanded(child: Divider(color: Colors.white10))]));
  }

  Widget _buildFab(BuildContext context) {
    return FutureBuilder<ProfileModel?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage(profile: snapshot.data!)));
            _reload();
          },
          backgroundColor: Colors.cyanAccent,
          icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF0F2027)),
          label: const Text("EDIT PROFILE", style: TextStyle(color: Color(0xFF0F2027), fontWeight: FontWeight.w900)),
        );
      },
    );
  }
}