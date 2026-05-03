import 'dart:io';
import 'package:css/pages/SettingsPage/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:css/services/feed_service.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'feed_widgets.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _captionController = TextEditingController();
  final FeedService           _feedService       = FeedService();
  final ImagePicker           _picker            = ImagePicker();

  List<XFile> _selectedImages = [];
  bool        _isPosting      = false;

  static const _lightBg     = Color(0xFFF0F4FF);
  static const _lightAppBar = Color(0xFFE4ECF9);
  static const _lightText   = Color(0xFF1A2332);

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) setState(() => _selectedImages.addAll(images));
    } catch (e) {
      SC.toast(context, SC.tr('createPostImageError'), SC.red);
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) setState(() => _selectedImages.add(image));
    } catch (e) {
      SC.toast(context, SC.tr('createPostCameraError'), SC.red);
    }
  }

  void _removeImage(int index) =>
      setState(() => _selectedImages.removeAt(index));

  Future<void> _createPost() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty && _selectedImages.isEmpty) {
      SC.toast(context, SC.tr('createPostValidation'), SC.red);
      return;
    }
    setState(() => _isPosting = true);
    try {
      // ── Post তৈরি করো, সব image upload সম্পন্ন হলে postId পাওয়া যাবে ──
      final String postId = await _feedService.createPost(
        caption: caption,
        images: _selectedImages,
      );

      // ✅ FIX: post ও images সম্পূর্ণ DB-তে save হওয়ার পর notification পাঠাও
      // images upload শেষ হলেই createPost return করে, তাই এখানে delay safe
      await Future.delayed(const Duration(milliseconds: 800));

      await NotificationHelper.sendToAll(
        titleKey: 'new_post_title',
        bodyKey:  'new_post_body',
        type:     'new_post',
        postId:   postId,
      );

      if (mounted) {
        Navigator.pop(context, true);
        SC.toast(context, SC.tr('createPostSuccess'), SC.green);
      }
    } catch (e) {
      SC.toast(context, '${SC.tr("createPostError")}$e', SC.red);
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _showImagePickerOptions(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
      isDark ? const Color(0xFF203A43) : const Color(0xFFF0F4FF),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ImagePickerSheet(
        title: SC.tr('feedWidgetPickerTitle'),
        isDark: isDark,
        onGallery: () { Navigator.pop(context); _pickImages(); },
        onCamera:  () { Navigator.pop(context); _pickImageFromCamera(); },
      ),
    );
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
    final isDark      = SC.isDark;
    final bgColor     = isDark ? SC.bgStart : _lightBg;
    final appBarColor = isDark ? const Color(0xFF132D46) : _lightAppBar;
    final textColor   = isDark ? Colors.white : _lightText;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: appBarColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(SC.tr('createPostTitle'),
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: textColor)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _isPosting ? null : _createPost,
                style: TextButton.styleFrom(
                  backgroundColor:
                  _isPosting ? Colors.grey.shade700 : SC.cyan,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isPosting
                    ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : Text(SC.tr('createPostBtn'),
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        body: Stack(children: [
          Positioned(
            bottom: -100, left: -100,
            child: BackgroundOrb(
                color: SC.purple
                    .withValues(alpha: isDark ? 0.05 : 0.04)),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CaptionField(
                  controller: _captionController,
                  hint: SC.tr('createPostHint'),
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
                AddImageButton(
                    isDark: isDark,
                    onTap: () => _showImagePickerOptions(isDark)),
                const SizedBox(height: 20),
                if (_selectedImages.isNotEmpty) ...[
                  SectionLabel(
                    text:
                    '${SC.tr("createPostSelectedImages")} (${_selectedImages.length})',
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.8)
                        : _lightText.withValues(alpha: 0.75),
                  ),
                  const SizedBox(height: 12),
                  ImageGrid(
                    itemCount: _selectedImages.length,
                    imageBuilder: (i) => Image.file(
                      File(_selectedImages[i].path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    onRemove: _removeImage,
                    badge: (i) => NumberBadge(number: i + 1),
                  ),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}