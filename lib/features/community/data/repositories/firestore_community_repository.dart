import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/community_post_model.dart';
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
}

