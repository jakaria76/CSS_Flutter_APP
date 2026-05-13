import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../models/constitution_model.dart';
import 'cloudinary_service.dart';

class ConstitutionService {
  final _supabase = Supabase.instance.client;

  static const String _folder = 'css_app/constitution';

  // ─── FETCH ALL ────────────────────────────────────────────────
  Future<List<ConstitutionFile>> fetchFiles() async {
    try {
      final data = await _supabase
          .from('constitution_files')
          .select()
          .order('uploaded_at', ascending: false);

      return (data as List)
          .map((e) => ConstitutionFile.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Constitution ফাইল লোড করতে সমস্যা: $e');
    }
  }

  // ─── UPLOAD PDF ───────────────────────────────────────────────
  Future<String?> uploadPdf(PlatformFile file) async {
    try {
      if (file.path == null) {
        debugPrint('File path is null');
        return null;
      }
      return await CloudinaryService.uploadRaw(
        File(file.path!),
        folder: _folder,
      );
    } catch (e) {
      debugPrint('Constitution upload error: $e');
      return null;
    }
  }

  // ─── CREATE ENTRY ─────────────────────────────────────────────
  Future<void> createFile({
    required String name,
    required String pdfUrl,
  }) async {
    try {
      await _supabase.from('constitution_files').insert({
        'name'       : name,
        'pdf_url'    : pdfUrl,
        'uploaded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Constitution যোগ করতে ব্যর্থ: $e');
    }
  }

  // ─── UPDATE NAME ──────────────────────────────────────────────
  Future<void> updateName({
    required String id,
    required String name,
  }) async {
    try {
      await _supabase
          .from('constitution_files')
          .update({'name': name})
          .eq('id', id);
    } catch (e) {
      throw Exception('আপডেট করতে ব্যর্থ: $e');
    }
  }

  // ─── DELETE (Cloudinary + DB) ─────────────────────────────────
  Future<void> deleteFile(String id) async {
    try {
      // 1) DB থেকে pdf_url নাও
      final data = await _supabase
          .from('constitution_files')
          .select('pdf_url')
          .eq('id', id)
          .maybeSingle();

      final fileUrl = data?['pdf_url'] as String?;

      // 2) Cloudinary থেকে permanently delete
      if (fileUrl != null && fileUrl.isNotEmpty) {
        await CloudinaryService.deleteFile(
          fileUrl,
          resourceType: 'raw', // PDF = raw type
        );
      }

      // 3) DB থেকে delete
      await _supabase.from('constitution_files').delete().eq('id', id);
    } catch (e) {
      throw Exception('মুছতে ব্যর্থ: $e');
    }
  }

  // ─── URL FIX ──────────────────────────────────────────────────
  String getViewUrl(String url) {
    if (url.isEmpty) return '';
    return CloudinaryService.rawUrl(url);
  }
}