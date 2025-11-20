import '../../../../models/user_model.dart';

/// Abstract repository for user data operations
abstract class UserRepository {
  Future<UserModel> getUser(String userId);
  Future<void> ensureUserDocument(String userId, Map<String, dynamic> userData);
  Future<void> updateLastSeen(String userId);
}

