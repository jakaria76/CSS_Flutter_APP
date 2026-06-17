import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cloudinary_service.dart';
import '../models/community_application_model.dart';

class CommunityApplicationService {
  final _supabase = Supabase.instance.client;
  final _picker   = ImagePicker();

  // ─── Pick Image (Camera/Gallery) ─────────────────────────────
  Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      return await _picker.pickImage(
        source      : source,
        maxWidth    : 1280,
        maxHeight   : 1280,
        imageQuality: 80,
      );
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // ─── Upload Applicant Photo ───────────────────────────────────
  Future<String> uploadApplicantPhoto(XFile imageFile) async {
    try {
      final file = File(imageFile.path);
      final url  = await CloudinaryService.uploadImage(
        file,
        folder: CloudinaryService.folderCommunityApplications,
      );
      if (url == null) throw Exception('Cloudinary upload failed');
      return url;
    } catch (e) {
      throw Exception('Failed to upload applicant photo: $e');
    }
  }

  // ─── Upload Payment Screenshot ────────────────────────────────
  Future<String> uploadPaymentScreenshot(XFile imageFile) async {
    try {
      final file = File(imageFile.path);
      final url  = await CloudinaryService.uploadImage(
        file,
        folder: CloudinaryService.folderCommunityApplications,
      );
      if (url == null) throw Exception('Cloudinary upload failed');
      return url;
    } catch (e) {
      throw Exception('Failed to upload payment screenshot: $e');
    }
  }

  // ─── Submit Application ───────────────────────────────────────
  Future<void> submitApplication(CommunityApplicationModel application) async {
    try {
      await _supabase
          .from('community_applications')
          .insert(application.toInsertMap());
    } catch (e) {
      throw Exception('Failed to submit application: $e');
    }
  }

  // ─── Check if current user already applied ────────────────────
  Future<CommunityApplicationModel?> getMyApplication() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;
      final data = await _supabase
          .from('community_applications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data == null) return null;
      return CommunityApplicationModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  // ─── Admin: Fetch All Applications ────────────────────────────
  Future<List<CommunityApplicationModel>> fetchAllApplications({
    String? statusFilter,
  }) async {
    try {
      var query = _supabase.from('community_applications').select();
      if (statusFilter != null && statusFilter != 'all') {
        query = query.eq('status', statusFilter);
      }
      final data = await query.order('created_at', ascending: false);
      return (data as List)
          .map((e) => CommunityApplicationModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch applications: $e');
    }
  }

  // ─── Admin: Update Status ─────────────────────────────────────
  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status, // approved | rejected | pending
    String? adminNote,
  }) async {
    try {
      final reviewerId = _supabase.auth.currentUser?.id;
      await _supabase.from('community_applications').update({
        'status':      status,
        'admin_note':  adminNote,
        'reviewed_by': reviewerId,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', applicationId);
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }

  // ─── Admin: Delete Application ─────────────────────────────────
  Future<void> deleteApplication(String applicationId) async {
    try {
      await _supabase
          .from('community_applications')
          .delete()
          .eq('id', applicationId);
    } catch (e) {
      throw Exception('Failed to delete application: $e');
    }
  }
}