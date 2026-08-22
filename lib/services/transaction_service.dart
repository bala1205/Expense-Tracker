import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:expense_track/models/transaction.dart';

class TransactionService {
  TransactionService._();

  static CollectionReference<Map<String, dynamic>> _transactions(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions');

  static DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  // ─── Transactions ────────────────────────────────────────────────────────

  static Stream<List<Transaction>> watchTransactions(String uid) {
    return _transactions(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Transaction.fromMap(doc.id, doc.data()))
            .toList());
  }

  static Future<void> addTransaction(String uid, Transaction transaction) async {
    final docRef = _transactions(uid).doc(transaction.id);
    await docRef.set(transaction.toMap());
  }

  static Future<void> updateTransaction(String uid, Transaction transaction) async {
    await _transactions(uid).doc(transaction.id).set(transaction.toMap());
  }

  static Future<void> deleteTransaction(
    String uid,
    Transaction transaction, {
    List<String> occurrenceIds = const [],
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(_transactions(uid).doc(transaction.id));
    for (final id in occurrenceIds) {
      batch.delete(_transactions(uid).doc(id));
    }
    await batch.commit();
  }

  // ─── Recurring materialization ───────────────────────────────────────────

  /// Generates occurrences for recurring transactions whose due dates have
  /// passed. Each occurrence has a deterministic id (`<sourceId>_<date>`), so
  /// it is never created twice even across app sessions.
  static Future<void> materializeRecurring(String uid, List<Transaction> all) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final existingIds = all.map((t) => t.id).toSet();

    for (final t in all.where((t) => t.isRecurring)) {
      DateTime due = _nextOccurrence(t.date, t.recurring);
      int created = 0;

      while (!due.isAfter(today) && created < 12) {
        final occurrenceId = '${t.id}_${due.toIso8601String().substring(0, 10)}';
        if (!existingIds.contains(occurrenceId)) {
          await _transactions(uid).doc(occurrenceId).set({
            'title': t.title,
            'amount': t.amount,
            'type': t.type,
            'date': Timestamp.fromDate(due),
            'category': t.category,
            'note': t.note,
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
            'recurring': 'none',
            'sourceId': t.id,
          });
          existingIds.add(occurrenceId);
          created++;
        }
        due = _nextOccurrence(due, t.recurring);
      }
    }
  }

  static DateTime _nextOccurrence(DateTime date, String recurring) {
    switch (recurring) {
      case 'daily':
        return DateTime(date.year, date.month, date.day + 1);
      case 'weekly':
        return DateTime(date.year, date.month, date.day + 7);
      case 'monthly':
        return DateTime(date.year, date.month + 1, date.day);
      case 'yearly':
        return DateTime(date.year + 1, date.month, date.day);
      default:
        return date;
    }
  }

  // ─── User settings (users/{uid}) ─────────────────────────────────────────

  static Stream<Map<String, dynamic>?> watchSettings(String uid) {
    return _userDoc(uid).snapshots().map((doc) => doc.data());
  }

  static Future<void> saveSettings(String uid, Map<String, dynamic> settings) async {
    await _userDoc(uid).set(settings, SetOptions(merge: true));
  }
}