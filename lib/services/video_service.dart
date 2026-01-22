import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video_model.dart';

class VideoService {
  final supabase = Supabase.instance.client;

  // ✅ Fetch all videos (admin = true shows all, false shows only active)
  Future<List<Video>> fetchVideos({bool admin = false}) async {
    try {
      var query = supabase.from('videos').select();

      if (!admin) {
        query = query.eq('is_active', true);
      }

      final res = await query.order('sort_order', ascending: true);

      return (res as List).map((e) => Video.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch videos: $e');
    }
  }

  // ✅ Add new video
  Future<Video> addVideo({
    required String title,
    required String youtubeUrl,
    int sortOrder = 0,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;

      final res = await supabase.from('videos').insert({
        'title': title,
        'youtube_url': youtubeUrl,
        'sort_order': sortOrder,
        'created_by': userId,
      }).select().single();

      return Video.fromMap(res);
    } catch (e) {
      throw Exception('Failed to add video: $e');
    }
  }

  // ✅ Update video
  Future<void> updateVideo({
    required int id,
    String? title,
    String? youtubeUrl,
    int? sortOrder,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (title != null) updates['title'] = title;
      if (youtubeUrl != null) updates['youtube_url'] = youtubeUrl;
      if (sortOrder != null) updates['sort_order'] = sortOrder;
      if (isActive != null) updates['is_active'] = isActive;

      await supabase.from('videos').update(updates).eq('id', id);
    } catch (e) {
      throw Exception('Failed to update video: $e');
    }
  }

  // ✅ Delete video
  Future<void> deleteVideo(int id) async {
    try {
      await supabase.from('videos').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete video: $e');
    }
  }

  // ✅ Toggle active status
  Future<void> toggleActive(int id, bool isActive) async {
    try {
      await supabase
          .from('videos')
          .update({'is_active': !isActive})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to toggle video status: $e');
    }
  }

  // ✅ Reorder videos
  Future<void> reorderVideos(List<Video> videos) async {
    try {
      for (var i = 0; i < videos.length; i++) {
        await supabase
            .from('videos')
            .update({'sort_order': i})
            .eq('id', videos[i].id);
      }
    } catch (e) {
      throw Exception('Failed to reorder videos: $e');
    }
  }
}