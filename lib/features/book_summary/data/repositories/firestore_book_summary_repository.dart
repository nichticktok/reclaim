import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/book_summary_repository.dart';
import '../../domain/entities/book_summary.dart';

class FirestoreBookSummaryRepository implements BookSummaryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<String> saveBookSummary(BookSummary summary) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final docRef = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('book_summaries')
        .add(summary.toMap());

    return docRef.id;
  }

  @override
  Future<List<BookSummary>> getUserBookSummaries(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('book_summaries')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return BookSummary.fromMap(doc.data(), doc.id);
    }).toList();
  }

  @override
  Future<BookSummary?> getBookSummaryById(String summaryId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('book_summaries')
        .doc(summaryId)
        .get();

    if (!doc.exists) return null;

    return BookSummary.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<void> updateBookSummary(BookSummary summary) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('book_summaries')
        .doc(summary.id)
        .update(summary.toMap());
  }

  @override
  Future<void> deleteBookSummary(String summaryId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('book_summaries')
        .doc(summaryId)
        .delete();
  }
}

