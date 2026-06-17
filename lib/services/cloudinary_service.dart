import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CloudinaryService {
  static const String _cloudName    = "dgfyu4ex7";
  static const String _uploadPreset = "css_preset";

  // ─── Folder Paths ─────────────────────────────────────────────
  static const String folderProfiles              = 'css_app/profiles';
  static const String folderEvents                = 'css_app/events';
  static const String folderGallery               = 'css_app/gallery';
  static const String folderBanners               = 'css_app/banners';
  static const String folderPosts                 = 'css_app/posts';
  static const String folderVideos                = 'css_app/video_thumbnails';
  static const String folderComplaints            = 'css_app/complaints';
  static const String folderNotices               = 'css_app/notices';
  static const String folderPayments              = 'css_app/payments';
  static const String folderCommunityApplications = 'css_app/community_applications'; // ✅ Fixed

  static final _cloudinary =
  CloudinaryPublic(_cloudName, _uploadPreset, cache: false);

  // ─── Single Upload (image) ───────────────────────────────────
  static Future<String?> uploadImage(
      File file, {
        String folder = 'css_app/general',
      }) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      debugPrint('Cloudinary image upload error: $e');
      return null;
    }
  }

  // ─── Raw Upload (PDF / DOC / TXT) ────────────────────────────
  static Future<String?> uploadRaw(
      File file, {
        String folder = 'css_app/notices/docs',
      }) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Raw,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      debugPrint('Cloudinary raw upload error: $e');
      return null;
    }
  }

  // ─── Multiple Upload (parallel) ──────────────────────────────
  static Future<List<String>> uploadMultipleImages(
      List<File> files, {
        String folder = 'css_app/gallery',
      }) async {
    final futures = files.map((f) => uploadImage(f, folder: folder)).toList();
    final results = await Future.wait(futures);
    return results.whereType<String>().toList();
  }

  // ─── URL Optimization (image only) ───────────────────────────
  static String optimizeUrl(
      String url, {
        int?   width,
        int?   height,
        String quality = 'auto',
        String format  = 'auto',
      }) {
    if (!url.contains('cloudinary.com')) return url;
    String t = 'q_$quality,f_$format';
    if (width  != null) t += ',w_$width';
    if (height != null) t += ',h_$height,c_fill';
    return url.replaceFirst('/image/upload/', '/image/upload/$t/');
  }

  // ─── Raw URL fix ──────────────────────────────────────────────
  static String rawUrl(String url) {
    if (!url.contains('cloudinary.com')) return url;
    if (url.contains('/image/upload/')) {
      return url.replaceFirst('/image/upload/', '/raw/upload/');
    }
    if (url.contains('/upload/fl_attachment/')) {
      return url.replaceFirst('/upload/fl_attachment/', '/raw/upload/');
    }
    return url;
  }

  static String thumbnailUrl(String url, {int size = 200}) =>
      optimizeUrl(url, width: size, height: size);

  static String profileUrl(String url, {int size = 150}) =>
      optimizeUrl(url, width: size, height: size);

  // ─── Extract Public ID (URL থেকে) ────────────────────────────
  static String? extractPublicId(String url) {
    try {
      final uri         = Uri.parse(url);
      final parts       = uri.pathSegments;
      final uploadIndex = parts.indexOf('upload');
      if (uploadIndex == -1) return null;

      var remaining = parts.sublist(uploadIndex + 1);

      // transformation segments বাদ দাও (যেমন q_auto,f_auto,w_800)
      while (remaining.isNotEmpty &&
          (remaining.first.contains('_') || remaining.first.contains(',')) &&
          !remaining.first.startsWith('css_app') &&
          !remaining.first.startsWith('v')) {
        remaining = remaining.sublist(1);
      }

      // version segment বাদ দাও (v দিয়ে শুরু, বাকি সব digit)
      if (remaining.isNotEmpty &&
          remaining.first.startsWith('v') &&
          int.tryParse(remaining.first.substring(1)) != null) {
        remaining = remaining.sublist(1);
      }

      final withExt = remaining.join('/');

      // ✅ raw file হলে extension সহ return করো
      // image হলে extension বাদ দাও
      final ext   = withExt.split('.').last.toLowerCase();
      final isRaw = ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'pptx']
          .contains(ext);

      if (isRaw) return withExt;

      final dotIndex = withExt.lastIndexOf('.');
      return dotIndex != -1 ? withExt.substring(0, dotIndex) : withExt;
    } catch (_) {
      return null;
    }
  }

  // ─── Delete (Supabase Edge Function দিয়ে) ────────────────────
  static Future<bool> deleteFile(
      String cloudinaryUrl, {
        String resourceType = 'image',
      }) async {
    try {
      final publicId = extractPublicId(cloudinaryUrl);
      if (publicId == null || publicId.isEmpty) {
        debugPrint('Could not extract publicId from: $cloudinaryUrl');
        return false;
      }

      debugPrint('Deleting from Cloudinary — publicId: $publicId, type: $resourceType');

      final response = await Supabase.instance.client.functions.invoke(
        'delete-cloudinary',
        body: {
          'publicId'    : publicId,
          'resourceType': resourceType,
        },
      );

      final result  = response.data as Map<String, dynamic>?;
      final success = result?['result'] == 'ok';
      debugPrint('Cloudinary delete result: $result');
      return success;
    } catch (e) {
      debugPrint('Cloudinary delete error: $e');
      return false;
    }
  }
}