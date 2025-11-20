import '../../../../models/community_post_model.dart';

/// Abstract repository for community data operations
abstract class CommunityRepository {
  Future<List<CommunityPostModel>> getPosts({int limit = 50});
  Future<CommunityPostModel> createPost(String userId, String userName, String message);
  Future<void> toggleLikePost(String postId, String userId);
  Future<void> deletePost(String postId, String userId);
  Stream<List<CommunityPostModel>> getPostsStream({int limit = 50});
}

