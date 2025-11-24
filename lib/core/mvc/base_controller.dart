import 'package:flutter/foundation.dart';

/// Base class for all MVC controllers (a thin wrapper over ChangeNotifier)
/// that exposes loading/error helpers and a guard method for async work.
abstract class BaseController extends ChangeNotifier {
  bool _isLoading = false;
  Object? _lastError;

  bool get isLoading => _isLoading;
  Object? get lastError => _lastError;

  @protected
  Future<T> guardAsync<T>(Future<T> Function() runner) async {
    _setLoading(true);
    try {
      final result = await runner();
      _lastError = null;
      return result;
    } catch (err, stack) {
      _lastError = err;
      onError(err, stack);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  @protected
  void onError(Object error, StackTrace stackTrace) {
    debugPrint('Controller error: $error');
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
