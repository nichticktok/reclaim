import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/reflection_repository.dart';
import '../../data/repositories/firestore_reflection_repository.dart';

class ReflectionController extends ChangeNotifier {
  final ReflectionRepository _repository = FirestoreReflectionRepository();
  
  bool _submitted = false;
  bool _loading = false;

  bool get submitted => _submitted;
  bool get loading => _loading;

  /// Submit reflection
  Future<void> submitReflection({
    required String gratitude,
    required String lesson,
    required String improvement,
  }) async {
    _setLoading(true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _repository.saveReflection(
          userId: user.uid,
          gratitude: gratitude,
          lesson: lesson,
          improvement: improvement,
        );
        _submitted = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error submitting reflection: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset reflection
  void reset() {
    _submitted = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

