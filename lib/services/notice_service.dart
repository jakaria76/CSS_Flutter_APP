import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../models/notice_model.dart';
import 'cloudinary_service.dart';

class NoticeService {
  final _supabase = Supabase.instance.client;

  // ─── FETCH NOTICES ───────────────────────────────────────────
  Future<List<Notice>> fetchNotices() async {
    try {
      final data = await _supabase
          .from('notices')
          .select()
          .order('publish_date', ascending: false);

      return (data as List)
          .map((e) => Notice.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('বিজ্ঞপ্তি লোড করতে সমস্যা হয়েছে: $e');
    }
  }

  // ─── UPLOAD FILE ─────────────────────────────────────────────
  Future<String?> uploadNoticeFile(PlatformFile file) async {
    try {
      if (file.path == null) {
        debugPrint('File path is null — cannot upload');
        return null;
      }

      final fileToUpload = File(file.path!);
      final ext = (file.extension ?? '').toLowerCase();
      final isImage = ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext);

      if (isImage) {
        return CloudinaryService.uploadImage(
          fileToUpload,
          folder: '${CloudinaryService.folderNotices}/images',
        );
      } else {
        return CloudinaryService.uploadRaw(
          fileToUpload,
          folder: '${CloudinaryService.folderNotices}/docs',
        );
      }
    } catch (e) {
      debugPrint('Notice file upload error: $e');
      return null;
    }
  }

  // ─── CREATE NOTICE ───────────────────────────────────────────
  Future<void> createNotice({
    required String title,
    required DateTime publishDate,
    String? fileUrl,
  }) async {
    try {
      await _supabase.from('notices').insert({
        'title'       : title,
        'publish_date': publishDate.toIso8601String(),
        'pdf_url'     : fileUrl,
      });
    } catch (e) {
      throw Exception('বিজ্ঞপ্তি যোগ করতে ব্যর্থ: $e');
    }
  }

  // ─── UPDATE NOTICE ───────────────────────────────────────────
  Future<void> updateNotice({
    required String id,
    required String title,
    required DateTime publishDate,
    String? fileUrl,
  }) async {
    try {
      await _supabase.from('notices').update({
        'title'       : title,
        'publish_date': publishDate.toIso8601String(),
        'pdf_url'     : fileUrl,
      }).eq('id', id);
    } catch (e) {
      throw Exception('আপডেট করতে ব্যর্থ: $e');
    }
  }

  // ─── DELETE NOTICE (Cloudinary + DB) ─────────────────────────
  // ─── DELETE NOTICE (Cloudinary + DB) ─────────────────────────
  Future<void> deleteNotice(String id) async {
    try {
      final data = await _supabase
          .from('notices')
          .select('pdf_url')
          .eq('id', id)
          .maybeSingle();

      final fileUrl = data?['pdf_url'] as String?;
      if (fileUrl != null && fileUrl.isNotEmpty) {
        // raw/upload থাকলে raw, নইলে image
        final isRaw = fileUrl.contains('/raw/upload/') ||
            fileUrl.contains('/notices/docs/');
        await CloudinaryService.deleteFile(
          fileUrl,
          resourceType: isRaw ? 'raw' : 'image',
        );
      }

      await _supabase.from('notices').delete().eq('id', id);
    } catch (e) {
      throw Exception('মুছতে ব্যর্থ হয়েছে: $e');
    }
  }

  // ─── URL HELPER ──────────────────────────────────────────────
  String getNoticeFileUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (!url.contains('cloudinary.com')) return url;

    final ext = url.split('.').last.split('?').first.toLowerCase();
    final isDoc = ['pdf', 'doc', 'docx', 'txt'].contains(ext) ||
        url.contains('/notices/docs/') ||
        url.contains('/raw/upload/');

    if (isDoc) return CloudinaryService.rawUrl(url);
    return CloudinaryService.optimizeUrl(url, width: 800);
  }
}