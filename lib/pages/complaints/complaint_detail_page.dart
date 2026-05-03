import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:css/models/complaint_model.dart';
import '../SettingsPage/settings_constants.dart';
import 'EditComplaintPage.dart'; // পাথ নিশ্চিত করুন

class ComplaintDetailPage extends StatelessWidget {
  final Complaint complaint;

  const ComplaintDetailPage({
    super.key,
    required this.complaint,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildScaffold(context),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back, color: textColor),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            SC.tr('detail_title'),
            style: TextStyle(color: textColor, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          centerTitle: true,
          actions: [
            if (complaint.status == 'pending')
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditComplaintPage(complaint: complaint),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_note_rounded, color: Colors.cyanAccent, size: 28),
              ),
          ],
        ),
        body: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: SC.blob(200, Colors.purpleAccent.withOpacity(0.1)),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusBadge(),
                    const SizedBox(height: 20),
                    _buildTitleCard(cardColor, textColor, borderColor),
                    const SizedBox(height: 20),
                    _buildDescriptionCard(cardColor, textColor, subTextColor, borderColor),
                    if (complaint.imageUrl != null && complaint.imageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildImageCard(cardColor, borderColor),
                    ],
                    const SizedBox(height: 20),
                    _buildDetailsCard(cardColor, textColor, subTextColor, borderColor),
                    if (complaint.adminReply != null && complaint.adminReply!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildAdminReplyCard(textColor),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    switch (complaint.status) {
      case 'pending': color = Colors.orangeAccent; break;
      case 'reviewed': color = Colors.blueAccent; break;
      case 'resolved': color = Colors.greenAccent; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            '${SC.tr('status_label')}: ${complaint.getStatusBangla()}',
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleCard(Color cardColor, Color textColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                complaint.getCategoryBangla(),
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            complaint.title,
            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SC.tr('description_label'),
            style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            complaint.description,
            style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(Color cardColor, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: complaint.imageUrl!,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _row(SC.tr('submission_date'), _formatDate(complaint.createdAt), textColor, subTextColor),
          if (complaint.updatedAt != null) ...[
            const Divider(height: 24),
            _row(SC.tr('last_update'), _formatDate(complaint.updatedAt!), textColor, subTextColor),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminReplyCard(Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(SC.tr('admin_response'), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(complaint.adminReply!, style: TextStyle(color: textColor, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color textColor, Color subTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: subTextColor, fontSize: 13)),
        Text(value, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatDate(DateTime date) => "${date.day}/${date.month}/${date.year}";
}