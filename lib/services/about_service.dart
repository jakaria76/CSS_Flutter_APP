// lib/services/about_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/about_models.dart';

class AboutService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 1️⃣ Get Organization Overview
  Future<AboutOverview?> getOverview() async {
    try {
      final response = await _supabase
          .from('about_overview')
          .select()
          .maybeSingle(); // single() এর বদলে maybeSingle() নিরাপদ [cite: 191]

      return response != null ? AboutOverview.fromJson(response) : null;
    } catch (e) {
      debugPrint('Error fetching overview: $e'); // print এর বদলে debugPrint ব্যবহার করুন [cite: 192]
      return null;
    }
  }

  /// 2️⃣ Get Mission Points (ordered)
  Future<List<MissionPoint>> getMissionPoints() async {
    try {
      final response = await _supabase
          .from('about_mission_points')
          .select()
          .order('order_index', ascending: true);

      return (response as List)
          .map((json) => MissionPoint.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching mission points: $e');
      return [];
    }
  }

  /// 3️⃣ Get Activities (ordered)
  Future<List<Activity>> getActivities() async {
    try {
      final response = await _supabase
          .from('about_activities')
          .select()
          .order('order_index', ascending: true);

      return (response as List)
          .map((json) => Activity.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching activities: $e');
      return [];
    }
  }

  /// 4️⃣ Get Story Timeline (ordered by date)
  Future<List<StoryEvent>> getStory() async {
    try {
      final response = await _supabase
          .from('about_story')
          .select()
          .order('event_date', ascending: true);

      return (response as List)
          .map((json) => StoryEvent.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching story: $e');
      return [];
    }
  }

  /// 5️⃣ Get Contact Info
  Future<ContactInfo?> getContactInfo() async {
    try {
      final response = await _supabase
          .from('about_contact')
          .select()
          .maybeSingle();

      return response != null ? ContactInfo.fromJson(response) : null;
    } catch (e) {
      debugPrint('Error fetching contact info: $e');
      return null;
    }
  }

  /// 🔄 Fetch ALL filtered data at once (for efficiency)
  /// এই মেথডটি এখন শুধুমাত্র প্রয়োজনীয় ৫টি সেকশন লোড করবে
  Future<Map<String, dynamic>> getAllAboutData() async {
    try {
      final results = await Future.wait([
        getOverview(),
        getMissionPoints(),
        getActivities(),
        getStory(),
        getContactInfo(),
      ]);

      return {
        'overview': results[0],
        'missionPoints': results[1],
        'activities': results[2],
        'story': results[3],
        'contact': results[4],
      };
    } catch (e) {
      debugPrint('Error fetching all about data: $e');
      return {
        'overview': null,
        'missionPoints': [],
        'activities': [],
        'story': [],
        'contact': null,
      };
    }
  }

  // ==================== ADMIN CRUD METHODS ====================

  /// Add Mission Point
  Future<bool> addMissionPoint(String text, int orderIndex) async {
    try {
      await _supabase.from('about_mission_points').insert({
        'text': text,
        'order_index': orderIndex,
      });
      return true;
    } catch (e) {
      debugPrint('Error adding mission point: $e');
      return false;
    }
  }

  /// Update Mission Point
  Future<bool> updateMissionPoint(int id, String text) async {
    try {
      await _supabase
          .from('about_mission_points')
          .update({'text': text})
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error updating mission point: $e');
      return false;
    }
  }

  /// Generic Delete Method
  Future<bool> deleteAboutItem(String table, int id) async {
    try {
      await _supabase.from(table).delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting item from $table: $e');
      return false;
    }
  }
}