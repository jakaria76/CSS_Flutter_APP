import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/models/post_model.dart';
import 'package:css/models/comment_model.dart';
import 'cloudinary_service.dart';

class FeedService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── FETCH POSTS ────────────────────────────────────────────
  Future<List<Post>> fetchPosts({int limit = 10, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('''
            *,
            post_images (image_url, display_order),
            comments (count)
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => Post.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      throw Exception('Failed to fetch posts: $e');
    }
  }

  // ─── FETCH SINGLE POST ──────────────────────────────────────
  Future<Post> fetchPostById(String postId) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('''
            *,
            post_images (image_url, display_order),
            comments (count)
          ''')
          .eq('id', postId)
          .single();

      return Post.fromMap(response);
    } catch (e) {
      debugPrint('Error fetching post by id: $e');
      throw Exception('Failed to fetch post: $e');
    }
  }

  // ─── CREATE POST ────────────────────────────────────────────
  Future<String> createPost({
    required String caption,
    required List<XFile> images,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final postResponse = await _supabase.from('posts').insert({
        'admin_id'  : userId,
        'caption'   : caption.isEmpty ? null : caption,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }).select().single();

      final postId = postResponse['id'] as String;

      if (images.isNotEmpty) {
        final List<File> files =
        images.map((img) => File(img.path)).toList();
        final List<String> uploadedUrls =
        await CloudinaryService.uploadMultipleImages(
          files,
          folder: '${CloudinaryService.folderPosts}/$postId',
        );

        for (int i = 0; i < uploadedUrls.length; i++) {
          await _supabase.from('post_images').insert({
            'post_id'      : postId,
            'image_url'    : uploadedUrls[i],
            'display_order': i,
          });
        }
      }

      return postId;
    } catch (e) {
      debugPrint('Error creating post: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  // ─── UPDATE POST ────────────────────────────────────────────
  Future<void> updatePost({
    required String postId,
    required String caption,
    required List<XFile> newImages,
    required List<String> imagesToDelete,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      await _supabase.from('posts').update({
        'caption'   : caption.isEmpty ? null : caption,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', postId).eq('admin_id', userId);

      // Cloudinary থেকে delete করো + DB থেকেও
      for (final imageUrl in imagesToDelete) {
        await CloudinaryService.deleteFile(imageUrl, resourceType: 'image');
        await _supabase
            .from('post_images')
            .delete()
            .eq('post_id', postId)
            .eq('image_url', imageUrl);
      }

      if (newImages.isNotEmpty) {
        final existingImages = await _supabase
            .from('post_images')
            .select('display_order')
            .eq('post_id', postId)
            .order('display_order', ascending: false)
            .limit(1);

        int startOrder = 0;
        if (existingImages.isNotEmpty &&
            existingImages[0]['display_order'] != null) {
          startOrder = (existingImages[0]['display_order'] as int) + 1;
        }

        final List<File> files =
        newImages.map((img) => File(img.path)).toList();
        final List<String> uploadedUrls =
        await CloudinaryService.uploadMultipleImages(
          files,
          folder: '${CloudinaryService.folderPosts}/$postId',
        );

        for (int i = 0; i < uploadedUrls.length; i++) {
          await _supabase.from('post_images').insert({
            'post_id'      : postId,
            'image_url'    : uploadedUrls[i],
            'display_order': startOrder + i,
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating post: $e');
      throw Exception('Failed to update post: $e');
    }
  }

  // ─── DELETE POST (Cloudinary + DB) ──────────────────────────
  Future<void> deletePost(String postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // ১. সব image URLs fetch করো
      final images = await _supabase
          .from('post_images')
          .select('image_url')
          .eq('post_id', postId);

      // ২. Cloudinary থেকে সব delete করো (parallel)
      final urls = (images as List)
          .map((e) => e['image_url'] as String? ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      if (urls.isNotEmpty) {
        await Future.wait(
          urls.map((url) =>
              CloudinaryService.deleteFile(url, resourceType: 'image')),
        );
      }

      // ৩. DB থেকে post delete করো
      await _supabase
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('admin_id', userId);
    } catch (e) {
      debugPrint('Error deleting post: $e');
      throw Exception('Failed to delete post: $e');
    }
  }

  // ─── IMAGE URL HELPER ───────────────────────────────────────
  String getPostImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    return url.contains('cloudinary.com')
        ? CloudinaryService.optimizeUrl(url, width: 600)
        : url;
  }

  // ─── FETCH COMMENTS ─────────────────────────────────────────
  Future<List<Comment>> fetchComments(String postId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('''
            *,
            profiles!comments_user_id_fkey (
              full_name,
              profile_image_url
            )
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => Comment.fromMap(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      throw Exception('Failed to fetch comments: $e');
    }
  }

  // ─── ADD COMMENT ────────────────────────────────────────────
  Future<void> addComment({
    required String postId,
    required String commentText,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('comments').insert({
      'post_id'     : postId,
      'user_id'     : userId,
      'comment_text': commentText,
      'created_at'  : DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ─── DELETE COMMENT ─────────────────────────────────────────
  Future<void> deleteComment(String commentId) async {
    try {
      await _supabase.from('comments').delete().eq('id', commentId);
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      throw Exception('Failed to delete comment: $e');
    }
  }
}