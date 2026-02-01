import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class EventRegistrationsPage extends StatefulWidget {
  final int eventId;
  final String eventTitle;
  final String? bannerUrl;

  const EventRegistrationsPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.bannerUrl,
  });

  @override
  State<EventRegistrationsPage> createState() =>
      _EventRegistrationsPageState();
}

class _EventRegistrationsPageState extends State<EventRegistrationsPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  bool loading = true;
  bool onlyVolunteers = false;
  List<Map<String, dynamic>> registrations = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
    fetchRegistrations();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> fetchRegistrations() async {
    try {
      if (mounted) setState(() => loading = true);

      final res = await supabase
          .from('event_registrations')
          .select()
          .eq('event_id', widget.eventId)
          .order('registered_at', ascending: true);

      if (mounted) {
        setState(() {
          registrations = List<Map<String, dynamic>>.from(res);
          loading = false;
        });
      }
    } catch (_) {
      showMsg('Failed to load registrations');
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> downloadCSV() async {
    try {
      showMsg('📥 Preparing CSV file...');

      if (registrations.isEmpty) {
        showMsg('❌ No data to export');
        return;
      }

      List<List<dynamic>> rows = [
        [
          'Serial No.',
          'Full Name',
          'Mobile',
          'Email',
          'Gender',
          'Institute Name',
          'Class/Year',
          'Why Join',
          'Will Volunteer',
          'Payment Method',
          'User Image URL',
          'Registered At',
          'User ID',
          'Event ID',
        ]
      ];

      for (int i = 0; i < registrations.length; i++) {
        final reg = registrations[i];
        rows.add([
          (i + 1).toString(),
          reg['full_name'] ?? 'N/A',
          reg['mobile'] ?? 'N/A',
          reg['email'] ?? 'N/A',
          reg['gender'] ?? 'N/A',
          reg['institute_name'] ?? 'N/A',
          reg['class_name'] ?? 'N/A',
          reg['why_join'] ?? 'N/A',
          reg['will_volunteer'] == true ? 'Yes' : 'No',
          reg['payment_method'] ?? 'N/A',
          reg['user_image_url'] ?? 'N/A',
          reg['registered_at'] ?? 'N/A',
          reg['user_id'] ?? 'N/A',
          reg['event_id']?.toString() ?? 'N/A',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      Directory? directory;
      String filePath = '';

      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final fileName =
            '${widget.eventTitle.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
        filePath = '${directory.path}/$fileName';
      } else {
        directory = await getApplicationDocumentsDirectory();
        final fileName =
            '${widget.eventTitle.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
        filePath = '${directory.path}/$fileName';
      }

      final file = File(filePath);
      await file.writeAsString(csv);

      showMsg(
          '✅ Success! ${registrations.length} registrations\n📁 ${file.uri.pathSegments.last}');
    } catch (e) {
      showMsg('❌ Download Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = onlyVolunteers
        ? registrations.where((r) => r['will_volunteer'] == true).toList()
        : registrations;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'REGISTRATIONS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 15,
                color: Color(0xFF2575FC),
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black26,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
            Text(
              widget.eventTitle,
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withOpacity(0.4)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyanAccent.withOpacity(0.1),
                  Colors.blueAccent.withOpacity(0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.cyanAccent, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh, color: Colors.cyanAccent, size: 20),
            ),
            onPressed: fetchRegistrations,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1F3A),
              Color(0xFF0D1B2A),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
                top: -100,
                right: -100,
                child: _animatedOrb(300, Colors.cyanAccent.withOpacity(0.08))),
            Positioned(
                bottom: -150,
                left: -100,
                child: _animatedOrb(350, Colors.purpleAccent.withOpacity(0.06))),
            Positioned(
                top: 200,
                left: -50,
                child: _animatedOrb(200, Colors.blueAccent.withOpacity(0.05))),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: loading
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                          color: Colors.cyanAccent, strokeWidth: 3),
                      const SizedBox(height: 20),
                      Text(
                        'Loading registrations...',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14),
                      ),
                    ],
                  ),
                )
                    : Column(
                  children: [
                    _buildPremiumHeader(filtered.length),
                    const SizedBox(height: 15),
                    Expanded(
                      child: filtered.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                        color: Colors.cyanAccent,
                        onRefresh: fetchRegistrations,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              20, 0, 20, 100),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _buildPremiumCard(
                                filtered[index], index + 1);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: registrations.isEmpty
          ? null
          : _buildFloatingButtons(),
    );
  }

  Widget _buildPremiumHeader(int count) {
    final volunteerCount =
        registrations.where((r) => r['will_volunteer'] == true).length;
    final attendeeCount = registrations.length - volunteerCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00F5FF), Color(0xFF0080FF)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.groups_3_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL REGISTRATIONS',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${registrations.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 32,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Participants',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildCompactFilter(),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.volunteer_activism_rounded,
                        volunteerCount.toString(),
                        'Volunteers',
                        const LinearGradient(
                          colors: [Color(0xFF00FF87), Color(0xFF00C853)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        Icons.people_alt_rounded,
                        attendeeCount.toString(),
                        'Attendees',
                        const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                        ),
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

  Widget _buildStatCard(
      IconData icon, String value, String label, Gradient gradient) {
    final mainColor = gradient.colors.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mainColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: mainColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: gradient.colors.first, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: gradient.colors.first,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: gradient.colors.first.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFilter() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: onlyVolunteers
            ? Colors.greenAccent.withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: onlyVolunteers
              ? Colors.greenAccent.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.volunteer_activism_rounded,
            color: onlyVolunteers ? Colors.greenAccent : Colors.white38,
            size: 16,
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: onlyVolunteers,
              activeColor: Colors.greenAccent,
              onChanged: (v) => setState(() => onlyVolunteers = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(Map<String, dynamic> data, int index) {
    final isVolunteer = data['will_volunteer'] == true;
    final imageUrl = data['user_image_url'];
    final hasImage = imageUrl != null && imageUrl.toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(isVolunteer ? 0.12 : 0.08),
                  Colors.white.withOpacity(isVolunteer ? 0.08 : 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isVolunteer
                    ? Colors.greenAccent.withOpacity(0.4)
                    : Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Profile Image with Serial Number
                      Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.cyanAccent.withOpacity(0.3),
                                  Colors.blueAccent.withOpacity(0.3),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.cyanAccent.withOpacity(0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyanAccent.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: hasImage
                                  ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.white.withOpacity(0.1),
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: Colors.white.withOpacity(0.3),
                                      size: 30,
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.cyanAccent,
                                        strokeWidth: 2,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              )
                                  : Icon(
                                Icons.person_rounded,
                                color: Colors.white.withOpacity(0.3),
                                size: 30,
                              ),
                            ),
                          ),
                          // Serial Number Badge
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.cyanAccent, Colors.blueAccent],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF0A0E27),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                '#$index',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['full_name'] ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (data['gender'] != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      data['gender'],
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isVolunteer)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00FF87), Color(0xFF00C853)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.volunteer_activism,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'VOL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                      Icons.phone_rounded, data['mobile'], Colors.cyanAccent),
                  _buildInfoItem(
                      Icons.email_rounded, data['email'], Colors.blueAccent),
                  _buildInfoItem(Icons.school_rounded, data['institute_name'],
                      Colors.purpleAccent),
                  _buildInfoItem(Icons.class_rounded, data['class_name'],
                      Colors.orangeAccent),
                  if (data['why_join'] != null &&
                      data['why_join'].toString().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.format_quote_rounded,
                              color: Colors.cyanAccent.withOpacity(0.5),
                              size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['why_join'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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

  Widget _buildInfoItem(IconData icon, dynamic value, Color color) {
    if (value == null || value.toString().isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00FF87), Color(0xFF00C853)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: downloadCSV,
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.file_download_rounded,
                color: Colors.white, size: 24),
            label: const Text(
              'Export CSV',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              onlyVolunteers
                  ? Icons.volunteer_activism_outlined
                  : Icons.groups_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            onlyVolunteers ? 'No Volunteers Yet' : 'No Registrations Yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            onlyVolunteers
                ? 'Turn off volunteer filter to see all'
                : 'Registrations will appear here',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0),
          ],
        ),
      ),
    );
  }

  void showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.cyanAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}