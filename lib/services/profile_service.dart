import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/member_type.dart';
import 'cloudinary_service.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  // ─── 1. নিজের প্রোফাইল ─────────────────────────────────────
  Future<ProfileModel?> getProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;
    return getProfileById(userId);
  }

  // ─── 2. ID দিয়ে প্রোফাইল ──────────────────────────────────
  Future<ProfileModel?> getProfileById(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();
      return data != null ? ProfileModel.fromMap(data) : null;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  // ─── 3. প্রোফাইল আছে কিনা চেক ─────────────────────────────
  Future<bool> profileExists() async {
    final userId = currentUserId;
    if (userId == null) return false;
    try {
      final data = await _client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      return data != null;
    } catch (_) {
      return false;
    }
  }

  // ─── 4. প্রোফাইল Save / Upsert ─────────────────────────────
  Future<void> saveProfile(ProfileModel profile) async {
    try {
      final payload = profile.toMap();
      payload['updated_at'] = DateTime.now().toUtc().toIso8601String();
      if (profile.id.isEmpty) {
        final userId = currentUserId;
        if (userId == null) return;
        payload['id'] = userId;
      }
      await _client.from('profiles').upsert(payload, onConflict: 'id');
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  // ─── 5. নির্দিষ্ট Field আপডেট ─────────────────────────────
  Future<void> updateProfileFields(Map<String, dynamic> fields) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      fields['updated_at'] = DateTime.now().toUtc().toIso8601String();
      await _client.from('profiles').update(fields).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update profile fields: $e');
    }
  }

  // ─── 6. প্রোফাইল ছবি Upload — Cloudinary only ─────────────
  Future<String?> uploadProfileImageFile(File file) async {
    if (currentUserId == null) throw Exception('User not logged in');
    try {
      // পুরনো ছবি delete করো
      final profile = await getProfile();
      final oldUrl = profile?.profileImageUrl;
      if (oldUrl != null && oldUrl.isNotEmpty) {
        await CloudinaryService.deleteFile(oldUrl, resourceType: 'image');
      }

      final imageUrl = await CloudinaryService.uploadImage(
        file,
        folder: CloudinaryService.folderProfiles,
      );
      if (imageUrl != null) {
        await updateProfileFields({'profile_image_url': imageUrl});
      }
      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // ─── 7. Image URL Helper ────────────────────────────────────
  String getProfileImageUrl(String? rawUrl, {int size = 150}) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (rawUrl.contains('cloudinary.com')) {
      return CloudinaryService.profileUrl(rawUrl, size: size);
    }
    return rawUrl;
  }

  // ─── 8. Committee & Advisor Fetching ───────────────────────
  Future<List<ProfileModel>> getPresentCommittee() async =>
      _fetchByMemberType(MemberType.presentCommittee, 'committee_position');

  Future<List<ProfileModel>> getAdvisors() async =>
      _fetchByMemberType(MemberType.advisor, 'full_name');

  Future<List<ProfileModel>> getPreviousCommittee() async =>
      _fetchByMemberType(MemberType.previousCommittee, 'tenure_to',
          ascending: false);

  Future<List<ProfileModel>> _fetchByMemberType(
      String type,
      String orderField, {
        bool ascending = true,
      }) async {
    try {
      final data = await _client
          .from('profiles')
          .select('*')
          .eq('member_type', type)
          .eq('account_status', 'active')
          .order(orderField, ascending: ascending);
      return (data as List)
          .map((e) => ProfileModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching $type: $e');
      return [];
    }
  }

  // ─── 9. প্রোফাইল Delete (Cloudinary + DB) ──────────────────
  Future<void> deleteProfile() async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      // profile image Cloudinary থেকে delete করো
      final profile = await getProfile();
      final imageUrl = profile?.profileImageUrl;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await CloudinaryService.deleteFile(imageUrl, resourceType: 'image');
      }

      await _client.from('profiles').delete().eq('id', userId);
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }

  // ─── 10. Admin: Profile Create ─────────────────────────────
  Future<ProfileModel?> adminCreateProfile({
    required String fullName,
    String? fullNameBn,
    required String memberType,
    String? profileImageUrl,
    String? committeePosition,
    String? previousPosition,
    int?    tenureFrom,
    int?    tenureTo,
    String? previousCommitteeNote,
    String? occupation,
    String? institution,
    String? designation,
    String? expertise,
    String? advisorNote,
  }) async {
    try {
      final map = <String, dynamic>{
        'full_name'               : fullName,
        'full_name_bn'            : fullNameBn,
        'member_type'             : memberType,
        'profile_image_url'       : profileImageUrl,
        'account_status'          : 'active',
        'committee_position'      : committeePosition,
        'previous_position'       : previousPosition,
        'tenure_from'             : tenureFrom,
        'tenure_to'               : tenureTo,
        'previous_committee_note' : previousCommitteeNote,
        'occupation'              : occupation,
        'institution'             : institution,
        'designation'             : designation,
        'expertise'               : expertise,
        'advisor_note'            : advisorNote,
        'updated_at'              : DateTime.now().toUtc().toIso8601String(),
      };
      map.removeWhere((_, v) => v == null);

      final result = await _client
          .from('profiles')
          .insert(map)
          .select()
          .single();
      return ProfileModel.fromMap(result);
    } catch (e) {
      debugPrint('Admin create error: $e');
      throw Exception('Failed to create profile: $e');
    }
  }

  // ─── 11. Admin: যেকোনো ID দিয়ে Delete (Cloudinary + DB) ───
  Future<void> adminDeleteProfile(String id) async {
    try {
      // profile image Cloudinary থেকে delete করো
      final profile = await getProfileById(id);
      final imageUrl = profile?.profileImageUrl;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await CloudinaryService.deleteFile(imageUrl, resourceType: 'image');
      }

      await _client.from('profiles').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }
}