import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:css/models/about_models.dart';
import 'package:css/services/about_service.dart';

class ManageAboutPage extends StatefulWidget {
  const ManageAboutPage({super.key});

  @override
  State<ManageAboutPage> createState() => _ManageAboutPageState();
}

class _ManageAboutPageState extends State<ManageAboutPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AboutService _aboutService = AboutService();
  final ImagePicker _picker = ImagePicker();

  bool loading = false;
  bool initialLoading = true;
  Map<String, bool> uploadingImages = {};

  // Data Holders
  int? overviewId;
  String orgDescription = "";
  int foundedYear = 2022;
  String focusAreas = "";

  int? contactId;
  String contactEmail = "";
  String contactPhone = "";
  String contactAddress = "";
  String contactFacebook = "";
  String contactWebsite = "";

  List<MissionPoint> missions = [];
  List<Activity> activities = [];
  List<Advisor> advisors = [];
  List<PreviousPresident> presidents = [];
  List<Leadership> leaders = [];
  List<StoryEvent> story = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ================= DATA LOADING =================
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => initialLoading = true);
    try {
      final data = await _aboutService.getAllAboutData();
      if (!mounted) return;
      setState(() {
        final overview = data['overview'] as AboutOverview?;
        if (overview != null) {
          overviewId = overview.id;
          orgDescription = overview.description;
          foundedYear = overview.foundedYear;
          focusAreas = overview.focus;
        }

        final contact = data['contact'] as ContactInfo?;
        if (contact != null) {
          contactId = contact.id;
          contactEmail = contact.email;
          contactPhone = contact.phone;
          contactAddress = contact.address;
          contactFacebook = contact.facebook ?? "";
          contactWebsite = contact.website ?? "";
        }

        missions = (data['missionPoints'] as List<MissionPoint>?) ?? [];
        activities = (data['activities'] as List<Activity>?) ?? [];
        advisors = (data['advisors'] as List<Advisor>?) ?? [];
        presidents = (data['previousPresidents'] as List<PreviousPresident>?) ?? [];
        leaders = (data['leadership'] as List<Leadership>?) ?? [];
        story = (data['story'] as List<StoryEvent>?) ?? [];
        initialLoading = false;
      });
    } catch (e) {
      _showMessage('Failed to load data: $e');
      if (mounted) setState(() => initialLoading = false);
    }
  }

  // ================= IMAGE UPLOAD =================
  Future<String?> _uploadImage(XFile xFile, String folder, String filename) async {
    try {
      final path = '$folder/$filename';
      final bytes = await xFile.readAsBytes();
      await Supabase.instance.client.storage.from('about').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );
      return path;
    } catch (e) {
      _showMessage('Image upload failed: $e');
      return null;
    }
  }

  // ================= SAVE & DELETE METHODS =================
  Future<void> _handleTeamMemberSave(String type, Map<String, dynamic> data, XFile? imageFile, {int? id}) async {
    setState(() => loading = true);
    try {
      String folder = type == 'advisor' ? 'advisors' : type == 'president' ? 'presidents' : 'leadership';
      String table = type == 'advisor' ? 'about_advisors' : type == 'president' ? 'about_previous_presidents' : 'about_leadership';

      if (imageFile != null) {
        String? path = await _uploadImage(imageFile, folder, '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        if (path != null) data['image_url'] = path;
      }

      if (id != null) {
        await Supabase.instance.client.from(table).update(data).eq('id', id);
      } else {
        await Supabase.instance.client.from(table).insert({...data, 'order_index': 0});
      }

      await _loadData();
      _showMessage('Member saved successfully!', isError: false);
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _deleteItem(String table, int id) async {
    setState(() => loading = true);
    try {
      await Supabase.instance.client.from(table).delete().eq('id', id);
      await _loadData();
      _showMessage('Deleted successfully', isError: false);
    } catch (e) {
      _showMessage('Failed: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _saveOverview() async {
    setState(() => loading = true);
    try {
      final data = {'description': orgDescription, 'founded_year': foundedYear, 'focus': focusAreas};
      if (overviewId != null) {
        await Supabase.instance.client.from('about_overview').update(data).eq('id', overviewId!);
      } else {
        await Supabase.instance.client.from('about_overview').insert(data);
      }
      _showMessage('Overview saved!', isError: false);
      _loadData();
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _saveContact() async {
    setState(() => loading = true);
    try {
      final data = {
        'email': contactEmail,
        'phone': contactPhone,
        'address': contactAddress,
        'facebook': contactFacebook,
        'website': contactWebsite
      };
      if (contactId != null) {
        await Supabase.instance.client.from('about_contact').update(data).eq('id', contactId!);
      } else {
        await Supabase.instance.client.from('about_contact').insert(data);
      }
      _showMessage('Contact saved!', isError: false);
      _loadData();
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ================= UI BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
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
            // Decorative background lights
            Positioned(top: -50, left: -50, child: _blurOrb(200, Colors.cyanAccent.withOpacity(0.1))),
            Positioned(bottom: 100, right: -30, child: _blurOrb(150, Colors.purpleAccent.withOpacity(0.05))),

            SafeArea(
              child: initialLoading
                  ? _buildLoadingState()
                  : Column(
                children: [
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildMissionTab(),
                        _buildActivitiesTab(),
                        _buildAdvisorsTab(),
                        _buildPresidentsTab(),
                        _buildLeadersTab(),
                        _buildStoryTab(),
                        _buildContactTab(),
                      ],
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

  Widget _blurOrb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)],
    ),
  );

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.cyanAccent, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MANAGE ABOUT ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Content Management',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: loading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
            )
                : const Icon(Icons.refresh_rounded, color: Colors.cyanAccent),
            onPressed: loading ? null : _loadData,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: Colors.cyanAccent,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading Dashboard...',
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: Colors.cyanAccent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: const Color(0xFF0F2027),
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Overview'),
          Tab(icon: Icon(Icons.flag_outlined, size: 18), text: 'Mission'),
          Tab(icon: Icon(Icons.event_note_outlined, size: 18), text: 'Activities'),
          Tab(icon: Icon(Icons.school_outlined, size: 18), text: 'Advisors'),
          Tab(icon: Icon(Icons.workspace_premium_outlined, size: 18), text: 'Presidents'),
          Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Leaders'),
          Tab(icon: Icon(Icons.timeline_outlined, size: 18), text: 'Story'),
          Tab(icon: Icon(Icons.contact_mail_outlined, size: 18), text: 'Contact'),
        ],
      ),
    );
  }

  // ================= TAB WIDGETS =================
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Organization Overview', Icons.business_outlined),
                const SizedBox(height: 20),
                _buildModernTextField(
                  label: 'Organization Description',
                  initialValue: orgDescription,
                  maxLines: 5,
                  onChanged: (v) => orgDescription = v,
                  hint: "Tell us about your organization...",
                  icon: Icons.description_outlined,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildModernTextField(
                        label: 'Founded Year',
                        initialValue: foundedYear.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => foundedYear = int.tryParse(v) ?? foundedYear,
                        icon: Icons.calendar_today_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModernTextField(
                        label: 'Primary Focus',
                        initialValue: focusAreas,
                        onChanged: (v) => focusAreas = v,
                        hint: "e.g. Social Work",
                        icon: Icons.star_border,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSaveButton(_saveOverview, 'Save Overview'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionTab() => _buildListTab(
    missions,
    'Mission Points',
    'about_mission_points',
    Icons.flag_outlined,
        (v) => _saveMission(v),
  );

  Widget _buildActivitiesTab() => _buildListTab(
    activities,
    'Activities',
    'about_activities',
    Icons.event_note_outlined,
        (v) => _saveActivity(v),
  );

  Widget _buildStoryTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _buildModernFAB(
        onPressed: _addStoryEvent,
        icon: Icons.add_rounded,
        label: 'Add Event',
      ),
      body: story.isEmpty
          ? _buildEmptyState('No Story Events', 'Add your first milestone', Icons.timeline_outlined)
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: story.length,
        itemBuilder: (_, i) => _buildStoryCard(story[i]),
      ),
    );
  }

  Widget _buildStoryCard(StoryEvent event) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event, color: Colors.cyanAccent, size: 20),
            ),
            title: Text(
              event.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12, color: Colors.cyanAccent),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd MMM yyyy').format(event.eventDate),
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
              ),
              onPressed: () => _showDeleteDialog(() => _deleteItem('about_story', event.id)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvisorsTab() => _buildPersonGrid(advisors, 'advisor', 'Advisors');
  Widget _buildPresidentsTab() => _buildPersonGrid(presidents, 'president', 'Previous Presidents');
  Widget _buildLeadersTab() => _buildPersonGrid(leaders, 'leader', 'Leadership Team');

  Widget _buildPersonGrid(List list, String type, String title) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _buildModernFAB(
        onPressed: () => _showPersonFormDialog(type),
        icon: Icons.person_add_rounded,
        label: 'Add Member',
      ),
      body: list.isEmpty
          ? _buildEmptyState('No $title', 'Add your first member', Icons.people_outline)
          : GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: list.length,
        itemBuilder: (_, i) => _buildPersonCard(list[i], type),
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Contact Information', Icons.contacts_outlined),
                const SizedBox(height: 20),
                _buildModernTextField(
                  label: 'Email Address',
                  initialValue: contactEmail,
                  hint: 'contact@example.com',
                  icon: Icons.email_outlined,
                  onChanged: (v) => contactEmail = v,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  label: 'Phone Number',
                  initialValue: contactPhone,
                  hint: '+880 1XXX-XXXXXX',
                  icon: Icons.phone_outlined,
                  onChanged: (v) => contactPhone = v,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  label: 'Address',
                  initialValue: contactAddress,
                  hint: 'Enter full address',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                  onChanged: (v) => contactAddress = v,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Social Media & Web', Icons.link),
                const SizedBox(height: 20),
                _buildModernTextField(
                  label: 'Facebook Page',
                  initialValue: contactFacebook,
                  hint: 'https://facebook.com/yourpage',
                  icon: Icons.facebook,
                  onChanged: (v) => contactFacebook = v,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  label: 'Website URL',
                  initialValue: contactWebsite,
                  hint: 'https://yourwebsite.com',
                  icon: Icons.language,
                  onChanged: (v) => contactWebsite = v,
                ),
                const SizedBox(height: 32),
                _buildSaveButton(_saveContact, 'Save Contact Info'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= COMPONENTS =================
  Widget _buildModernCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.cyanAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.cyanAccent, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    String? label,
    String? initialValue,
    Function(String)? onChanged,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: TextFormField(
            initialValue: initialValue,
            onChanged: onChanged,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon: icon != null
                  ? Icon(icon, color: Colors.cyanAccent.withOpacity(0.7), size: 20)
                  : null,
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonCard(dynamic member, String type) {
    String table = type == 'advisor'
        ? 'about_advisors'
        : type == 'president'
        ? 'about_previous_presidents'
        : 'about_leadership';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.cyanAccent, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.black.withOpacity(0.3),
                  backgroundImage: member.imageUrl != null
                      ? NetworkImage(
                    Supabase.instance.client.storage.from('about').getPublicUrl(member.imageUrl),
                  )
                      : null,
                  child: member.imageUrl == null
                      ? const Icon(Icons.person, color: Colors.cyanAccent, size: 35)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  member.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                member.role,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildIconButton(
                      Icons.edit_outlined,
                      Colors.cyanAccent,
                          () => _showPersonFormDialog(type, member: member),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    _buildIconButton(
                      Icons.delete_outline,
                      Colors.redAccent,
                          () => _showDeleteDialog(() => _deleteItem(table, member.id)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildListTab(
      List list,
      String title,
      String table,
      IconData icon,
      Function(String) onAdd,
      ) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _buildModernFAB(
        onPressed: () => _showInputDialog('Add $title', TextEditingController(), (v) => onAdd(v)),
        icon: Icons.add_rounded,
        label: 'Add $title',
      ),
      body: list.isEmpty
          ? _buildEmptyState('No $title', 'Add your first item', icon)
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: list.length,
        itemBuilder: (_, i) {
          String text = list[i] is MissionPoint
              ? list[i].text
              : (list[i] is Activity ? list[i].title : "");
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.cyanAccent, size: 18),
                  ),
                  title: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    ),
                    onPressed: () => _showDeleteDialog(() => _deleteItem(table, list[i].id)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernFAB({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: Colors.cyanAccent,
      elevation: 10,
      icon: Icon(icon, color: const Color(0xFF0F2027)),
      label: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0F2027),
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: Colors.cyanAccent),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(VoidCallback onTap, String label) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: const Color(0xFF0F2027),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          shadowColor: Colors.cyanAccent.withOpacity(0.3),
        ),
        child: loading
            ? const SizedBox(
          height: 25,
          width: 25,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Color(0xFF0F2027),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.save_outlined, size: 20),
            const SizedBox(width: 10),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DIALOGS =================
  void _showPersonFormDialog(String type, {dynamic member}) {
    final nameC = TextEditingController(text: member?.name);
    final roleC = TextEditingController(text: member?.role);
    final messageC = TextEditingController(text: member?.message);
    final bioC = TextEditingController(text: member?.bio);
    XFile? selectedImage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.2),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_add_alt_1, color: Colors.cyanAccent, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              '${member == null ? 'Add' : 'Edit'} ${type.toUpperCase()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final img = await _picker.pickImage(source: ImageSource.gallery);
                                if (img != null) setDState(() => selectedImage = img);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.cyanAccent, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.black.withOpacity(0.3),
                                  backgroundImage: selectedImage != null
                                      ? FileImage(File(selectedImage!.path))
                                      : (member?.imageUrl != null
                                      ? NetworkImage(Supabase.instance.client.storage
                                      .from('about')
                                      .getPublicUrl(member!.imageUrl!))
                                      : null) as ImageProvider?,
                                  child: selectedImage == null && member?.imageUrl == null
                                      ? const Icon(Icons.add_a_photo, color: Colors.cyanAccent, size: 30)
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildDialogField(nameC, 'Full Name', Icons.person_outline),
                            _buildDialogField(
                              roleC,
                              type == 'president' ? 'Term (e.g. 2022-23)' : 'Official Position',
                              Icons.work_outline,
                            ),
                            _buildDialogField(
                              messageC,
                              'Message/Quote',
                              Icons.format_quote,
                              maxLines: 3,
                            ),
                            _buildDialogField(bioC, 'Biography', Icons.description_outlined, maxLines: 4),
                          ],
                        ),
                      ),
                      // Actions
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final data = {
                                    'name': nameC.text,
                                    type == 'president' ? 'term' : 'role': roleC.text,
                                    'message': messageC.text,
                                    'bio': bioC.text
                                  };
                                  _handleTeamMemberSave(type, data, selectedImage, id: member?.id);
                                  Navigator.pop(ctx);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: Colors.cyanAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Save Member',
                                  style: TextStyle(
                                    color: Color(0xFF0F2027),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
        ),
      ),
    );
  }

  void _addStoryEvent() {
    final descC = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.2),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.event_note, color: Colors.cyanAccent, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'New Story Event',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) setDState(() => selectedDate = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month, color: Colors.cyanAccent),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(selectedDate),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildDialogField(descC, 'Event Description', Icons.description_outlined, maxLines: 4),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (descC.text.isEmpty) return;
                                _saveStory(DateFormat('yyyy-MM-dd').format(selectedDate), descC.text);
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.cyanAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Add Event',
                                style: TextStyle(
                                  color: Color(0xFF0F2027),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildDialogField(
      TextEditingController controller,
      String hint,
      IconData icon, {
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: Icon(icon, color: Colors.cyanAccent.withOpacity(0.7), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }

  void _showMessage(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent.withOpacity(0.9) : Colors.greenAccent.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  void _showDeleteDialog(VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 40),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Delete Permanently?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This action cannot be undone',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              onDelete();
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  void _showInputDialog(String title, TextEditingController c, Function(String) onSave) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.2),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline, color: Colors.cyanAccent, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: TextField(
                        controller: c,
                        autofocus: true,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter text here...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (c.text.isNotEmpty) {
                                onSave(c.text);
                                Navigator.pop(ctx);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.cyanAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                color: Color(0xFF0F2027),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  // ================= API HELPERS =================
  void _saveMission(String v, {int? id}) async {
    try {
      if (id != null) {
        await Supabase.instance.client.from('about_mission_points').update({'text': v}).eq('id', id);
      } else {
        await Supabase.instance.client.from('about_mission_points').insert({'text': v, 'order_index': missions.length});
      }
      _loadData();
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  void _saveActivity(String v) async {
    try {
      await Supabase.instance.client.from('about_activities').insert({
        'title': v,
        'icon': 'bolt',
        'order_index': activities.length
      });
      _loadData();
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  void _saveStory(String date, String desc) async {
    try {
      await Supabase.instance.client.from('about_story').insert({
        'event_date': date,
        'description': desc,
        'order_index': story.length
      });
      _loadData();
    } catch (e) {
      _showMessage(e.toString());
    }
  }
}