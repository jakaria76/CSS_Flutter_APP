import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:css/models/complaint_model.dart';
import 'package:css/services/complaint_service.dart';
import '../SettingsPage/settings_constants.dart';

class EditComplaintPage extends StatefulWidget {
  final Complaint complaint;

  const EditComplaintPage({
    super.key,
    required this.complaint,
  });

  @override
  State<EditComplaintPage> createState() => _EditComplaintPageState();
}

class _EditComplaintPageState extends State<EditComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final _complaintService = ComplaintService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.complaint.title);
    _descriptionController = TextEditingController(text: widget.complaint.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- Delete Logic with Alert ---
  Future<void> _deleteComplaint() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: SC.isDark ? const Color(0xFF1A2634) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(SC.tr('delete_confirm_title'),
              style: TextStyle(color: SC.isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          content: Text(SC.tr('delete_confirm_msg'),
              style: TextStyle(color: SC.isDark ? Colors.white70 : Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(SC.tr('cancel_btn'), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(SC.tr('delete_btn'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        await _complaintService.deleteComplaint(widget.complaint.id);
        if (mounted) {
          SC.toast(context, SC.tr('delete_success'), Colors.orange);
          // Pop দুবার করা হয়েছে যাতে মূল লিস্টে ফিরে যায় এবং রিফ্রেশ হয়
          Navigator.pop(context, true);
          Navigator.pop(context, true);
        }
      } catch (e) {
        SC.toast(context, e.toString(), Colors.red);
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  // --- Update Logic ---
  Future<void> _updateComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);
    try {
      await _complaintService.updateComplaint(
        complaintId: widget.complaint.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      if (mounted) {
        SC.toast(context, SC.tr('update_success'), SC.green);
        Navigator.pop(context, true); // Go back with refresh signal
      }
    } catch (e) {
      SC.toast(context, e.toString(), Colors.red);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SC.themeModeNotifier,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: SC.languageNotifier,
        builder: (context, __, ___) => _buildPage(),
      ),
    );
  }

  Widget _buildPage() {
    final isDark = SC.isDark;
    final bgColor = isDark ? const Color(0xFF0F2027) : const Color(0xFFF0F4FF);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2332);
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(SC.tr('edit_complaint'),
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              onPressed: _isProcessing ? null : _deleteComplaint,
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 28),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned(top: -50, left: -50, child: SC.blob(200, Colors.cyanAccent.withOpacity(0.1))),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _titleController,
                        label: SC.tr('title_label'),
                        icon: Icons.title_rounded,
                        cardColor: cardColor,
                        textColor: textColor,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _descriptionController,
                        label: SC.tr('description_label'),
                        icon: Icons.description_rounded,
                        maxLines: 8,
                        cardColor: cardColor,
                        textColor: textColor,
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _updateComplaint,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          child: _isProcessing
                              ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : Text(SC.tr('update_btn'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    required Color cardColor,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 8),
          child: Text(label, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.cyanAccent.withOpacity(0.5)),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5)),
          ),
          validator: (v) => (v == null || v.isEmpty) ? SC.tr('field_required') : null,
        ),
      ],
    );
  }
}