import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/banner_model.dart';

class BannerService {
  final supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  // ✅ Fetch all active banners (sorted by sort_order)
  Future<List<BannerModel>> fetchBanners() async {
    try {
      final response = await supabase
          .from('banners')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((e) => BannerModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch banners: $e');
    }
  }

  // ✅ Fetch all banners (including inactive - for admin)
  Future<List<BannerModel>> fetchAllBanners() async {
    try {
      final response = await supabase
          .from('banners')
          .select()
          .order('sort_order', ascending: true);

      return (response as List)
          .map((e) => BannerModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all banners: $e');
    }
  }

  // ✅ Upload image to Supabase Storage
  Future<String> uploadBannerImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'banners/$fileName';

      await supabase.storage.from('banners').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: false,
        ),
      );

      final publicUrl = supabase.storage.from('banners').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // ✅ Create new banner
  Future<void> createBanner({
    required String imageUrl,
    String? title,
    String? subtitle,
    String? linkUrl,
    int sortOrder = 0,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;

      await supabase.from('banners').insert({
        'image_url': imageUrl,
        'title': title,
        'subtitle': subtitle,
        'link_url': linkUrl,
        'sort_order': sortOrder,
        'is_active': true,
        'created_by': userId,
      });
    } catch (e) {
      throw Exception('Failed to create banner: $e');
    }
  }

  // ✅ Update banner
  Future<void> updateBanner(BannerModel banner) async {
    try {
      await supabase.from('banners').update({
        'title': banner.title,
        'subtitle': banner.subtitle,
        'link_url': banner.linkUrl,
        'sort_order': banner.sortOrder,
        'is_active': banner.isActive,
      }).eq('id', banner.id);
    } catch (e) {
      throw Exception('Failed to update banner: $e');
    }
  }

  // ✅ Toggle banner active status
  Future<void> toggleBannerStatus(String id, bool isActive) async {
    try {
      await supabase
          .from('banners')
          .update({'is_active': isActive}).eq('id', id);
    } catch (e) {
      throw Exception('Failed to toggle banner status: $e');
    }
  }

  // ✅ Delete banner (including storage file)
  Future<void> deleteBanner(String id, String imageUrl) async {
    try {
      // Extract file path from public URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final bannerIndex = pathSegments.indexOf('banners');

      if (bannerIndex != -1 && bannerIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(bannerIndex).join('/');

        // Delete from storage
        await supabase.storage.from('banners').remove([filePath]);
      }

      // Delete from database
      await supabase.from('banners').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete banner: $e');
    }
  }

  // ✅ Pick image from gallery
  Future<XFile?> pickImage() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // ✅ Reorder banners
  Future<void> reorderBanners(List<BannerModel> banners) async {
    try {
      for (int i = 0; i < banners.length; i++) {
        await supabase
            .from('banners')
            .update({'sort_order': i})
            .eq('id', banners[i].id);
      }
    } catch (e) {
      throw Exception('Failed to reorder banners: $e');
    }
  }
}