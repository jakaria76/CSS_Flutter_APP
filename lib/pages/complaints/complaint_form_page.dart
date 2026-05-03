import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:css/models/complaint_model.dart';
import 'package:css/services/complaint_service.dart';
import '../SettingsPage/settings_constants.dart'; // পাথ চেক করুন

class ComplaintFormPage extends StatefulWidget {
  const ComplaintFormPage({super.key});

  @override
  State<ComplaintFormPage> createState() => _ComplaintFormPageState();
}

class _ComplaintFormPageState extends State<ComplaintFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _complaintService = ComplaintService();
  final _imagePicker = ImagePicker();

  ComplaintCategory _selectedCategory = ComplaintCategory.feedback;
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      SC.toast(context, SC.tr('image_error'), SC.red);
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await _complaintService.submitComplaint(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory.englishName,
        image: _selectedImage,
      );

      if (mounted) {
        SC.toast(context, SC.tr('submit_success'), SC.green);
        Navigator.pop(context, true);
      }
    } catch (e) {
      SC.toast(context, SC.tr('submit_error'), SC.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
    final fieldColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
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
            SC.tr('submit_feedback_title'),
            style: TextStyle(color: textColor, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Positioned(top: -50, right: -50, child: SC.blob(200, Colors.cyanAccent.withOpacity(0.1))),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildHeaderCard(isDark, textColor, subTextColor, borderColor),
                      const SizedBox(height: 25),
                      _buildCategorySelector(isDark, textColor, borderColor),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _titleController,
                        label: SC.tr('title_label'),
                        hint: SC.tr('title_hint'),
                        icon: Icons.title_rounded,
                        isDark: isDark,
                        textColor: textColor,
                        fieldColor: fieldColor,
                        borderColor: borderColor,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _descriptionController,
                        label: SC.tr('detail_label'),
                        hint: SC.tr('detail_hint'),
                        icon: Icons.description_rounded,
                        maxLines: 6,
                        isDark: isDark,
                        textColor: textColor,
                        fieldColor: fieldColor,
                        borderColor: borderColor,
                      ),
                      const SizedBox(height: 20),
                      _buildImagePicker(isDark, subTextColor, fieldColor, borderColor),
                      const SizedBox(height: 30),
                      _buildSubmitButton(),
                      const SizedBox(height: 20),
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

  Widget _buildHeaderCard(bool isDark, Color textColor, Color subTextColor, Color borderColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.feedback_rounded, color: Colors.cyanAccent, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(SC.tr('tell_us'), style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(SC.tr('feedback_importance'), style: TextStyle(color: subTextColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark, Color textColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(SC.tr('select_type'), style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: ComplaintCategory.values.map((category) {
            final isSelected = _selectedCategory == category;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.cyanAccent.withOpacity(0.15) : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: isSelected ? Colors.cyanAccent : borderColor, width: isSelected ? 2 : 1),
                    ),
                    child: Text(
                      category.banglaName, // আপনি চাইলে SC.tr দিয়ে ক্যাটাগরি কি চেক করতে পারেন
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isSelected ? Colors.cyanAccent : textColor.withOpacity(0.7), fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    required bool isDark,
    required Color textColor,
    required Color fieldColor,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textColor.withOpacity(0.3)),
            prefixIcon: Icon(icon, color: Colors.cyanAccent.withOpacity(0.5)),
            filled: true,
            fillColor: fieldColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder( // এখান থেকে const সরিয়ে দেওয়া হয়েছে
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
            ),
          ),
          validator: (value) => (value == null || value.trim().isEmpty) ? SC.tr('field_required') : null,
        ),
      ],
    );
  }

  Widget _buildImagePicker(bool isDark, Color subTextColor, Color fieldColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(SC.tr('attach_photo'), style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(color: fieldColor, borderRadius: BorderRadius.circular(15), border: Border.all(color: borderColor)),
            child: _imageBytes == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_rounded, color: Colors.cyanAccent.withOpacity(0.5), size: 40),
                const SizedBox(height: 8),
                Text(SC.tr('pick_photo'), style: TextStyle(color: subTextColor, fontSize: 12)),
              ],
            )
                : Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.memory(_imageBytes!, fit: BoxFit.cover)),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedImage = null;
                      _imageBytes = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitComplaint,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: const Color(0xFF0F2027),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F2027))))
            : Text(SC.tr('submit_btn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }
}