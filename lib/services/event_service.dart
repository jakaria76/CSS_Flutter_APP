import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cloudinary_service.dart';

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── FETCH EVENTS ───────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchEvents({bool adminMode = false}) async {
    try {
      var query = _supabase.from('events').select();
      if (!adminMode) {
        query = query.eq('is_published', true);
      }
      final data = await query.order('start_datetime', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Failed to load events: $e');
    }
  }

  // ─── FETCH SINGLE EVENT ─────────────────────────────────────
  Future<Map<String, dynamic>?> fetchEventById(int eventId) async {
    try {
      final data = await _supabase
          .from('events')
          .select('*, event_images(image_url)')
          .eq('id', eventId)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('Error fetching event: $e');
      return null;
    }
  }

  // ─── UPLOAD BANNER ───────────────────────────────────────────
  Future<String?> uploadBanner(XFile bannerImage) async {
    try {
      final file = File(bannerImage.path);
      return await CloudinaryService.uploadImage(
        file,
        folder: CloudinaryService.folderEvents,
      );
    } catch (e) {
      debugPrint('Banner upload error: $e');
      return null;
    }
  }

  // ─── UPLOAD GALLERY ──────────────────────────────────────────
  Future<void> uploadGallery(int eventId, List<XFile> galleryImages) async {
    try {
      final List<File> files =
      galleryImages.map((img) => File(img.path)).toList();

      final List<String> urls = await CloudinaryService.uploadMultipleImages(
        files,
        folder: '${CloudinaryService.folderEvents}/gallery/$eventId',
      );

      for (final url in urls) {
        await _supabase.from('event_images').insert({
          'event_id' : eventId,
          'image_url': url,
        });
      }
    } catch (e) {
      debugPrint('Gallery upload error: $e');
    }
  }

  // ─── CREATE EVENT ───────────────────────────────────────────
  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String tag,
    required String shortDescription,
    required String fullDescription,
    required String venue,
    required double latitude,
    required double longitude,
    required DateTime startDatetime,
    DateTime? endDatetime,
    required double price,
    required bool isPublished,
    required bool isFeatured,
    XFile? bannerImage,
    List<XFile> galleryImages = const [],
  }) async {
    String? bannerUrl;
    if (bannerImage != null) {
      bannerUrl = await uploadBanner(bannerImage);
    }

    final event = await _supabase.from('events').insert({
      'title'            : title,
      'tag'              : tag,
      'short_description': shortDescription,
      'full_description' : fullDescription,
      'venue'            : venue,
      'latitude'         : latitude,
      'longitude'        : longitude,
      'start_datetime'   : startDatetime.toIso8601String(),
      'end_datetime'     : endDatetime?.toIso8601String(),
      'price'            : price,
      'is_published'     : isPublished,
      'is_featured'      : isFeatured,
      'banner_url'       : bannerUrl,
      'created_at'       : DateTime.now().toUtc().toIso8601String(),
    }).select().single();

    if (galleryImages.isNotEmpty) {
      await uploadGallery(event['id'], galleryImages);
    }

    return event;
  }

  // ─── SEND EMAIL NOTIFICATION ─────────────────────────────────
  Future<Map<String, dynamic>> sendEventNotification(
      Map<String, dynamic> event, String? bannerUrl) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return {'sent': 0, 'total': 0, 'noSession': true};

      final result = await _supabase.functions.invoke(
        'send_event_notification',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        body: {
          'title'         : event['title'],
          'description'   : event['short_description'],
          'event_id'      : event['id'],
          'banner_url'    : bannerUrl,
          'venue'         : event['venue'],
          'start_datetime': event['start_datetime'],
          'price'         : event['price'],
        },
      );

      return {
        'sent'     : result.data?['sent'] ?? 0,
        'total'    : result.data?['total'] ?? 0,
        'noSession': false,
      };
    } catch (e) {
      debugPrint('Email notification error: $e');
      return {'sent': 0, 'total': 0, 'error': e.toString()};
    }
  }

  // ─── UPDATE EVENT ───────────────────────────────────────────
  Future<void> updateEvent(int eventId, Map<String, dynamic> updates) async {
    try {
      await _supabase.from('events').update(updates).eq('id', eventId);
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  // ─── DELETE EVENT (Cloudinary + DB) ─────────────────────────
  Future<void> deleteEvent(int eventId) async {
    try {
      // ১. Banner + gallery URLs fetch করো
      final eventData = await _supabase
          .from('events')
          .select('banner_url, event_images(image_url)')
          .eq('id', eventId)
          .maybeSingle();

      if (eventData != null) {
        final List<String> urlsToDelete = [];

        // Banner URL
        final bannerUrl = eventData['banner_url'] as String?;
        if (bannerUrl != null && bannerUrl.isNotEmpty) {
          urlsToDelete.add(bannerUrl);
        }

        // Gallery URLs
        final galleryImages =
            eventData['event_images'] as List<dynamic>? ?? [];
        for (final img in galleryImages) {
          final imgUrl = img['image_url'] as String?;
          if (imgUrl != null && imgUrl.isNotEmpty) {
            urlsToDelete.add(imgUrl);
          }
        }

        // ২. Cloudinary থেকে সব delete করো (parallel)
        if (urlsToDelete.isNotEmpty) {
          debugPrint(
              '🗑️ Deleting ${urlsToDelete.length} image(s) from Cloudinary...');
          await Future.wait(
            urlsToDelete.map(
                  (url) =>
                  CloudinaryService.deleteFile(url, resourceType: 'image'),
            ),
          );
        }
      }

      // ৩. DB থেকে event delete করো
      await _supabase.from('events').delete().eq('id', eventId);
      debugPrint('✅ Event $eventId deleted successfully.');
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  // ─── TOGGLE PUBLISH ─────────────────────────────────────────
  Future<void> togglePublish(int eventId, bool isPublished) async {
    try {
      await _supabase
          .from('events')
          .update({'is_published': isPublished})
          .eq('id', eventId);
    } catch (e) {
      throw Exception('Failed to toggle publish: $e');
    }
  }

  // ─── IMAGE URL HELPERS ───────────────────────────────────────
  String getBannerUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (rawUrl.contains('cloudinary.com')) {
      return CloudinaryService.optimizeUrl(rawUrl, width: 800);
    }
    return rawUrl;
  }

  String getGalleryThumbnailUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (rawUrl.contains('cloudinary.com')) {
      return CloudinaryService.thumbnailUrl(rawUrl, size: 300);
    }
    return rawUrl;
  }
}