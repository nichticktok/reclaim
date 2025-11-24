import 'package:recalim/core/models/user_model.dart';

/// Abstract repository for profile data operations
abstract class ProfileRepository {
  Future<UserModel> getUserProfile(String userId);
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates);
  Future<void> updateProfileField(String userId, String field, dynamic value);
}

