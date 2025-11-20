import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/community_repository.dart';
import '../../data/repositories/firestore_community_repository.dart';

class CommunityController extends ChangeNotifier {
  final CommunityRepository _repository = FirestoreCommunityRepository();
  
  List<Map<String, dynamic>> _posts = [];
  List<String> _quotes = [];
  bool _loading = false;

  List<Map<String, dynamic>> get posts => _posts;
  List<String> get quotes => _quotes;
  bool get loading => _loading;

  /// Initialize and load community data
  Future<void> initialize() async {
    _setLoading(true);
    try {
      _posts = await _repository.getPosts();
      _quotes = [
        "Consistency compounds. Every small effort counts.",
        "The gap between goals and accomplishment is discipline.",
        "One day or day one. You decide.",
      ];
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading community data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh feed
  Future<void> refreshFeed() async {
    await initialize();
  }

  /// Add a new post
  Future<void> addPost(String message) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final newPost = await _repository.createPost(user.uid, message);
        _posts.insert(0, newPost);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding post: $e');
      rethrow;
    }
  }

  /// Get random quote
  String getRandomQuote() {
    if (_quotes.isEmpty) return '';
    _quotes.shuffle();
    return _quotes.first;
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

