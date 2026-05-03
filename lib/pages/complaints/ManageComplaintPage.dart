import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:css/models/complaint_model.dart';
import 'package:css/services/complaint_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../SettingsPage/settings_constants.dart'; // পাথ চেক করুন

class ManageComplaintPage extends StatefulWidget {
  final Complaint complaint;

  const ManageComplaintPage({
    super.key,
    required this.complaint,
  });

  @override
  State<ManageComplaintPage> createState() => _ManageComplaintPageState();
}

class _ManageComplaintPageState extends State<ManageComplaintPage> {
  final _complaintService = ComplaintService();
  final _replyController = TextEditingController();

  late String _selectedStatus;
  bool _isUpdating = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.complaint.status;
    _replyController.text = widget.complaint.adminReply ?? '';
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _updateComplaint() async {
    setState(() => _isUpdating = true);
    try {
      await _complaintService.updateComplaintStatus(
        complaintId: widget.complaint.id,
        status: _selectedStatus,
        adminReply: _replyController.text.trim().isEmpty
            ? null
            : _replyController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
        SC.toast(context, SC.tr('update_success'), SC.green);
      }
    } catch (e) {
      SC.toast(context, '${SC.tr('update_failed')}: $e', SC.red);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteComplaint() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: SC.isDark ? const Color(0xFF203A43) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(SC.tr('delete_confirm_title'),
              style: TextStyle(color: SC.isDark ? Colors.white : Colors.black)),
          content: Text(SC.tr('delete_confirm_desc'),
              style: TextStyle(color: SC.isDark ? Colors.white70 : Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(SC.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text(SC.tr('delete'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      try {
        await _complaintService.deleteComplaint(widget.complaint.id);
        if (mounted) {
          Navigator.pop(context, true);
          SC.toast(context, SC.tr('delete_success'), SC.green);
        }
      } catch (e) {
        SC.toast(context, e.toString(), SC.red);
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
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
    final bgColor = isDark ? const Color(0xFF0F2027) : const Color(0xFFF0F4FF);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final subTextColor = isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF4A5568);
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF132D46) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(SC.tr('manage_complaint'),
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          actions: [
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent))
                  : const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _isDeleting ? null : _deleteComplaint,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updateComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isUpdating
                    ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(SC.tr('save'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned(bottom: -100, left: -100, child: SC.blob(300, Colors.purpleAccent.withOpacity(0.05))),
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserInfoCard(cardColor, textColor, subTextColor, borderColor),
                  const SizedBox(height: 20),
                  _buildDetailsCard(cardColor, textColor, subTextColor, borderColor),
                  const SizedBox(height: 20),
                  _buildStatusSelector(cardColor, textColor, borderColor),
                  const SizedBox(height: 20),
                  _buildReplySection(cardColor, textColor, subTextColor, borderColor),
                  const SizedBox(height: 20),
                  if (widget.complaint.imageUrl != null && widget.complaint.imageUrl!.isNotEmpty)
                    _buildComplaintImage(textColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.cyanAccent.withOpacity(0.1),
            backgroundImage: widget.complaint.userProfileImageUrl != null ? NetworkImage(widget.complaint.userProfileImageUrl!) : null,
            child: widget.complaint.userProfileImageUrl == null ? Icon(Icons.person, color: subTextColor) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.complaint.userFullName ?? 'User', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(widget.complaint.getCategoryBangla(), style: const TextStyle(color: Colors.cyanAccent, fontSize: 13)),
                Text(_formatDate(widget.complaint.createdAt), style: TextStyle(color: subTextColor, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(SC.tr('complaint_details'), Icons.description_outlined, Colors.cyanAccent, textColor),
          const SizedBox(height: 12),
          Text(widget.complaint.title, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(widget.complaint.description, style: TextStyle(color: subTextColor, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildStatusSelector(Color cardColor, Color textColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(SC.tr('update_status'), Icons.toggle_on_outlined, Colors.purpleAccent, textColor),
          const SizedBox(height: 12),
          _statusItem('pending', SC.tr('status_pending'), Icons.pending_outlined, Colors.orangeAccent),
          const SizedBox(height: 8),
          _statusItem('reviewed', SC.tr('status_reviewed'), Icons.rate_review_outlined, Colors.blueAccent),
          const SizedBox(height: 8),
          _statusItem('resolved', SC.tr('status_resolved'), Icons.check_circle_outline, Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _statusItem(String value, String label, IconData icon, Color color) {
    final isSelected = _selectedStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: isSelected ? color : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReplySection(Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(SC.tr('admin_reply'), Icons.reply_rounded, Colors.greenAccent, textColor),
          const SizedBox(height: 12),
          TextField(
            controller: _replyController,
            maxLines: 4,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: SC.tr('reply_hint'),
              hintStyle: TextStyle(color: subTextColor.withOpacity(0.5)),
              filled: true,
              fillColor: SC.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintImage(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(SC.tr('attached_image'), Icons.image_outlined, Colors.pinkAccent, textColor),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: widget.complaint.imageUrl!,
            placeholder: (context, url) => Container(height: 200, color: Colors.grey.withOpacity(0.1), child: const Center(child: CircularProgressIndicator())),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color iconColor, Color textColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return SC.tr('just_now');
    if (diff.inHours < 1) return SC.tr('min_ago').replaceAll('@min', diff.inMinutes.toString());
    if (diff.inDays < 1) return SC.tr('hour_ago').replaceAll('@hour', diff.inHours.toString());
    return SC.tr('day_ago').replaceAll('@day', diff.inDays.toString());
  }
}