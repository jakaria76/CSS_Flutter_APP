import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:css/models/complaint_model.dart';
import 'package:css/services/complaint_service.dart';
import 'complaint_form_page.dart';
import 'complaint_detail_page.dart';
import '../SettingsPage/settings_constants.dart'; // পাথ চেক করুন

class MyComplaintsPage extends StatefulWidget {
  const MyComplaintsPage({super.key});

  @override
  State<MyComplaintsPage> createState() => _MyComplaintsPageState();
}

class _MyComplaintsPageState extends State<MyComplaintsPage> {
  final _complaintService = ComplaintService();
  List<Complaint> _complaints = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final complaints = await _complaintService.getMyComplaints();
      if (mounted) {
        setState(() {
          _complaints = complaints;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = SC.tr('load_error');
        });
        SC.toast(context, SC.tr('load_error'), SC.red);
      }
    }
  }

  Future<void> _navigateToForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ComplaintFormPage()),
    );

    if (result == true) {
      _loadComplaints();
    }
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
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF4A5568);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F2027) : const Color(0xFFF0F4FF),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Text(
            SC.tr('my_complaints_title'),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _navigateToForm,
          backgroundColor: Colors.cyanAccent,
          foregroundColor: const Color(0xFF0F2027),
          icon: const Icon(Icons.add_rounded, size: 24),
          label: Text(
            SC.tr('new_complaint_btn'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Stack(
          children: [
            Positioned(
              top: -50,
              left: -50,
              child: SC.blob(200, Colors.cyanAccent.withOpacity(0.1)),
            ),
            SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                  : _errorMessage != null
                  ? _buildErrorState(textColor, subTextColor)
                  : _complaints.isEmpty
                  ? _buildEmptyState(subTextColor)
                  : RefreshIndicator(
                onRefresh: _loadComplaints,
                color: Colors.cyanAccent,
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _complaints.length,
                  itemBuilder: (context, index) {
                    return _buildComplaintCard(_complaints[index], isDark, textColor, subTextColor);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Color textColor, Color subTextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.redAccent.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              SC.tr('load_error'),
              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadComplaints,
              icon: const Icon(Icons.refresh),
              label: Text(SC.tr('retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: const Color(0xFF0F2027),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color subTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 80, color: subTextColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            SC.tr('no_complaints'),
            style: TextStyle(color: subTextColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            SC.tr('add_new_desc'),
            style: TextStyle(color: subTextColor.withOpacity(0.6), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint, bool isDark, Color textColor, Color subTextColor) {
    Color statusColor;
    IconData statusIcon;

    switch (complaint.status) {
      case 'pending':
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.pending_outlined;
        break;
      case 'reviewed':
        statusColor = Colors.blueAccent;
        statusIcon = Icons.rate_review_outlined;
        break;
      case 'resolved':
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle_outline;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08);

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComplaintDetailPage(complaint: complaint),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SC.currentCardBg.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(complaint.category).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getCategoryIcon(complaint.category),
                          color: _getCategoryColor(complaint.category),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaint.title,
                              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              complaint.getCategoryBangla(), // অথবা SC.tr দিয়ে ক্যাটাগরি কি চেক করতে পারেন
                              style: TextStyle(color: _getCategoryColor(complaint.category), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              complaint.getStatusBangla(),
                              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    complaint.description,
                    style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: subTextColor),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(complaint.createdAt),
                        style: TextStyle(color: subTextColor, fontSize: 11),
                      ),
                      const Spacer(),
                      if (complaint.adminReply != null && complaint.adminReply!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.reply_rounded, size: 12, color: Colors.greenAccent),
                              const SizedBox(width: 4),
                              Text(SC.tr('replied'), style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'complaint': return Colors.redAccent;
      case 'suggestion': return Colors.blueAccent;
      case 'feedback': return Colors.purpleAccent;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'complaint': return Icons.error_outline_rounded;
      case 'suggestion': return Icons.lightbulb_outline_rounded;
      case 'feedback': return Icons.feedback_outlined;
      default: return Icons.comment_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return SC.tr('just_now');
    if (diff.inHours < 1) return SC.tr('min_ago').replaceAll('@min', diff.inMinutes.toString());
    if (diff.inDays < 1) return SC.tr('hour_ago').replaceAll('@hour', diff.inHours.toString());
    if (diff.inDays == 1) return SC.tr('yesterday');
    if (diff.inDays < 7) return SC.tr('day_ago').replaceAll('@day', diff.inDays.toString());
    if (diff.inDays < 30) return SC.tr('week_ago').replaceAll('@week', (diff.inDays / 7).floor().toString());
    if (diff.inDays < 365) return SC.tr('month_ago').replaceAll('@month', (diff.inDays / 30).floor().toString());
    return SC.tr('year_ago').replaceAll('@year', (diff.inDays / 365).floor().toString());
  }
}