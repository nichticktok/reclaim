import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../domain/repositories/community_repository.dart';

/// Firestore implementation of CommunityRepository
class FirestoreCommunityRepository implements CommunityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Map<String, dynamic>>> getPosts({int limit = 20}) async {
    // For now, return placeholder data
    // In production, fetch from Firestore
    return [
      {
        "user": "Liam",
        "avatarColor": Colors.blueAccent,
        "message": "Finished my morning workout 💪 Feeling alive and ready to tackle the day!",
        "time": "2h ago",
      },
      {
        "user": "Sophie",
        "avatarColor": Colors.pinkAccent,
        "message": "Read 20 pages of 'Deep Work'. Staying consistent feels amazing 📚",
        "time": "4h ago",
      },
      {
        "user": "Ethan",
        "avatarColor": Colors.green,
        "message": "Reflected on my day: discipline > motivation 🔥",
        "time": "1d ago",
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> createPost(String userId, String message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    // In production, save to Firestore
    return {
      "user": user.displayName ?? "You",
      "avatarColor": Colors.purpleAccent,
      "message": message,
      "time": "Just now",
    };
  }

  @override
  Future<void> likePost(String postId) async {
    // Implementation for liking posts
    await _firestore
        .collection('community')
        .doc(postId)
        .update({'likes': FieldValue.increment(1)});
  }

  @override
  Future<void> deletePost(String postId) async {
    await _firestore.collection('community').doc(postId).delete();
  }
}

