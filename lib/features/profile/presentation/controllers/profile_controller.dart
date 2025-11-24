import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recalim/core/models/user_model.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/repositories/firestore_profile_repository.dart';

class ProfileController extends ChangeNotifier {
  final ProfileRepository _repository = FirestoreProfileRepository();
  
  UserModel? _user;
  bool _loading = false;
  bool _isEditing = false;

  UserModel? get user => _user;
  bool get loading => _loading;
  bool get isEditing => _isEditing;

  /// Initialize and load user profile
  Future<void> initialize(UserModel user) async {
    _user = user;
    notifyListeners();
  }

  /// Toggle edit mode
  void toggleEditMode() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? goal,
  }) async {
    if (_user == null) return;

    _setLoading(true);
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (goal != null) updates['goal'] = goal;

      await _repository.updateUserProfile(_user!.id, updates);

      if (name != null) _user!.name = name;
      if (goal != null) _user!.goal = goal;

      _isEditing = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

