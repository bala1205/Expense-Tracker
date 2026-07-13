import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppData {
  static ValueNotifier<double> income = ValueNotifier(0);
  static ValueNotifier<double> expense = ValueNotifier(0);
  static ValueNotifier<double> totalBalance = ValueNotifier(0);

  static ValueNotifier<List<Map<String, dynamic>>> transactions =
  ValueNotifier([]);

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add Transaction to Firestore
  static Future<void> addTransaction(
      String title, double amount, bool isIncome) async {

    await _firestore.collection("transactions").add({
      "title": title,
      "amount": amount,
      "isIncome": isIncome,
      "date": Timestamp.now(),
    });

    await loadTransactions();
  }

  // Load Transactions from Firestore
  static Future<void> loadTransactions() async {
    final snapshot = await _firestore
        .collection("transactions")
        .orderBy("date", descending: true)
        .get();

    double incomeTotal = 0;
    double expenseTotal = 0;

    List<Map<String, dynamic>> list = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();

      bool isIncome = data["isIncome"];
      double amount = (data["amount"] as num).toDouble();

      if (isIncome) {
        incomeTotal += amount;
      } else {
        expenseTotal += amount;
      }

      list.add({
        "id": doc.id,
        "name": data["title"],
        "amount": amount,
        "isIncome": isIncome,
        "date": data["date"] != null
            ? (data["date"] as Timestamp)
            .toDate()
            .toString()
            .substring(0, 10)
            : "",
        "icon":
        isIncome ? Icons.arrow_upward : Icons.arrow_downward,
        "color": isIncome ? Colors.green : Colors.red,
      });
    }

    income.value = incomeTotal;
    expense.value = expenseTotal;
    totalBalance.value = incomeTotal - expenseTotal;
    transactions.value = list;
  }

  // Delete Transaction
  static Future<void> deleteTransaction(String id) async {
    await _firestore.collection("transactions").doc(id).delete();
    await loadTransactions();
  }
}