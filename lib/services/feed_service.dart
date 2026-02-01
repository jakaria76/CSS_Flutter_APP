import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/models/post_model.dart';
import 'package:css/models/comment_model.dart';
import 'package:path/path.dart' as path;

class FeedService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // POSTS
  // =====================================================

  Future<List<Post>> fetchPosts({int limit = 10, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('''
            *,
            post_images (
              image_url,
              display_order
            ),
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

  Future<void> createPost({
    required String caption,
    required List<XFile> images,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // 1. Create post
      final postResponse = await _supabase
          .from('posts')
          .insert({
        'admin_id': userId,
        'caption': caption.isEmpty ? null : caption,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      })
          .select()
          .single();

      final postId = postResponse['id'] as String;

      // 2. Upload images if any
      if (images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final imageUrl = await _uploadImage(images[i], postId, i);

          await _supabase.from('post_images').insert({
            'post_id': postId,
            'image_url': imageUrl,
            'display_order': i,
          });
        }
      }
    } catch (e) {
      debugPrint('Error creating post: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  /// ✅ FIXED: Improved image upload with proper MIME type detection
  Future<String> _uploadImage(XFile image, String postId, int index) async {
    try {
      // Read file as bytes
      final bytes = kIsWeb
          ? await image.readAsBytes()
          : await File(image.path).readAsBytes();

      // Get file extension
      String fileExt = path.extension(image.path).toLowerCase();
      if (fileExt.startsWith('.')) {
        fileExt = fileExt.substring(1); // Remove the dot
      }

      // ✅ Validate and normalize file extension
      String contentType;
      switch (fileExt) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          fileExt = 'jpg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
        // If unknown extension, default to jpeg
          contentType = 'image/jpeg';
          fileExt = 'jpg';
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${postId}_${index}_$timestamp.$fileExt';
      final filePath = 'post_images/$fileName';

      debugPrint('📸 Uploading image: $fileName (${bytes.length} bytes, $contentType)');

      // Upload to Supabase Storage
      final uploadResponse = await _supabase.storage
          .from('posts')
          .uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: false, // ✅ Changed to false to avoid conflicts
        ),
      );

      debugPrint('✅ Upload successful: $uploadResponse');

      // Get public URL
      final publicUrl = _supabase.storage
          .from('posts')
          .getPublicUrl(filePath);

      debugPrint('✅ Public URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      // Re-throw with more context
      if (e.toString().contains('Invalid media type')) {
        throw Exception('Invalid image format. Please use JPG, PNG, or WebP images.');
      }
      throw Exception('Failed to upload image: $e');
    }
  }

  /// ✅ Update existing post
  Future<void> updatePost({
    required String postId,
    required String caption,
    required List<XFile> newImages,
    required List<String> imagesToDelete,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // 1. Update post caption
      await _supabase
          .from('posts')
          .update({
        'caption': caption.isEmpty ? null : caption,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      })
          .eq('id', postId)
          .eq('admin_id', userId); // Ensure user owns the post

      // 2. Delete removed images from storage and database
      for (final imageUrl in imagesToDelete) {
        try {
          // Extract file path from URL
          final uri = Uri.parse(imageUrl);
          final pathSegments = uri.pathSegments;

          // Find 'posts' bucket and get the path after it
          final postsIndex = pathSegments.indexOf('posts');
          if (postsIndex != -1 && postsIndex < pathSegments.length - 1) {
            final filePath = pathSegments.sublist(postsIndex + 1).join('/');

            // Delete from storage
            await _supabase.storage.from('posts').remove([filePath]);

            debugPrint('✅ Deleted image from storage: $filePath');
          }

          // Delete from database
          await _supabase
              .from('post_images')
              .delete()
              .eq('post_id', postId)
              .eq('image_url', imageUrl);

          debugPrint('✅ Deleted image from database: $imageUrl');
        } catch (e) {
          debugPrint('⚠️ Error deleting image $imageUrl: $e');
          // Continue even if one image fails
        }
      }

      // 3. Upload new images
      if (newImages.isNotEmpty) {
        // Get current max display_order
        final existingImages = await _supabase
            .from('post_images')
            .select('display_order')
            .eq('post_id', postId)
            .order('display_order', ascending: false)
            .limit(1);

        int startOrder = 0;
        if (existingImages.isNotEmpty && existingImages[0]['display_order'] != null) {
          startOrder = (existingImages[0]['display_order'] as int) + 1;
        }

        for (int i = 0; i < newImages.length; i++) {
          final imageUrl = await _uploadImage(newImages[i], postId, startOrder + i);

          await _supabase.from('post_images').insert({
            'post_id': postId,
            'image_url': imageUrl,
            'display_order': startOrder + i,
          });
        }
      }

      debugPrint('✅ Post updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating post: $e');
      throw Exception('Failed to update post: $e');
    }
  }

  /// ✅ Delete post (with all images and comments)
  Future<void> deletePost(String postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // 1. Get all images for this post
      final images = await _supabase
          .from('post_images')
          .select('image_url')
          .eq('post_id', postId);

      // 2. Delete all images from storage
      for (final imageData in images) {
        final imageUrl = imageData['image_url'] as String;
        try {
          // Extract file path from URL
          final uri = Uri.parse(imageUrl);
          final pathSegments = uri.pathSegments;

          // Find 'posts' bucket and get the path after it
          final postsIndex = pathSegments.indexOf('posts');
          if (postsIndex != -1 && postsIndex < pathSegments.length - 1) {
            final filePath = pathSegments.sublist(postsIndex + 1).join('/');

            // Delete from storage
            await _supabase.storage.from('posts').remove([filePath]);

            debugPrint('✅ Deleted image from storage: $filePath');
          }
        } catch (e) {
          debugPrint('⚠️ Error deleting image from storage: $e');
          // Continue even if one image fails
        }
      }

      // 3. Delete post (CASCADE will delete post_images and comments automatically)
      await _supabase
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('admin_id', userId); // Ensure user owns the post

      debugPrint('✅ Post deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting post: $e');
      throw Exception('Failed to delete post: $e');
    }
  }

  // =====================================================
  // COMMENTS - ✅ WITH USER PROFILE INFO
  // =====================================================

  Future<List<Comment>> fetchComments(String postId) async {
    try {
      // ✅ Join with profiles table to get user info
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

      debugPrint('✅ Fetched ${(response as List).length} comments with user profiles');

      return (response as List).map((json) {
        debugPrint('Comment data: ${json['profiles']}');
        return Comment.fromMap(json);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching comments: $e');
      throw Exception('Failed to fetch comments: $e');
    }
  }

  Future<void> addComment({
    required String postId,
    required String commentText,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      await _supabase.from('comments').insert({
        'post_id': postId,
        'user_id': userId,
        'comment_text': commentText,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      debugPrint('✅ Comment added successfully');
    } catch (e) {
      debugPrint('❌ Error adding comment: $e');
      throw Exception('Failed to add comment: $e');
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _supabase.from('comments').delete().eq('id', commentId);

      debugPrint('✅ Comment deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting comment: $e');
      throw Exception('Failed to delete comment: $e');
    }
  }
}