import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'find_donors_map_page.dart';

class BloodGroupsPage extends StatefulWidget {
  const BloodGroupsPage({super.key});

  @override
  State<BloodGroupsPage> createState() => _BloodGroupsPageState();
}

class _BloodGroupsPageState extends State<BloodGroupsPage> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  bool _loading = true;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  final List<Map<String, dynamic>> bloodGroups = [
    {"group": "A+", "color": Color(0xFFE53935), "icon": Icons.favorite},
    {"group": "A-", "color": Color(0xFFD32F2F), "icon": Icons.favorite_border},
    {"group": "B+", "color": Color(0xFFC62828), "icon": Icons.favorite},
    {"group": "B-", "color": Color(0xFFB71C1C), "icon": Icons.favorite_border},
    {"group": "O+", "color": Color(0xFFFF5252), "icon": Icons.favorite},
    {"group": "O-", "color": Color(0xFFFF1744), "icon": Icons.favorite_border},
    {"group": "AB+", "color": Color(0xFFF44336), "icon": Icons.favorite},
    {"group": "AB-", "color": Color(0xFFE91E63), "icon": Icons.favorite_border},
  ];

  Map<String, Map<String, int>> stats = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fetchStats();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    setState(() => _loading = true);

    try {
      final data = await supabase.from('profiles').select('blood_group, donation_eligibility');

      Map<String, Map<String, int>> temp = {};
      for (var g in bloodGroups) {
        temp[g['group']] = {"total": 0, "ready": 0};
      }

      for (var u in data) {
        final g = u['blood_group'];
        final e = (u['donation_eligibility'] ?? '').toString().toLowerCase();

        if (temp.containsKey(g)) {
          temp[g]!['total'] = temp[g]!['total']! + 1;
          if (e == 'eligible' || e == 'ready') {
            temp[g]!['ready'] = temp[g]!['ready']! + 1;
          }
        }
      }

      setState(() {
        stats = temp;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Error fetching stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),


        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.15),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.redAccent.withOpacity(0.3),
                          Colors.pinkAccent.withOpacity(0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            const Text(
              'BLOOD SUMMARY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative background orbs
            Positioned(top: -80, left: -80, child: _blurOrb(250, Colors.redAccent.withOpacity(0.1))),
            Positioned(bottom: -50, right: -50, child: _blurOrb(200, Colors.pinkAccent.withOpacity(0.08))),
            Positioned(top: 200, right: -40, child: _blurOrb(180, Colors.purpleAccent.withOpacity(0.06))),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _loading ? _buildLoadingState() : _buildBloodGroupsList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blurOrb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [
        BoxShadow(color: color, blurRadius: 100, spreadRadius: 60),
      ],
    ),
  );

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: const Text(
              'SAVE LIVES TODAY',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Find Blood\nDonors',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with donors in your area',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    int totalDonors = 0;
    int readyDonors = 0;

    stats.forEach((key, value) {
      totalDonors += value['total'] ?? 0;
      readyDonors += value['ready'] ?? 0;
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              'Total Donors',
              totalDonors.toString(),
              Icons.people_outline,
              const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryCard(
              'Ready to Donate',
              readyDonors.toString(),
              Icons.volunteer_activism,
              const LinearGradient(colors: [Color(0xFFf093fb), Color(0xFFf5576c)]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Gradient gradient) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient.createShader(const Rect.fromLTWH(0, 0, 200, 200)) != null
                ? gradient
                : null,
            color: gradient == null ? Colors.white.withOpacity(0.08) : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.2),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.redAccent.withOpacity(0.2),
                        Colors.pinkAccent.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite, color: Colors.redAccent, size: 50),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading Blood Groups...',
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodGroupsList() {
    return RefreshIndicator(
      onRefresh: _fetchStats,
      color: Colors.redAccent,
      backgroundColor: Colors.white,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: bloodGroups.length,
        itemBuilder: (context, index) {
          return FadeTransition(
            opacity: _fadeController,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, 0.3 * (index + 1)),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _fadeController,
                  curve: Interval(
                    (index / bloodGroups.length) * 0.5,
                    1.0,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
              child: _buildBloodGroupCard(index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBloodGroupCard(int index) {
    final group = bloodGroups[index];
    final g = group['group'] as String;
    final s = stats[g] ?? {"total": 0, "ready": 0};
    final color = group['color'] as Color;
    final icon = group['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Blood Group Icon & Name
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.3), color.withOpacity(0.15)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.4), width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: color, size: 28),
                        const SizedBox(height: 4),
                        Text(
                          g,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _miniStatChip(
                              'Total',
                              s['total']!,
                              Colors.white.withOpacity(0.15),
                              Colors.white,
                            ),
                            const SizedBox(width: 8),
                            _miniStatChip(
                              'Ready',
                              s['ready']!,
                              Colors.greenAccent.withOpacity(0.2),
                              Colors.greenAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _progressBar(s['ready']!, s['total']!, color),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Find Button
                  InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FindDonorsMapPage(bloodGroup: g),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, color: Colors.white, size: 20),
                          SizedBox(height: 4),
                          Text(
                            'FIND',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStatChip(String label, int value, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar(int ready, int total, Color color) {
    double percentage = total > 0 ? (ready / total) : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability: ${(percentage * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}