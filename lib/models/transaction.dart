import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;

class Transaction {
  final String id;
  final String title;
  final double amount;
  final String type; // 'income' | 'expense'
  final DateTime date;
  final String category;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String recurring; // 'none' | 'daily' | 'weekly' | 'monthly' | 'yearly'
  final String? sourceId; // set on occurrences generated from a recurring txn

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.recurring = 'none',
    this.sourceId,
  });

  bool get isIncome => type == 'income';
  bool get isRecurring => recurring != 'none';

  Transaction copyWith({
    String? title,
    double? amount,
    String? type,
    DateTime? date,
    String? category,
    String? note,
    String? recurring,
  }) {
    return Transaction(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      category: category ?? this.category,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      recurring: recurring ?? this.recurring,
      sourceId: sourceId,
    );
  }

  factory Transaction.fromMap(String id, Map<String, dynamic> data) {
    Timestamp dateTs = data['date'] as Timestamp? ??
        Timestamp.fromDate(DateTime.now());
    Timestamp createdAtTs = data['createdAt'] as Timestamp? ??
        Timestamp.fromDate(DateTime.now());
    Timestamp updatedAtTs = data['updatedAt'] as Timestamp? ?? createdAtTs;

    return Transaction(
      id: id,
      title: data['title'] as String? ?? 'Transaction',
      amount: ((data['amount'] as num?) ?? 0).toDouble(),
      type: (data['type'] as String?) == 'income' ? 'income' : 'expense',
      date: dateTs.toDate(),
      category: data['category'] as String? ?? 'Other',
      note: data['note'] as String? ?? '',
      createdAt: createdAtTs.toDate(),
      updatedAt: updatedAtTs.toDate(),
      recurring: data['recurring'] as String? ?? 'none',
      sourceId: data['sourceId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'type': type,
      'date': Timestamp.fromDate(date),
      'category': category,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'recurring': recurring,
      if (sourceId != null) 'sourceId': sourceId,
    };
  }
}