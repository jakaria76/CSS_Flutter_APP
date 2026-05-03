import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:css/services/feed_service.dart';
import 'package:css/models/post_model.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';
import 'feed_widgets.dart';

class ManagePostPage extends StatefulWidget {
  final Post post;
  const ManagePostPage({super.key, required this.post});

  @override
  State<ManagePostPage> createState() => _ManagePostPageState();
}

class _ManagePostPageState extends State<ManagePostPage> {
  final TextEditingController _captionController = TextEditingController();
  final FeedService           _feedService       = FeedService();
  final ImagePicker           _picker            = ImagePicker();

  List<String> _existingImages  = [];
  List<XFile>  _newImages       = [];
  List<String> _imagesToDelete  = [];
  bool         _isUpdating      = false;
  bool         _isDeleting      = false;

  static const _lightBg     = Color(0xFFF0F4FF);
  static const _lightAppBar = Color(0xFFE4ECF9);
  static const _lightText   = Color(0xFF1A2332);

  @override
  void initState() {
    super.initState();
    _captionController.text = widget.post.caption;
    _existingImages = List.from(widget.post.images);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) setState(() => _newImages.addAll(images));
    } catch (e) {
      SC.toast(context, SC.tr('createPostImageError'), SC.red);
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image =
      await _picker.pickImage(source: ImageSource.camera);
      if (image != null) setState(() => _newImages.add(image));
    } catch (e) {
      SC.toast(context, SC.tr('createPostCameraError'), SC.red);
    }
  }

  void _removeExistingImage(String imageUrl) => setState(() {
    _existingImages.remove(imageUrl);
    _imagesToDelete.add(imageUrl);
  });

  void _removeNewImage(int index) =>
      setState(() => _newImages.removeAt(index));

  Future<void> _updatePost() async {
    setState(() => _isUpdating = true);
    try {
      await _feedService.updatePost(
        postId:         widget.post.id,
        caption:        _captionController.text.trim(),
        newImages:      _newImages,
        imagesToDelete: _imagesToDelete,
      );
      if (mounted) {
        Navigator.pop(context, true);
        SC.toast(context, SC.tr('managePostUpdated'), SC.green);
      }
    } catch (e) {
      SC.toast(context, '${SC.tr('managePostUpdateError')}$e', SC.red);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _deletePost() async {
    final confirmed = await _showConfirmDialog(
      title:        SC.tr('managePostDeleteTitle'),
      content:      SC.tr('managePostDeleteContent'),
      confirmLabel: SC.tr('managePostDeleteConfirm'),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await _feedService.deletePost(widget.post.id);
      if (mounted) {
        Navigator.pop(context, true);
        SC.toast(context, SC.tr('managePostDeleted'), SC.green);
      }
    } catch (e) {
      SC.toast(context, '${SC.tr('managePostDeleteError')}$e', SC.red);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
  }) {
    final isDark    = SC.isDark;
    final dialogBg  = isDark ? const Color(0xFF203A43) : const Color(0xFFF0F4FF);
    final textColor = isDark ? Colors.white : _lightText;
    final subColor  = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : _lightText.withValues(alpha: 0.6);

    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(color: textColor)),
        content: Text(content, style: TextStyle(color: subColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(SC.tr('managePostCancel'),
                style: TextStyle(color: SC.cyan)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
      isDark ? const Color(0xFF203A43) : const Color(0xFFF0F4FF),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ImagePickerSheet(
        title: SC.tr('managePostAddImage'),
        isDark: isDark,
        onGallery: () { Navigator.pop(context); _pickImages(); },
        onCamera:  () { Navigator.pop(context); _pickImageFromCamera(); },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════
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
    final bgColor     = isDark ? SC.bgStart      : _lightBg;
    final appBarColor = isDark ? const Color(0xFF132D46) : _lightAppBar;
    final textColor   = isDark ? Colors.white    : _lightText;
    final subColor    = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : _lightText.withValues(alpha: 0.5);
    final totalImages = _existingImages.length + _newImages.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: appBarColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(SC.tr('managePostTitle'),
              style: TextStyle(
                fontWeight: FontWeight.bold, color: textColor,
              )),
          actions: [
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.redAccent))
                  : const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _isDeleting ? null : _deletePost,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _isUpdating ? null : _updatePost,
                style: TextButton.styleFrom(
                  backgroundColor:
                  _isUpdating ? Colors.grey.shade700 : SC.cyan,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isUpdating
                    ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : Text(SC.tr('managePostSave'),
                    style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold,
                    )),
              ),
            ),
          ],
        ),
        body: Stack(children: [
          Positioned(
            bottom: -100, left: -100,
            child: BackgroundOrb(
                color: SC.purple.withValues(alpha: isDark ? 0.05 : 0.04)),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CaptionField(
                  controller: _captionController,
                  hint: SC.tr('managePostCaptionHint'),
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
                AddImageButton(
                  isDark: isDark,
                  label: SC.tr('managePostAddImage'),
                  onTap: () => _showImagePickerOptions(isDark),
                ),
                const SizedBox(height: 20),

                // Existing images
                if (_existingImages.isNotEmpty) ...[
                  SectionLabel(
                    text: '${SC.tr('managePostExistingImages')} (${_existingImages.length})',
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.8)
                        : _lightText.withValues(alpha: 0.75),
                  ),
                  const SizedBox(height: 12),
                  ImageGrid(
                    itemCount: _existingImages.length,
                    imageBuilder: (i) => Image.network(
                      _existingImages[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (_, child, progress) =>
                      progress == null
                          ? child
                          : Container(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                        child: Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: SC.cyan),
                        ),
                      ),
                    ),
                    onRemove: (i) =>
                        _removeExistingImage(_existingImages[i]),
                  ),
                  const SizedBox(height: 20),
                ],

                // New images
                if (_newImages.isNotEmpty) ...[
                  SectionLabel(
                    text: '${SC.tr('managePostNewImages')} (${_newImages.length})',
                    color: SC.cyan.withValues(alpha: 0.9),
                  ),
                  const SizedBox(height: 12),
                  ImageGrid(
                    itemCount: _newImages.length,
                    imageBuilder: (i) => Image.file(
                      File(_newImages[i].path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    onRemove: _removeNewImage,
                    badge: (_) => const NewBadge(),
                  ),
                ],

                // Warning
                if (totalImages == 0) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange.shade300),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          SC.tr('managePostWarning'),
                          style: TextStyle(
                              color: Colors.orange.shade300, fontSize: 13),
                        ),
                      ),
                    ]),
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