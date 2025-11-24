import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recalim/features/community/domain/entities/community_post_model.dart';
import 'package:recalim/features/community/domain/entities/community_comment_model.dart';
import '../controllers/community_controller.dart';

/// Community Screen - Social feed for all users
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with WidgetsBindingObserver {
  CommunityController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize controller when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller = context.read<CommunityController>();
      _controller?.initialize();
      // Resume quote timer when screen is visible
      _controller?.resumeQuoteTimer();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save controller reference when dependencies change
    _controller ??= context.read<CommunityController>();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop quote timer when user leaves the page
    _controller?.stopQuoteTimer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _controller ??= context.read<CommunityController>();
    if (state == AppLifecycleState.resumed) {
      // Resume timer when app comes to foreground
      _controller?.resumeQuoteTimer();
    } else if (state == AppLifecycleState.paused) {
      // Pause timer when app goes to background
      _controller?.stopQuoteTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        title: const Text("Community", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          // Add Post button in AppBar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () => _showAddPostDialog(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
              tooltip: 'Add Post',
            ),
          ),
        ],
      ),
      body: Consumer<CommunityController>(
        builder: (context, controller, child) {
          if (controller.loading && controller.posts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.refreshFeed(),
            color: Colors.orange,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 80,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Header with quote
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    constraints: const BoxConstraints(
                      minHeight: 140,
                      maxHeight: 140,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.orange.withValues(alpha: 0.2),
                          Colors.orange.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          size: 28,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                            child: Text(
                              controller.currentQuote,
                              key: ValueKey<String>(controller.currentQuote),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                                height: 1.3,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Posts list
                  if (controller.posts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No posts yet',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to share your journey!',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...controller.posts.map(
                      (post) => _PostCard(
                        post: post,
                        controller: controller,
                        onLike: () => controller.toggleLikePost(post.id),
                        onDelete: () => _showDeleteConfirmation(
                          context,
                          post.id,
                          controller,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddPostDialog(BuildContext context) {
    final controller = context.read<CommunityController>();
    final textController = TextEditingController();
    bool isPosting = false;
    // Save reference to parent context before showing dialog
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Row(
            children: [
              Icon(Icons.edit, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                'Share with Community',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
          content: TextField(
            controller: textController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText:
                  'What\'s on your mind? Share your progress, wins, or motivation!',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isPosting ? null : () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: isPosting
                  ? null
                  : () async {
                      if (textController.text.trim().isEmpty) return;
                      setDialogState(() => isPosting = true);
                      try {
                        await controller.addPost(textController.text.trim());
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Post shared! 🎉'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() => isPosting = false);
                        if (!mounted) return;
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                disabledBackgroundColor: Colors.orange.withValues(alpha: 0.5),
              ),
              child: isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Post', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String postId,
    CommunityController controller,
  ) {
    // Save reference to parent context before showing dialog
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Post', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this post?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await controller.deletePost(postId);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Post deleted'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final CommunityPostModel post;
  final CommunityController controller;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  const _PostCard({
    required this.post,
    required this.controller,
    required this.onLike,
    required this.onDelete,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _showComments = false;
  final TextEditingController _commentController = TextEditingController();
  String? _replyingToCommentId;

  @override
  void initState() {
    super.initState();
    // Load comments when card is first created
    widget.controller.loadComments(widget.post.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    // Stop loading comments when card is disposed
    widget.controller.stopLoadingComments(widget.post.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnPost =
        currentUser != null && widget.post.userId == currentUser.uid;
    final isLiked =
        currentUser != null && widget.post.isLikedBy(currentUser.uid);
    final avatarColor = Color(widget.post.getAvatarColorValue());
    final comments = widget.controller.getComments(widget.post.id);
    final topLevelComments = comments
        .where((c) => c.parentCommentId == null)
        .toList();

    return GestureDetector(
      onTap: () {
        // Close comments when tapping on the post card (but not on interactive elements)
        if (_showComments) {
          setState(() {
            _showComments = false;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar, name, time, delete button
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: avatarColor,
                  radius: 20,
                  child: Text(
                    widget.post.userName.isNotEmpty
                        ? widget.post.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.post.getTimeAgo(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Delete button (only for own posts)
                if (isOwnPost)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: widget.onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Message
            Text(
              widget.post.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            // Like button and count
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onLike,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isLiked
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isLiked
                            ? Colors.red.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked
                              ? Colors.red
                              : Colors.white.withValues(alpha: 0.7),
                          size: 18,
                        ),
                        if (widget.post.likes > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            widget.post.likes.toString(),
                            style: TextStyle(
                              color: isLiked
                                  ? Colors.red
                                  : Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Comment button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showComments = !_showComments;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 18,
                        ),
                        if (widget.post.comments > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            widget.post.comments.toString(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Comments section
            if (_showComments) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),
              // Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showComments = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Comment input
              GestureDetector(
                onTap: () {}, // Prevent tap from closing comments
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: currentUser != null
                          ? Color(
                              _getUserAvatarColor(
                                currentUser.displayName ?? 'You',
                              ),
                            )
                          : Colors.grey,
                      radius: 16,
                      child: Text(
                        currentUser?.displayName?[0].toUpperCase() ?? 'Y',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: _replyingToCommentId != null
                              ? 'Write a reply...'
                              : 'Write a comment...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
                            _submitComment();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.orange,
                        size: 20,
                      ),
                      onPressed: () {
                        if (_commentController.text.trim().isNotEmpty) {
                          _submitComment();
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              if (_replyingToCommentId != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 40),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Replying to ${comments.firstWhere((c) => c.id == _replyingToCommentId).userName}',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _replyingToCommentId = null;
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.orange,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // Comments list
              GestureDetector(
                onTap: () {}, // Prevent tap from closing comments
                behavior: HitTestBehavior.opaque,
                child: topLevelComments.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No comments yet. Be the first to comment!',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: topLevelComments.asMap().entries.map((entry) {
                          final index = entry.key;
                          final comment = entry.value;
                          return _CommentWidget(
                            key: ValueKey('comment_${comment.id}_$index'),
                            comment: comment,
                            allComments: comments,
                            controller: widget.controller,
                            postId: widget.post.id,
                            onReply: () {
                              setState(() {
                                _replyingToCommentId = comment.id;
                              });
                            },
                          );
                        }).toList(),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _submitComment() async {
    final message = _commentController.text.trim();
    if (message.isEmpty) return;

    try {
      await widget.controller.addComment(
        widget.post.id,
        message,
        parentCommentId: _replyingToCommentId,
      );
      _commentController.clear();
      setState(() {
        _replyingToCommentId = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  int _getUserAvatarColor(String userName) {
    final hash = userName.hashCode;
    final colors = [
      0xFF2196F3, // Blue
      0xFFE91E63, // Pink
      0xFF4CAF50, // Green
      0xFFFF9800, // Orange
      0xFF9C27B0, // Purple
      0xFF00BCD4, // Cyan
      0xFFFF5722, // Deep Orange
      0xFF795548, // Brown
    ];
    return colors[hash.abs() % colors.length];
  }
}

class _CommentWidget extends StatelessWidget {
  final CommunityCommentModel comment;
  final List<CommunityCommentModel> allComments;
  final CommunityController controller;
  final String postId;
  final VoidCallback onReply;

  const _CommentWidget({
    super.key,
    required this.comment,
    required this.allComments,
    required this.controller,
    required this.postId,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isLiked = currentUser != null && comment.isLikedBy(currentUser.uid);
    final isOwnComment =
        currentUser != null && comment.userId == currentUser.uid;
    final avatarColor = Color(comment.getAvatarColorValue());
    final replies = allComments
        .where((c) => c.parentCommentId == comment.id)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: avatarColor,
                radius: 16,
                child: Text(
                  comment.userName.isNotEmpty
                      ? comment.userName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                comment.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                comment.getTimeAgo(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              controller.toggleLikeComment(postId, comment.id),
                          child: Row(
                            children: [
                              Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.white54,
                                size: 16,
                              ),
                              if (comment.likes > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  comment.likes.toString(),
                                  style: TextStyle(
                                    color: isLiked
                                        ? Colors.red
                                        : Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: onReply,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.reply,
                                color: Colors.white54,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reply',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isOwnComment) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () =>
                                _showDeleteCommentConfirmation(context),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.red.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Replies
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Column(
                children: replies.asMap().entries.map((entry) {
                  final index = entry.key;
                  final reply = entry.value;
                  return _CommentWidget(
                    key: ValueKey('${reply.id}_reply_$index'),
                    comment: reply,
                    allComments: allComments,
                    controller: controller,
                    postId: postId,
                    onReply: onReply,
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteCommentConfirmation(BuildContext context) {
    // Save reference to scaffold messenger before showing dialog
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Delete Comment',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this comment?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close dialog immediately
              Navigator.pop(dialogContext);

              try {
                await controller.deleteComment(postId, comment.id);
              } catch (e) {
                // Show error if deletion fails
                if (context.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
