import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileService {
  // =====================================================
  // Supabase client
  // =====================================================
  final SupabaseClient _client = Supabase.instance.client;

  // =====================================================
  // Current logged-in user id
  // =====================================================
  String? get currentUserId => _client.auth.currentUser?.id;

  // =====================================================
  // 1. নিজের প্রোফাইল পাওয়ার ফাংশন (Current User)
  // =====================================================
  Future<ProfileModel?> getProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final Map<String, dynamic>? data = await _client
          .from('profiles')
          .select('*')            // ✅ সব কলাম ফেচ করবে
          .eq('id', userId)       // ✅ প্রাইমারি কি (auth uid)
          .maybeSingle();         // ✅ রো না থাকলে ক্র্যাশ করবে না

      if (data == null) return null;

      return ProfileModel.fromMap(data); // ProfileModel এ fromMap মেথড থাকতে হবে
    } catch (e) {
      debugPrint('Error loading own profile: $e');
      throw Exception('Failed to load profile: $e');
    }
  }

  // =====================================================
  // 2. আইডি দিয়ে নির্দিষ্ট কোনো ডোনারের প্রোফাইল পাওয়ার ফাংশন
  // =====================================================
  Future<ProfileModel?> getProfileById(String userId) async {
    try {
      final Map<String, dynamic>? data = await _client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;

      return ProfileModel.fromMap(data);
    } catch (e) {
      debugPrint('Error fetching profile by ID: $e');
      return null;
    }
  }

  // =====================================================
  // 3. প্রোফাইল আছে কি না চেক করা (Login এর পর)
  // =====================================================
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

  // =====================================================
  // 4. প্রোফাইল তৈরি বা আপডেট (UPSERT)
  // =====================================================
  Future<void> saveProfile(ProfileModel profile) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final Map<String, dynamic> payload = profile.toMap();

      payload['id'] = userId; // 🔥 সঠিক ইউজারের আইডি নিশ্চিত করা
      payload['last_updated_date'] = DateTime.now().toIso8601String();

      await _client.from('profiles').upsert(
        payload,
        onConflict: 'id', // 🔥 আইডি কনফ্লিক্ট হলে আপডেট করবে
      );
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  // =====================================================
  // 5. শুধুমাত্র নির্দিষ্ট কিছু ফিল্ড আপডেট করা
  // =====================================================
  Future<void> updateProfileFields(Map<String, dynamic> fields) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      fields['last_updated_date'] = DateTime.now().toIso8601String();

      await _client
          .from('profiles')
          .update(fields)
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update profile fields: $e');
    }
  }

  // =====================================================
  // 6. প্রোফাইল ইমেজ আপলোড (WEB + MOBILE SAFE)
  // =====================================================
  Future<String> uploadProfileImage({
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final filePath = '$userId/profile.jpg';

      // 🔥 বাইনারি আপলোড (Web and Mobile compatible)
      await _client.storage
          .from('profile-images')
          .uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: contentType,
        ),
      );

      // 🔥 পাবলিক URL সংগ্রহ
      final String publicUrl = _client.storage
          .from('profile-images')
          .getPublicUrl(filePath);

      // 🔥 প্রোফাইল টেবিলে URL সেভ করা
      await updateProfileFields({
        'profile_image_url': publicUrl,
      });

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // =====================================================
  // 7. প্রোফাইল ডিলিট করা
  // =====================================================
  Future<void> deleteProfile() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _client.from('profiles').delete().eq('id', userId);
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }
}