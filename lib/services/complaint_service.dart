import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/complaint_model.dart';
import 'cloudinary_service.dart';
import 'package:css/pages/SettingsPage/notification_helper.dart';

class ComplaintService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  // ─── 1. Submit New Complaint ────────────────────────────────
  Future<void> submitComplaint({
    required String title,
    required String description,
    required String category,
    XFile? image,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    try {
      String? imageUrl;
      if (image != null) {
        final file = File(image.path);
        imageUrl = await CloudinaryService.uploadImage(
          file,
          folder: CloudinaryService.folderComplaints,
        );
      }

      final result = await _client.from('complaints').insert({
        'user_id'   : userId,
        'title'     : title,
        'description': description,
        'category'  : category,
        'status'    : 'pending',
        'image_url' : imageUrl,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }).select('id').single();

      final complaintId = result['id'] as String;

      final admins = await _client
          .from('profiles')
          .select('id')
          .eq('role', 'admin');

      for (final admin in admins as List) {
        final adminId = admin['id'] as String?;
        if (adminId == null) continue;
        await NotificationHelper.send(
          userId     : adminId,
          titleKey   : 'new_complaint_title',
          bodyKey    : 'new_complaint_body',
          type       : 'complaint',
          complaintId: complaintId,
        );
      }
    } catch (e) {
      debugPrint('Error submitting complaint: $e');
      throw Exception('Failed to submit complaint: $e');
    }
  }

  // ─── 2. Get My Complaints ───────────────────────────────────
  Future<List<Complaint>> getMyComplaints() async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('complaints')
          .select('''
            *,
            profiles!complaints_user_id_fkey (
              full_name,
              profile_image_url
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((item) {
        final profile = item['profiles'];
        return Complaint.fromMap({
          ...item,
          'user_full_name'         : profile?['full_name'],
          'user_profile_image_url' : profile?['profile_image_url'],
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching my complaints: $e');
      throw Exception('Failed to load complaints: $e');
    }
  }

  // ─── 3. Get All Complaints (Admin) ──────────────────────────
  Future<List<Complaint>> getAllComplaints() async {
    try {
      final response = await _client
          .from('complaints')
          .select('''
            *,
            profiles!complaints_user_id_fkey (
              full_name,
              profile_image_url
            )
          ''')
          .order('created_at', ascending: false);

      return (response as List).map((item) {
        final profile = item['profiles'];
        return Complaint.fromMap({
          ...item,
          'user_full_name'         : profile?['full_name'],
          'user_profile_image_url' : profile?['profile_image_url'],
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching all complaints: $e');
      throw Exception('Failed to load complaints: $e');
    }
  }

  // ─── 4. Update Status & Admin Reply ─────────────────────────
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? adminReply,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status'    : status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (adminReply != null) {
        updateData['admin_reply'] = adminReply;
      }

      await _client
          .from('complaints')
          .update(updateData)
          .eq('id', complaintId);

      if (adminReply != null && adminReply.trim().isNotEmpty) {
        final complaint = await _client
            .from('complaints')
            .select('user_id')
            .eq('id', complaintId)
            .single();

        final ownerId = complaint['user_id'] as String?;
        if (ownerId != null) {
          await NotificationHelper.send(
            userId     : ownerId,
            titleKey   : 'complaint_replied_title',
            bodyKey    : 'complaint_replied_body',
            type       : 'complaint_reply',
            complaintId: complaintId,
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating complaint status: $e');
      throw Exception('Failed to update complaint: $e');
    }
  }

  // ─── 5. Update My Complaint ──────────────────────────────────
  Future<void> updateComplaint({
    required String complaintId,
    required String title,
    required String description,
  }) async {
    try {
      await _client.from('complaints').update({
        'title'      : title,
        'description': description,
        'updated_at' : DateTime.now().toUtc().toIso8601String(),
      }).eq('id', complaintId);
    } catch (e) {
      debugPrint('Error editing complaint: $e');
      throw Exception('Failed to edit complaint: $e');
    }
  }

  // ─── 6. Delete Complaint (Cloudinary + DB) ──────────────────
  Future<void> deleteComplaint(String complaintId) async {
    try {
      // ১. image_url fetch করো
      final data = await _client
          .from('complaints')
          .select('image_url')
          .eq('id', complaintId)
          .maybeSingle();

      // ২. Cloudinary থেকে image delete করো
      final imageUrl = data?['image_url'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await CloudinaryService.deleteFile(imageUrl, resourceType: 'image');
      }

      // ৩. DB থেকে delete করো
      await _client.from('complaints').delete().eq('id', complaintId);
    } catch (e) {
      debugPrint('Error deleting complaint: $e');
      throw Exception('Failed to delete complaint: $e');
    }
  }

  // ─── 7. Image URL Helper ────────────────────────────────────
  String getComplaintImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (rawUrl.contains('cloudinary.com')) {
      return CloudinaryService.optimizeUrl(rawUrl, width: 800);
    }
    return rawUrl;
  }
}