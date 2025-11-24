import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recalim/features/community/domain/entities/community_post_model.dart';
import 'package:recalim/features/community/domain/entities/community_comment_model.dart';
import '../../domain/repositories/community_repository.dart';

/// Firestore implementation of CommunityRepository
/// Uses shared 'community' collection (not user-specific)
class FirestoreCommunityRepository implements CommunityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<CommunityPostModel>> getPosts({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('community')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => CommunityPostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  @override
  Stream<List<CommunityPostModel>> getPostsStream({int limit = 50}) {
    return _firestore
        .collection('community')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityPostModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<CommunityPostModel> createPost(String userId, String userName, String message) async {
    try {
      final postRef = _firestore.collection('community').doc();
      
      final post = CommunityPostModel(
        id: postRef.id,
        userId: userId,
        userName: userName,
        message: message,
        likes: 0,
        comments: 0,
        createdAt: DateTime.now(),
      );

      await postRef.set(post.toJson());
      return post;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  @override
  Future<void> toggleLikePost(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('community').doc(postId);
      final postDoc = await postRef.get();

      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final postData = postDoc.data()!;
      final likedBy = List<String>.from(postData['likedBy'] ?? []);

      if (likedBy.contains(userId)) {
        // Unlike
        await postRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        // Like
        await postRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  @override
  Future<void> deletePost(String postId, String userId) async {
    try {
      final postDoc = await _firestore.collection('community').doc(postId).get();
      
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final postData = postDoc.data()!;
      if (postData['userId'] != userId) {
        throw Exception('You can only delete your own posts');
      }

      await _firestore.collection('community').doc(postId).delete();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  @override
  Future<List<CommunityCommentModel>> getComments(String postId) async {
    try {
      final snapshot = await _firestore
          .collection('community')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => CommunityCommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  @override
  Stream<List<CommunityCommentModel>> getCommentsStream(String postId) {
    return _firestore
        .collection('community')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityCommentModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<CommunityCommentModel> createComment(
    String postId,
    String userId,
    String userName,
    String message, {
    String? parentCommentId,
  }) async {
    try {
      final commentRef = _firestore
          .collection('community')
          .doc(postId)
          .collection('comments')
          .doc();

      final comment = CommunityCommentModel(
        id: commentRef.id,
        postId: postId,
        userId: userId,
        userName: userName,
        message: message,
        parentCommentId: parentCommentId,
        likes: 0,
        replies: 0,
        createdAt: DateTime.now(),
      );

      await commentRef.set(comment.toJson());

      // Update post comment count only if it's a top-level comment
      // (replies don't count toward the post's comment count)
      if (parentCommentId == null) {
        await _firestore.collection('community').doc(postId).update({
          'comments': FieldValue.increment(1),
        });
      }

      // If this is a reply, update parent comment reply count
      if (parentCommentId != null) {
        await _firestore
            .collection('community')
            .doc(postId)
            .collection('comments')
            .doc(parentCommentId)
            .update({
          'replies': FieldValue.increment(1),
        });
      }

      return comment;
    } catch (e) {
      throw Exception('Failed to create comment: $e');
    }
  }

  @override
  Future<void> toggleLikeComment(String postId, String commentId, String userId) async {
    try {
      final commentRef = _firestore
          .collection('community')
          .doc(postId)
          .collection('comments')
          .doc(commentId);
      final commentDoc = await commentRef.get();

      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }

      final commentData = commentDoc.data()!;
      final likedBy = List<String>.from(commentData['likedBy'] ?? []);

      if (likedBy.contains(userId)) {
        // Unlike
        await commentRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        // Like
        await commentRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  @override
  Future<void> deleteComment(String postId, String commentId, String userId) async {
    try {
      final commentDoc = await _firestore
          .collection('community')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .get();

      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }

      final commentData = commentDoc.data()!;
      if (commentData['userId'] != userId) {
        throw Exception('You can only delete your own comments');
      }

      final parentCommentId = commentData['parentCommentId'] as String?;
      final isTopLevelComment = parentCommentId == null;

      // Delete the comment
      await _firestore
          .collection('community')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // Update post comment count only if it's a top-level comment
      // (replies don't count toward the post's comment count)
      if (isTopLevelComment) {
        await _firestore.collection('community').doc(postId).update({
          'comments': FieldValue.increment(-1),
        });
      }

      // If this was a reply, update parent comment reply count
      if (parentCommentId != null) {
        await _firestore
            .collection('community')
            .doc(postId)
            .collection('comments')
            .doc(parentCommentId)
            .update({
          'replies': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }
}

