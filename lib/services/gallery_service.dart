import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/models/gallery_image_model.dart';
import 'package:file_picker/file_picker.dart';

class GalleryService {
  final _supabase = Supabase.instance.client;

  /// Fetch gallery images with optional filters
  Future<List<GalleryImage>> fetchGallery({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase.from('gallery_images').select();

      // Filter by category
      if (category != null && category.isNotEmpty && category != 'সব') {
        query = query.eq('category', category);
      }

      // Filter by date range
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((item) => GalleryImage.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('ছবি লোড করতে ব্যর্থ: $e');
    }
  }

  /// Upload image to Supabase Storage
  Future<String> uploadImage(PlatformFile file) async {
    try {
      final bytes = file.bytes;
      if (bytes == null) throw Exception('ফাইল পড়া যায়নি');

      // Create unique filename with date folder structure
      final now = DateTime.now();
      final year = now.year.toString();
      final month = now.month.toString().padLeft(2, '0');
      final timestamp = now.millisecondsSinceEpoch;
      final fileName = '${timestamp}_${file.name}';
      final filePath = 'gallery/$year/$month/$fileName';

      // Upload to Supabase Storage
      await _supabase.storage.from('gallery').uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: false,
        ),
      );

      // Get public URL
      final publicUrl = _supabase.storage.from('gallery').getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('ছবি আপলোড করতে ব্যর্থ: $e');
    }
  }

  /// Add image record to database
  Future<void> addImageToGallery({
    required String imageUrl,
    required String category,
    String? title,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      await _supabase.from('gallery_images').insert({
        'title': title,
        'category': category,
        'image_url': imageUrl,
        'uploaded_by': userId,
      });
    } catch (e) {
      throw Exception('ডাটাবেসে যোগ করতে ব্যর্থ: $e');
    }
  }

  /// Delete image from storage and database
  Future<void> deleteImage(String id, String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final galleryIndex = pathSegments.indexOf('gallery');

      if (galleryIndex != -1 && galleryIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(galleryIndex).join('/');

        // Delete from storage
        await _supabase.storage.from('gallery').remove([filePath]);
      }

      // Delete from database
      await _supabase.from('gallery_images').delete().eq('id', id);
    } catch (e) {
      throw Exception('ছবি মুছতে ব্যর্থ: $e');
    }
  }

  /// Get available categories
  Future<List<String>> getCategories() async {
    try {
      final response = await _supabase
          .from('gallery_images')
          .select('category')
          .order('category');

      final categories = (response as List)
          .map((item) => item['category'] as String)
          .toSet()
          .toList();

      return ['সব', ...categories];
    } catch (e) {
      return ['সব', 'ইভেন্ট', 'সেমিনার', 'কর্মশালা', 'প্রোগ্রাম'];
    }
  }
}
