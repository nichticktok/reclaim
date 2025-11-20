import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/community_post_model.dart';
import '../../domain/repositories/community_repository.dart';
import '../../data/repositories/firestore_community_repository.dart';

class CommunityController extends ChangeNotifier {
  final CommunityRepository _repository = FirestoreCommunityRepository();
  
  List<CommunityPostModel> _posts = [];
  List<String> _quotes = [];
  int _currentQuoteIndex = 0;
  bool _loading = false;
  bool _initialized = false;
  StreamSubscription<List<CommunityPostModel>>? _postsSubscription;
  Timer? _quoteTimer;

  List<CommunityPostModel> get posts => _posts;
  List<String> get quotes => _quotes;
  bool get loading => _loading;
  
  /// Get current quote (changes every 5 seconds)
  String get currentQuote {
    if (_quotes.isEmpty) return '';
    return _quotes[_currentQuoteIndex % _quotes.length];
  }

  /// Initialize and load community data with real-time updates
  Future<void> initialize({bool forceRefresh = false}) async {
    if (_initialized && !forceRefresh) {
      debugPrint('👥 CommunityController already initialized, skipping...');
      return;
    }

    _setLoading(true);
    try {
      // Initialize quotes
      _quotes = [
        "Consistency compounds. Every small effort counts.",
        "The gap between goals and accomplishment is discipline.",
        "One day or day one. You decide.",
        "Small steps lead to big changes.",
        "Your future self is counting on you.",
        "Discipline is choosing between what you want now and what you want most.",
      ];
      
      // Shuffle quotes initially for variety
      _quotes.shuffle();
      _currentQuoteIndex = 0;

      // Cancel existing subscription and timer if any
      await _postsSubscription?.cancel();
      _quoteTimer?.cancel();

      // Set up real-time stream listener
      _postsSubscription = _repository.getPostsStream(limit: 50).listen(
        (updatedPosts) {
          _posts = updatedPosts;
          _initialized = true;
          _setLoading(false);
          notifyListeners();
          debugPrint('✅ Community posts updated in real-time: ${_posts.length} posts');
        },
        onError: (error) {
          debugPrint('❌ Error in posts stream: $error');
          _setLoading(false);
          notifyListeners();
        },
      );

      // Start quote rotation timer (changes every 5 seconds)
      _startQuoteTimer();

      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing community data: $e');
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Refresh feed (re-initialize to get latest data)
  Future<void> refreshFeed() async {
    await initialize(forceRefresh: true);
  }

  /// Start timer to rotate quotes every 5 seconds
  /// Only runs when user is on the community page
  void _startQuoteTimer() {
    _quoteTimer?.cancel();
    _quoteTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_quotes.isNotEmpty) {
        _currentQuoteIndex = (_currentQuoteIndex + 1) % _quotes.length;
        notifyListeners();
        debugPrint('🔄 Quote rotated to index $_currentQuoteIndex');
      }
    });
  }

  /// Stop quote rotation timer (when user leaves the page)
  void stopQuoteTimer() {
    _quoteTimer?.cancel();
    _quoteTimer = null;
    debugPrint('⏸️ Quote timer stopped');
  }

  /// Resume quote rotation timer (when user returns to the page)
  void resumeQuoteTimer() {
    if (_quoteTimer == null && _quotes.isNotEmpty) {
      _startQuoteTimer();
      debugPrint('▶️ Quote timer resumed');
    }
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    _quoteTimer?.cancel();
    super.dispose();
  }

  /// Add a new post
  /// Optimistically updates local state for immediate feedback
  Future<void> addPost(String message) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Get user name from Firestore or use display name
      String userName = user.displayName ?? 'Anonymous';
      
      // Try to get user name from Firestore
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          userName = userData?['name'] ?? userData?['displayName'] ?? userName;
        }
      } catch (e) {
        debugPrint('Could not fetch user name: $e');
      }

      // Create post in Firestore
      final newPost = await _repository.createPost(user.uid, userName, message);
      
      // Optimistically add to local state immediately for instant feedback
      _posts.insert(0, newPost);
      notifyListeners();
      debugPrint('✅ Post created and added optimistically');
      
      // Stream will sync the actual data from Firestore shortly
    } catch (e) {
      debugPrint('Error adding post: $e');
      rethrow;
    }
  }

  /// Toggle like on a post
  /// Optimistically updates local state for immediate feedback
  Future<void> toggleLikePost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // Find the post in local state
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) {
      debugPrint('⚠️ Post not found in local state, waiting for stream update');
      await _repository.toggleLikePost(postId, user.uid);
      return;
    }

    final post = _posts[postIndex];
    final wasLiked = post.isLikedBy(user.uid);

    // Optimistically update local state immediately
    if (wasLiked) {
      post.likes--;
      post.likedBy.remove(user.uid);
    } else {
      post.likes++;
      post.likedBy.add(user.uid);
    }
    notifyListeners();
    debugPrint('✅ Like toggled optimistically: ${wasLiked ? "unliked" : "liked"}');

    try {
      // Update in Firestore (stream will sync the actual data)
      await _repository.toggleLikePost(postId, user.uid);
    } catch (e) {
      debugPrint('Error toggling like: $e');
      
      // Revert optimistic update on error - restore original state
      if (wasLiked) {
        // Was unliked optimistically, so revert by liking again
        post.likes++;
        post.likedBy.add(user.uid);
      } else {
        // Was liked optimistically, so revert by unliking again
        post.likes--;
        post.likedBy.remove(user.uid);
      }
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a post
  /// Optimistically updates local state for immediate feedback
  Future<void> deletePost(String postId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Optimistically remove from local state immediately
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _posts.removeAt(postIndex);
        notifyListeners();
        debugPrint('✅ Post removed optimistically');
      }

      // Delete from Firestore (stream will sync the actual data)
      await _repository.deletePost(postId, user.uid);
    } catch (e) {
      debugPrint('Error deleting post: $e');
      
      // Revert optimistic update on error by refreshing
      await refreshFeed();
      rethrow;
    }
  }


  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}

