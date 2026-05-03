import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:css/models/complaint_model.dart';
import 'package:css/services/complaint_service.dart';
import 'package:css/pages/complaints/ManageComplaintPage.dart';
import '../SettingsPage/settings_constants.dart'; // পাথ চেক করুন

class AdminComplaintsPage extends StatefulWidget {
  const AdminComplaintsPage({super.key});

  @override
  State<AdminComplaintsPage> createState() => _AdminComplaintsPageState();
}

class _AdminComplaintsPageState extends State<AdminComplaintsPage>
    with SingleTickerProviderStateMixin {
  final _complaintService = ComplaintService();
  List<Complaint> _allComplaints = [];
  List<Complaint> _filteredComplaints = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_filterComplaints);
    _loadComplaints();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final complaints = await _complaintService.getAllComplaints();
      if (mounted) {
        setState(() {
          _allComplaints = complaints;
          _filterComplaints();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        SC.toast(context, '${SC.tr('load_error')}: $e', SC.red);
      }
    }
  }

  void _filterComplaints() {
    if (!mounted) return;
    setState(() {
      switch (_tabController.index) {
        case 0: _filteredComplaints = _allComplaints; break;
        case 1: _filteredComplaints = _allComplaints.where((c) => c.status == 'pending').toList(); break;
        case 2: _filteredComplaints = _allComplaints.where((c) => c.status == 'reviewed').toList(); break;
        case 3: _filteredComplaints = _allComplaints.where((c) => c.status == 'resolved').toList(); break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildScaffold(),
      ),
    );
  }

  Widget _buildScaffold() {
    final isDark = SC.isDark;
    final bgColor = isDark ? const Color(0xFF0F2027) : const Color(0xFFF0F4FF);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF132D46) : Colors.white,
          elevation: 0,
          title: Text(SC.tr('manage_complaints_title'),
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: textColor),
              onPressed: _loadComplaints,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.cyanAccent,
            labelColor: Colors.cyanAccent,
            unselectedLabelColor: textColor.withOpacity(0.5),
            isScrollable: true,
            tabs: [
              Tab(text: SC.tr('all_tab').replaceAll('@count', _allComplaints.length.toString())),
              Tab(text: SC.tr('pending_tab').replaceAll('@count', _allComplaints.where((c) => c.status == 'pending').length.toString())),
              Tab(text: SC.tr('reviewed_tab').replaceAll('@count', _allComplaints.where((c) => c.status == 'reviewed').length.toString())),
              Tab(text: SC.tr('resolved_tab').replaceAll('@count', _allComplaints.where((c) => c.status == 'resolved').length.toString())),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
            : _errorMessage != null
            ? _buildErrorState(textColor)
            : RefreshIndicator(
          onRefresh: _loadComplaints,
          color: Colors.cyanAccent,
          child: _filteredComplaints.isEmpty
              ? _buildEmptyState(textColor.withOpacity(0.5))
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredComplaints.length,
            itemBuilder: (context, index) => _buildComplaintCard(_filteredComplaints[index], isDark, textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color subColor) {
    String msg = SC.tr('no_complaints_found');
    if (_tabController.index == 1) msg = SC.tr('no_pending_msg');
    if (_tabController.index == 2) msg = SC.tr('no_reviewed_msg');
    if (_tabController.index == 3) msg = SC.tr('no_resolved_msg');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: subColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: subColor, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint, bool isDark, Color textColor) {
    final cardBg = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ManageComplaintPage(complaint: complaint)),
        );
        if (result == true) _loadComplaints();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                  backgroundImage: complaint.userProfileImageUrl != null ? NetworkImage(complaint.userProfileImageUrl!) : null,
                  child: complaint.userProfileImageUrl == null ? Icon(Icons.person, color: textColor.withOpacity(0.3)) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(complaint.userFullName ?? 'User', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(complaint.getCategoryBangla(), style: const TextStyle(color: Colors.cyanAccent, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.edit_note, color: Colors.cyanAccent.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 15),
            Text(complaint.title, style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(complaint.description, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
            if (complaint.imageUrl != null && complaint.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(complaint.imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 50, color: Colors.grey.withOpacity(0.1), child: Center(child: Text(SC.tr('image_not_available'))))),
              ),
            ],
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(complaint.status),
                Text(_formatDate(complaint.createdAt), style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'pending': color = Colors.orangeAccent; break;
      case 'reviewed': color = Colors.blueAccent; break;
      case 'resolved': color = Colors.greenAccent; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildErrorState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(SC.tr('load_error'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _loadComplaints, child: Text(SC.tr('retry'))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return SC.tr('just_now');
    if (diff.inHours < 1) return SC.tr('min_ago').replaceAll('@min', diff.inMinutes.toString());
    if (diff.inDays < 1) return SC.tr('hour_ago').replaceAll('@hour', diff.inHours.toString());
    if (diff.inDays == 1) return SC.tr('yesterday');
    return SC.tr('day_ago').replaceAll('@day', diff.inDays.toString());
  }
}