/// Abstract repository for community data operations
abstract class CommunityRepository {
  Future<List<Map<String, dynamic>>> getPosts({int limit = 20});
  Future<Map<String, dynamic>> createPost(String userId, String message);
  Future<void> likePost(String postId);
  Future<void> deletePost(String postId);
}

