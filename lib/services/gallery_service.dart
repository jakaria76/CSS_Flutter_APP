import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gallery_image_model.dart';
import 'cloudinary_service.dart';

class GalleryService {
  final _supabase = Supabase.instance.client;

  // ─── Fetch (with filters) ───────────────────────────────────
  Future<List<GalleryImage>> fetchGallery({
    String?   category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase.from('gallery_images').select();

      if (category != null && category.isNotEmpty && category != 'সব') {
        query = query.eq('category', category);
      }
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((e) => GalleryImage.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('ছবি লোড করতে ব্যর্থ: $e');
    }
  }

  // ─── Upload from PlatformFile (FilePicker) ──────────────────
  Future<String> uploadImage(PlatformFile platformFile) async {
    try {
      if (platformFile.bytes == null) {
        throw Exception('ফাইল পড়া যায়নি');
      }

      final tempDir  = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${platformFile.name}',
      );
      await tempFile.writeAsBytes(platformFile.bytes!);

      final url = await CloudinaryService.uploadImage(
        tempFile,
        folder: CloudinaryService.folderGallery,
      );

      await tempFile.delete();

      if (url == null) throw Exception('Cloudinary upload failed');
      return url;
    } catch (e) {
      throw Exception('ছবি আপলোড করতে ব্যর্থ: $e');
    }
  }

  // ─── Upload from File (Mobile) ──────────────────────────────
  Future<String?> uploadGalleryImage(File imageFile) async {
    return CloudinaryService.uploadImage(
      imageFile,
      folder: CloudinaryService.folderGallery,
    );
  }

  // ─── Batch Upload ───────────────────────────────────────────
  Future<List<String>> uploadMultiple(List<File> imageFiles) async {
    return CloudinaryService.uploadMultipleImages(
      imageFiles,
      folder: CloudinaryService.folderGallery,
    );
  }

  // ─── Add to Database ────────────────────────────────────────
  Future<void> addImageToGallery({
    required String imageUrl,
    required String category,
    String? title,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      await _supabase.from('gallery_images').insert({
        'title'      : title,
        'category'   : category,
        'image_url'  : imageUrl,
        'uploaded_by': userId,
        'created_at' : DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('ডাটাবেসে যোগ করতে ব্যর্থ: $e');
    }
  }

  // ─── Delete (Cloudinary + DB) ────────────────────────────────
  Future<void> deleteImage(String id, String imageUrl) async {
    try {
      // ১. Cloudinary থেকে delete করো
      if (imageUrl.isNotEmpty) {
        await CloudinaryService.deleteFile(imageUrl, resourceType: 'image');
      }

      // ২. DB থেকে delete করো
      await _supabase.from('gallery_images').delete().eq('id', id);
    } catch (e) {
      throw Exception('ছবি মুছতে ব্যর্থ: $e');
    }
  }

  // ─── URL Helpers ────────────────────────────────────────────
  String getThumbnailUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (rawUrl.contains('cloudinary.com')) {
      return CloudinaryService.thumbnailUrl(rawUrl, size: 300);
    }
    return rawUrl;
  }

  String getFullUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (rawUrl.contains('cloudinary.com')) {
      return CloudinaryService.optimizeUrl(rawUrl, width: 1080);
    }
    return rawUrl;
  }

  // ─── Categories ─────────────────────────────────────────────
  Future<List<String>> getCategories() async {
    try {
      final response = await _supabase
          .from('gallery_images')
          .select('category');
      final categories = (response as List)
          .map((e) => e['category'] as String)
          .toSet()
          .toList();
      return ['সব', ...categories];
    } catch (e) {
      return ['সব', 'ইভেন্ট', 'সেমিনার', 'রক্তদান', 'কর্মশালা'];
    }
  }
}