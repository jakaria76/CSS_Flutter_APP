import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/banner_model.dart';
import 'cloudinary_service.dart';

class BannerService {
  final _supabase = Supabase.instance.client;
  final _picker   = ImagePicker();

  // ─── Fetch ──────────────────────────────────────────────────
  Future<List<BannerModel>> fetchBanners() async {
    try {
      final response = await _supabase
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

  Future<List<BannerModel>> fetchAllBanners() async {
    try {
      final response = await _supabase
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

  // ─── Pick Image ─────────────────────────────────────────────
  Future<XFile?> pickImage() async {
    try {
      return await _picker.pickImage(
        source      : ImageSource.gallery,
        maxWidth    : 1920,
        maxHeight   : 1080,
        imageQuality: 85,
      );
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // ─── Upload Banner ───────────────────────────────────────────
  Future<String> uploadBannerImage(XFile imageFile) async {
    try {
      final file = File(imageFile.path);
      final url  = await CloudinaryService.uploadImage(
        file,
        folder: CloudinaryService.folderBanners,
      );
      if (url == null) throw Exception('Cloudinary upload failed');
      return url;
    } catch (e) {
      throw Exception('Failed to upload banner image: $e');
    }
  }

  // ─── Create Banner ──────────────────────────────────────────
  Future<void> createBanner({
    required String imageUrl,
    String? title,
    String? subtitle,
    String? linkUrl,
    int sortOrder = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      await _supabase.from('banners').insert({
        'image_url' : imageUrl,
        'title'     : title,
        'subtitle'  : subtitle,
        'link_url'  : linkUrl,
        'sort_order': sortOrder,
        'is_active' : true,
        'created_by': userId,
      });
    } catch (e) {
      throw Exception('Failed to create banner: $e');
    }
  }

  // ─── Update ─────────────────────────────────────────────────
  Future<void> updateBanner(BannerModel banner) async {
    try {
      await _supabase.from('banners').update({
        'title'     : banner.title,
        'subtitle'  : banner.subtitle,
        'link_url'  : banner.linkUrl,
        'sort_order': banner.sortOrder,
        'is_active' : banner.isActive,
      }).eq('id', banner.id);
    } catch (e) {
      throw Exception('Failed to update banner: $e');
    }
  }

  // ─── Toggle Active ──────────────────────────────────────────
  Future<void> toggleBannerStatus(String id, bool isActive) async {
    try {
      await _supabase
          .from('banners')
          .update({'is_active': isActive})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to toggle banner status: $e');
    }
  }

  // ─── Delete Banner (Cloudinary + DB) ────────────────────────
  Future<void> deleteBanner(String id, String imageUrl) async {
    try {
      // ১. Cloudinary থেকে আগে delete করো
      if (imageUrl.isNotEmpty) {
        await CloudinaryService.deleteFile(imageUrl, resourceType: 'image');
      }

      // ২. DB থেকে delete করো
      await _supabase.from('banners').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete banner: $e');
    }
  }

  // ─── Reorder ────────────────────────────────────────────────
  Future<void> reorderBanners(List<BannerModel> banners) async {
    try {
      for (int i = 0; i < banners.length; i++) {
        await _supabase
            .from('banners')
            .update({'sort_order': i})
            .eq('id', banners[i].id);
      }
    } catch (e) {
      throw Exception('Failed to reorder banners: $e');
    }
  }

  // ─── URL Helper ─────────────────────────────────────────────
  String getBannerUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (rawUrl.contains('cloudinary.com')) {
      return CloudinaryService.optimizeUrl(rawUrl, width: 800);
    }
    return rawUrl;
  }
}