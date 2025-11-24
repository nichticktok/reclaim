import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recalim/core/models/user_model.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/repositories/firestore_user_repository.dart';

class HomeController extends ChangeNotifier {
  final UserRepository _repository = FirestoreUserRepository();
  
  UserModel? _currentUser;
  bool _loading = false; // Start as false, will be set to true when initialize() is called
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get loading => _loading;
  String? get error => _error;

  /// Initialize and load user data
  Future<void> initialize() async {
    _setLoading(true);
    _error = null;

    try {
      // Check if user is already available (don't wait for authStateChanges)
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        _error = 'No user found';
        _setLoading(false);
        return;
      }

      _currentUser = await _repository.getUser(user.uid);
      _setLoading(false);
      debugPrint('✅ HomeController initialized: User loaded - ${_currentUser?.name}');
    } on FirebaseException catch (e) {
      _error = e.message ?? e.code;
      _setLoading(false);
      debugPrint('❌ Firestore error: ${e.code} – ${e.message}');
    } catch (e) {
      _error = 'Failed to load user data';
      _setLoading(false);
      debugPrint('❌ Error loading user data: $e');
    }
  }

  /// Update last seen timestamp
  Future<void> updateLastSeen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _repository.updateLastSeen(user.uid);
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? goal,
    String? email,
  }) async {
    if (_currentUser == null) return;

    _setLoading(true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final updates = <String, dynamic>{};
      
      // Update name
      if (name != null && name.isNotEmpty) {
        updates['name'] = name;
        _currentUser!.name = name;
      }
      
      // Update goal
      if (goal != null) {
        updates['goal'] = goal;
        _currentUser!.goal = goal;
      }
      
      // Update email (requires Firebase Auth update)
      if (email != null && email.isNotEmpty && email != _currentUser!.email) {
        // Use verifyBeforeUpdateEmail for security (sends verification email)
        await user.verifyBeforeUpdateEmail(email);
        // Update Firestore immediately (user will verify via email)
        updates['email'] = email;
        updates['emailVerified'] = false; // Mark as unverified until user confirms
        _currentUser!.email = email;
      }

      // Update Firestore
      if (updates.isNotEmpty) {
        await _repository.ensureUserDocument(user.uid, updates);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Reload user data
  Future<void> reloadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUser = await _repository.getUser(user.uid);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

}

