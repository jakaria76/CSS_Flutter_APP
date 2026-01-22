// lib/services/about_service.dart

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
          .single();

      return AboutOverview.fromJson(response);
    } catch (e) {
      print('Error fetching overview: $e');
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
      print('Error fetching mission points: $e');
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
      print('Error fetching activities: $e');
      return [];
    }
  }

  /// 4️⃣ Get Advisors (ordered)
  Future<List<Advisor>> getAdvisors() async {
    try {
      final response = await _supabase
          .from('about_advisors')
          .select()
          .order('order_index', ascending: true);

      return (response as List)
          .map((json) => Advisor.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching advisors: $e');
      return [];
    }
  }

  /// 5️⃣ Get Previous Presidents (ordered)
  Future<List<PreviousPresident>> getPreviousPresidents() async {
    try {
      final response = await _supabase
          .from('about_previous_presidents')
          .select()
          .order('order_index', ascending: true);

      return (response as List)
          .map((json) => PreviousPresident.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching previous presidents: $e');
      return [];
    }
  }

  /// 6️⃣ Get Current Leadership (ordered)
  Future<List<Leadership>> getLeadership() async {
    try {
      final response = await _supabase
          .from('about_leadership')
          .select()
          .order('order_index', ascending: true);

      return (response as List)
          .map((json) => Leadership.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching leadership: $e');
      return [];
    }
  }

  /// 7️⃣ Get Story Timeline (ordered by date)
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
      print('Error fetching story: $e');
      return [];
    }
  }

  /// 8️⃣ Get Contact Info
  Future<ContactInfo?> getContactInfo() async {
    try {
      final response = await _supabase
          .from('about_contact')
          .select()
          .single();

      return ContactInfo.fromJson(response);
    } catch (e) {
      print('Error fetching contact info: $e');
      return null;
    }
  }

  /// 🔄 Fetch ALL data at once (for efficiency)
  Future<Map<String, dynamic>> getAllAboutData() async {
    try {
      final results = await Future.wait([
        getOverview(),
        getMissionPoints(),
        getActivities(),
        getAdvisors(),
        getPreviousPresidents(),
        getLeadership(),
        getStory(),
        getContactInfo(),
      ]);

      return {
        'overview': results[0],
        'missionPoints': results[1],
        'activities': results[2],
        'advisors': results[3],
        'previousPresidents': results[4],
        'leadership': results[5],
        'story': results[6],
        'contact': results[7],
      };
    } catch (e) {
      print('Error fetching all about data: $e');
      return {};
    }
  }

  // ==================== ADMIN METHODS (Future use) ====================

  /// Add Mission Point (Admin only)
  Future<bool> addMissionPoint(String text, int orderIndex) async {
    try {
      await _supabase.from('about_mission_points').insert({
        'text': text,
        'order_index': orderIndex,
      });
      return true;
    } catch (e) {
      print('Error adding mission point: $e');
      return false;
    }
  }

  /// Update Mission Point (Admin only)
  Future<bool> updateMissionPoint(String id, String text) async {
    try {
      await _supabase
          .from('about_mission_points')
          .update({'text': text})
          .eq('id', id);
      return true;
    } catch (e) {
      print('Error updating mission point: $e');
      return false;
    }
  }

  /// Delete Mission Point (Admin only)
  Future<bool> deleteMissionPoint(String id) async {
    try {
      await _supabase
          .from('about_mission_points')
          .delete()
          .eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting mission point: $e');
      return false;
    }
  }

// Similarly, you can add CRUD methods for other tables...
}