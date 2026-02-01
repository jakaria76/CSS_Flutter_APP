import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/complaint_model.dart';

class ComplaintService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  // =====================================================
  // 1. Submit New Complaint
  // =====================================================
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

      // Upload image if provided
      if (image != null) {
        imageUrl = await _uploadComplaintImage(image);
      }

      // ✅ FIXED: Insert complaint with proper UTC time
      await _client.from('complaints').insert({
        'user_id': userId,
        'title': title,
        'description': description,
        'category': category,
        'status': 'pending',
        'image_url': imageUrl,
        'created_at': DateTime.now().toUtc().toIso8601String(), // ✅ Explicit UTC
      });
    } catch (e) {
      debugPrint('Error submitting complaint: $e');
      throw Exception('Failed to submit complaint: $e');
    }
  }

  // =====================================================
  // 2. Get My Complaints (Current User)
  // =====================================================
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
          'user_full_name': profile?['full_name'],
          'user_profile_image_url': profile?['profile_image_url'],
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching my complaints: $e');
      throw Exception('Failed to load complaints: $e');
    }
  }

  // =====================================================
  // 3. Get All Complaints (Admin)
  // =====================================================
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
          'user_full_name': profile?['full_name'],
          'user_profile_image_url': profile?['profile_image_url'],
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching all complaints: $e');
      throw Exception('Failed to load complaints: $e');
    }
  }

  // =====================================================
  // 4. Update Complaint Status (Admin)
  // =====================================================
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? adminReply,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(), // ✅ Explicit UTC
      };

      if (adminReply != null) {
        updateData['admin_reply'] = adminReply;
      }

      await _client
          .from('complaints')
          .update(updateData)
          .eq('id', complaintId);
    } catch (e) {
      debugPrint('Error updating complaint: $e');
      throw Exception('Failed to update complaint: $e');
    }
  }

  // =====================================================
  // 5. Upload Complaint Image (WEB + MOBILE SAFE)
  // =====================================================
  Future<String> _uploadComplaintImage(XFile image) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    try {
      final bytes = await image.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$userId/complaint_$timestamp.jpg';

      await _client.storage.from('complaint-images').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );

      return _client.storage.from('complaint-images').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // =====================================================
  // 6. Delete Complaint
  // =====================================================
  Future<void> deleteComplaint(String complaintId) async {
    try {
      await _client.from('complaints').delete().eq('id', complaintId);
    } catch (e) {
      debugPrint('Error deleting complaint: $e');
      throw Exception('Failed to delete complaint: $e');
    }
  }
}