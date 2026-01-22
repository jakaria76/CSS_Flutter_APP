import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/profile_model.dart';
import '../../services/profile_service.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  final String? id;

  const ProfilePage({super.key, this.id});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  final ProfileService _service = ProfileService();
  late Future<ProfileModel?> _profileFuture;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reload();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: 0,
    )..forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      if (widget.id != null) {
        _profileFuture = _service.getProfileById(widget.id!);
      } else {
        _profileFuture = _service.getProfile();
      }
    });
  }

  Future<void> _deleteAccount() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      _showSnackBar("Please enter your password", Colors.orangeAccent);
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.6)],
            ),
          ),
          child: const Center(
            child: Card(
              color: Color(0xFF1A2634),
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 3),
                    SizedBox(height: 20),
                    Text("Deleting account...", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.auth.signInWithPassword(
        email: user.email!,
        password: password,
      );

      await supabase.from('profiles').delete().eq('id', user.id);

      try {
        await supabase.storage.from('profile-images').remove(['profiles/${user.id}.jpg']);
      } catch (_) {}

      await supabase.auth.signOut();

      if (!mounted) return;
      Navigator.of(context).pop();

      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
      _showSnackBar("Your account and data have been wiped. You must sign up again.", Colors.green);

    } on AuthException catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showSnackBar(e.message, Colors.redAccent);
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showSnackBar("Process failed. Please try again.", Colors.redAccent);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
      ),
    );
  }

  void _showDeleteDialog() {
    _passwordController.clear();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A2634), Color(0xFF0F1923)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 30, spreadRadius: 5),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Delete Account",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  "All your profile data will be permanently removed from our database. You will need to create a new account to use the app again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: "Enter your password",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.white.withOpacity(0.5), size: 20),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Cancel", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete();
                        },
                        child: const Text("Continue", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A2634), Color(0xFF0F1923)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 2),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 56),
              const SizedBox(height: 20),
              const Text(
                "Final Confirmation",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "This action cannot be undone. Do you really want to delete all your data?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("No, Go Back", style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteAccount();
                      },
                      child: const Text("Yes, Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime? d) => d == null ? "Not provided" : "${d.day}/${d.month}/${d.year}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: widget.id != null
          ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
            color: Colors.white,
          ),
        ),
      )
          : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1828),
              Color(0xFF132D46),
              Color(0xFF1B4242),
              Color(0xFF0F2D3D),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: FutureBuilder<ProfileModel?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 3),
                    const SizedBox(height: 20),
                    Text(
                      "Loading profile...",
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off_outlined, size: 80, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 20),
                    const Text('Profile not found', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              );
            }

            final p = snapshot.data!;

            return RefreshIndicator(
              onRefresh: () async => _reload(),
              backgroundColor: const Color(0xFF1A2634),
              color: Colors.cyanAccent,
              strokeWidth: 3,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAnimatedHeader(p),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        FadeTransition(
                          opacity: _fadeController,
                          child: Column(
                            children: [
                              _buildQuickStats(p),
                              const SizedBox(height: 30),
                              _buildSectionCard("Basic Information", Icons.person_rounded, const Color(0xFF4A90E2), [
                                _buildInfoRow(Icons.badge_outlined, "Full Name (EN)", p.fullName),
                                _buildInfoRow(Icons.translate_rounded, "নাম (বাংলা)", p.fullNameBn),
                                _buildInfoRow(Icons.wc_rounded, "Gender", p.gender),
                                _buildInfoRow(Icons.cake_outlined, "Date of Birth", _fmtDate(p.dateOfBirth)),
                                _buildInfoRow(Icons.verified_user_outlined, "Member Type", p.memberType),
                                _buildInfoRow(Icons.workspace_premium_outlined, "Committee Position", p.committeePosition),
                                _buildInfoRow(Icons.calendar_month_outlined, "Member Since", _fmtDate(p.memberSince)),
                              ]),
                              _buildSectionCard("Contact Details", Icons.contacts_rounded, const Color(0xFFFF8A65), [
                                _buildInfoRow(Icons.chat_bubble_outline_rounded, "WhatsApp", p.whatsappNumber),
                                _buildInfoRow(Icons.phone_iphone_rounded, "Alternative Mobile", p.alternativeMobile),
                                _buildInfoRow(Icons.home_outlined, "Present Address", p.presentAddress),
                                _buildInfoRow(Icons.location_city_outlined, "Permanent Address", p.permanentAddress),
                                Row(children: [
                                  Expanded(child: _buildInfoRow(Icons.map_outlined, "District", p.district)),
                                  const SizedBox(width: 10),
                                  Expanded(child: _buildInfoRow(Icons.explore_outlined, "Upazila", p.upazila)),
                                ]),
                              ]),
                              _buildSectionCard("Blood Donation Status", Icons.favorite_rounded, const Color(0xFFEF5350), [
                                _buildInfoRow(Icons.history_rounded, "Last Donation", _fmtDate(p.lastDonationDate)),
                                _buildInfoRow(Icons.event_available_rounded, "Next Available", _fmtDate(p.nextAvailableDonationDate)),
                                _buildInfoRow(Icons.health_and_safety_outlined, "Eligibility", p.donationEligibility),
                                _buildInfoRow(Icons.pin_drop_outlined, "Preferred Location", p.preferredDonationLocation),
                              ]),
                              _buildSectionCard("Academic Records", Icons.school_rounded, const Color(0xFF66BB6A), [
                                _buildSubHeader("Secondary Education"),
                                _buildInfoRow(Icons.school_outlined, "School", p.schoolName),
                                _buildInfoRow(Icons.history_edu_rounded, "SSC Group/Year", "${p.schoolGroup ?? 'N/A'} - ${p.schoolPassingYear ?? ''}"),
                                _buildInfoRow(Icons.account_balance_outlined, "College", p.collegeName),
                                _buildInfoRow(Icons.history_edu_rounded, "HSC Group/Year", "${p.collegeGroup ?? 'N/A'} - ${p.collegePassingYear ?? ''}"),
                                _buildSubHeader("Higher Education"),
                                _buildInfoRow(Icons.account_balance_rounded, "University", p.universityName),
                                _buildInfoRow(Icons.category_outlined, "Department", p.department),
                              ]),
                              _buildSectionCard("Geographic Location", Icons.location_on_rounded, const Color(0xFF26A69A), [
                                _buildInfoRow(Icons.gps_fixed_rounded, "Coordinates", "${p.latitude ?? 'N/A'}, ${p.longitude ?? 'N/A'}"),
                                _buildInfoRow(Icons.my_location_rounded, "Location Name", p.locationDms),
                              ]),
                              if (widget.id == null) _buildDangerZone(),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: widget.id == null ? _buildFab(context) : null,
    );
  }

  Widget _buildAnimatedHeader(ProfileModel p) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 30),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) => Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.cyanAccent.withOpacity(0.3),
                            Colors.blueAccent.withOpacity(0.2),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) => Container(
                    width: 145 + (_pulseController.value * 10),
                    height: 145 + (_pulseController.value * 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.3 - (_pulseController.value * 0.2)),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 65,
                    backgroundColor: const Color(0xFF1A2634),
                    backgroundImage: p.profileImageUrl != null ? NetworkImage(p.profileImageUrl!) : null,
                    child: p.profileImageUrl == null
                        ? Icon(Icons.person_rounded, size: 70, color: Colors.white.withOpacity(0.2))
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Text(
              p.fullName?.toUpperCase() ?? "MEMBER NAME",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.cyanAccent.withOpacity(0.25),
                    Colors.blueAccent.withOpacity(0.25),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: Colors.cyanAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    p.committeePosition ?? "Volunteer",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(ProfileModel p) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          _statBox("BLOOD", p.bloodGroup ?? "--", const Color(0xFFEF5350), Icons.water_drop_rounded),
          _statBox("DONATIONS", p.totalDonationCount?.toString() ?? "0", const Color(0xFFFF8A65), Icons.favorite_rounded),
          _statBox("STATUS", p.donationEligibility ?? "Check", const Color(0xFF66BB6A), Icons.verified_rounded),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E2E3E).withOpacity(0.8),
            const Color(0xFF152232).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              border: Border(
                bottom: BorderSide(color: color.withOpacity(0.3), width: 1.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    bool hasValue = value != null && value.isNotEmpty && value != "null";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(icon, size: 18, color: Colors.white.withOpacity(0.6)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasValue ? value : "Not provided",
                  style: TextStyle(
                    color: hasValue ? Colors.white.withOpacity(0.95) : Colors.white.withOpacity(0.3),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 14),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.cyanAccent, Colors.blueAccent],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: Colors.cyanAccent.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.cyanAccent.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.redAccent.withOpacity(0.1),
            Colors.red.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
              ),
              const SizedBox(width: 14),
              const Text(
                "Danger Zone",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Permanently delete your account and all associated data from the CSS database. This action cannot be undone.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showDeleteDialog,
              icon: const Icon(Icons.delete_forever_rounded, size: 22),
              label: const Text(
                "DELETE ACCOUNT",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FutureBuilder<ProfileModel?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () async {
              // snapshot.data! ব্যবহার করে প্রোফাইল অবজেক্টটি পাস করা হচ্ছে
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(profile: snapshot.data!),
                ),
              );
              _reload(); // ফিরে আসার পর ডাটা রিলোড করার জন্য
            },
            backgroundColor: Colors.cyanAccent,
            elevation: 0,
            icon: const Icon(Icons.edit_rounded, color: Color(0xFF0A1828), size: 22),
            label: const Text(
              "EDIT PROFILE",
              style: TextStyle(
                color: Color(0xFF0A1828),
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ),
        );
      },
    );
  }
}