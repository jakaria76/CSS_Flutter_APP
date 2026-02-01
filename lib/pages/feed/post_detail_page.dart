import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:css/models/comment_model.dart';
import 'package:css/widgets/comment_tile.dart';
import 'package:css/models/post_model.dart';
import 'package:css/services/feed_service.dart';
import 'package:css/widgets/post_card.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;

  const PostDetailPage({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _feedService = FeedService();
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isPostingComment = false;
  late Post _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final comments = await _feedService.fetchComments(_currentPost.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('মন্তব্য লোড করতে সমস্যা হয়েছে', isError: true);
      }
    }
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    // Check if user is authenticated
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      _showSnackBar('মন্তব্য করতে লগইন করুন', isError: true);
      return;
    }

    setState(() => _isPostingComment = true);
    try {
      await _feedService.addComment(
        postId: _currentPost.id,
        commentText: text,
      );

      if (mounted) {
        _commentController.clear();
        FocusScope.of(context).unfocus();
        await _loadComments();

        // Update post comment count
        final updatedPost = Post(
          id: _currentPost.id,
          adminId: _currentPost.adminId,
          caption: _currentPost.caption,
          createdAt: _currentPost.createdAt,
          images: _currentPost.images,
          commentCount: _currentPost.commentCount + 1,
        );

        setState(() {
          _currentPost = updatedPost;
        });

        _showSnackBar('মন্তব্য পোস্ট হয়েছে');
      }
    } catch (e) {
      _showSnackBar('মন্তব্য পোস্ট করতে সমস্যা হয়েছে', isError: true);
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF203A43),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'মন্তব্য মুছবেন?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'এই মন্তব্যটি স্থায়ীভাবে মুছে যাবে',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _feedService.deleteComment(comment.id);
        if (mounted) {
          await _loadComments();

          final updatedPost = Post(
            id: _currentPost.id,
            adminId: _currentPost.adminId,
            caption: _currentPost.caption,
            createdAt: _currentPost.createdAt,
            images: _currentPost.images,
            commentCount: _currentPost.commentCount - 1,
          );

          setState(() {
            _currentPost = updatedPost;
          });

          _showSnackBar('মন্তব্য মুছে ফেলা হয়েছে');
        }
      } catch (e) {
        _showSnackBar('মন্তব্য মুছতে সমস্যা হয়েছে', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: const Color(0xFF132D46),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'পোস্ট',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background orb
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.08),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          Column(
            children: [
              // Post content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Post card
                      PostCard(post: _currentPost),

                      const SizedBox(height: 16),

                      // Comments section header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.comment_rounded,
                              color: Colors.cyanAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'মন্তব্য (${_comments.length})',
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Comments list
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            color: Colors.cyanAccent,
                            strokeWidth: 2,
                          ),
                        )
                      else if (_comments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'কোনো মন্তব্য নেই।\nপ্রথম মন্তব্য করুন!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            final isOwner = comment.userId == currentUserId;

                            return CommentTile(
                              comment: comment,
                              isOwner: isOwner,
                              onDelete: isOwner
                                  ? () => _deleteComment(comment)
                                  : null,
                            );
                          },
                        ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Comment input
              _buildCommentInput(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF132D46),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // User avatar
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.cyanAccent.withOpacity(0.5),
                  Colors.purpleAccent.withOpacity(0.5),
                ],
              ),
            ),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF1A2332),
              child: Icon(
                Icons.person_rounded,
                size: 20,
                color: Colors.white54,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Text field
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _commentController,
                    enabled: isAuthenticated,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: isAuthenticated
                          ? 'মন্তব্য লিখুন...'
                          : 'মন্তব্য করতে লগইন করুন',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    maxLength: 500,
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                      return null; // Hide counter
                    },
                    textInputAction: TextInputAction.send,
                    onSubmitted: isAuthenticated ? (_) => _postComment() : null,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: isAuthenticated && !_isPostingComment ? _postComment : null,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isAuthenticated
                      ? [Colors.cyanAccent, Colors.purpleAccent]
                      : [Colors.grey.shade600, Colors.grey.shade700],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: isAuthenticated ? [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ] : [],
              ),
              child: _isPostingComment
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Icon(
                Icons.send_rounded,
                color: isAuthenticated ? Colors.white : Colors.white54,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}