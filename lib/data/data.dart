import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:expense_track/constants.dart';
import 'package:expense_track/models/transaction.dart';
import 'package:expense_track/services/transaction_service.dart';
import 'package:expense_track/utils/formatters.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Central state hub. Keeps the existing ValueNotifier-based approach and
/// reacts to Firestore snapshot streams, so the dashboard, statistics and
/// lists always stay in sync with the backend.
class AppData {
  AppData._();

  static String get uid => user.value?.uid ?? '';
  static String get currencySymbol =>
      AppConstants.currencySymbols[currencyCode.value] ?? '₹';

  // ─── Transaction state ──────────────────────────────────────────────────
  static final ValueNotifier<List<Transaction>> transactions =
      ValueNotifier(const []);
  static final ValueNotifier<double> income = ValueNotifier(0);
  static final ValueNotifier<double> expense = ValueNotifier(0);
  static final ValueNotifier<double> totalBalance = ValueNotifier(0);
  static final ValueNotifier<double> todayIncome = ValueNotifier(0);
  static final ValueNotifier<double> todayExpense = ValueNotifier(0);
  static final ValueNotifier<double> monthIncome = ValueNotifier(0);
  static final ValueNotifier<double> monthExpense = ValueNotifier(0);
  static final ValueNotifier<bool> isLoading = ValueNotifier(true);
  static final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  /// One-time budget alert for the UI to surface (respects the
  /// notifications setting).
  static final ValueNotifier<String?> budgetAlert = ValueNotifier(null);

  // ─── Account / settings state ───────────────────────────────────────────
  static final ValueNotifier<User?> user = ValueNotifier(null);
  static final ValueNotifier<String> currencyCode = ValueNotifier('INR');
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.system);
  static final ValueNotifier<bool> notificationsEnabled = ValueNotifier(true);
  static final ValueNotifier<double> monthlyBudget = ValueNotifier(0);
  static final ValueNotifier<Map<String, double>> categoryBudgets =
      ValueNotifier({});
  static final ValueNotifier<String> displayName = ValueNotifier('');

  static StreamSubscription<List<Transaction>>? _txnSub;
  static StreamSubscription<Map<String, dynamic>?>? _settingsSub;
  static bool _materializing = false;
  static bool _budgetExceededAlerted = false;
  static bool _budgetApproachAlerted = false;

  // ─── Lifecycle ──────────────────────────────────────────────────────────

  static void onAuthChanged(User? currentUser) {
    if (currentUser == null) {
      reset();
      return;
    }
    user.value = currentUser;
    init();
  }

  static void init() {
    if (uid.isEmpty) return;
    isLoading.value = true;
    errorMessage.value = null;

    _txnSub?.cancel();
    _settingsSub?.cancel();

    _txnSub = TransactionService.watchTransactions(uid).listen(
      _onTransactions,
      onError: _onStreamError,
    );
    _settingsSub = TransactionService.watchSettings(uid).listen(
      _onSettings,
      onError: _onStreamError,
    );
  }

  static void reset() {
    _txnSub?.cancel();
    _txnSub = null;
    _settingsSub?.cancel();
    _settingsSub = null;

    user.value = null;
    transactions.value = const [];
    income.value = 0;
    expense.value = 0;
    totalBalance.value = 0;
    todayIncome.value = 0;
    todayExpense.value = 0;
    monthIncome.value = 0;
    monthExpense.value = 0;
    isLoading.value = true;
    errorMessage.value = null;
    budgetAlert.value = null;
    _materializing = false;
    _budgetExceededAlerted = false;
    _budgetApproachAlerted = false;
  }

  // ─── Stream handlers ────────────────────────────────────────────────────

  /// Clears in-memory data and re-subscribes to the Firestore streams.
  static void reloadData() {
    transactions.value = const [];
    income.value = 0;
    expense.value = 0;
    totalBalance.value = 0;
    todayIncome.value = 0;
    todayExpense.value = 0;
    monthIncome.value = 0;
    monthExpense.value = 0;
    errorMessage.value = null;
    isLoading.value = true;
    init();
  }

  static void _onTransactions(List<Transaction> list) {
    transactions.value = list;
    _recompute(list);
    isLoading.value = false;
    errorMessage.value = null;
    _materializeRecurring(list);
  }

  static void _onSettings(Map<String, dynamic>? data) {
    if (data == null) return;
    currencyCode.value = data['currency'] as String? ?? 'INR';
    themeMode.value = _themeModeFrom(data['themeMode']);
    notificationsEnabled.value =
        data['notificationsEnabled'] as bool? ?? true;
    monthlyBudget.value = ((data['monthlyBudget'] as num?) ?? 0).toDouble();
    displayName.value = data['name'] as String? ?? '';

    final budgets = data['categoryBudgets'];
    if (budgets is Map<String, dynamic>) {
      categoryBudgets.value = budgets.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    }
  }

  static void _onStreamError(Object error) {
    isLoading.value = false;
    errorMessage.value = Formatters.friendlyError(error);
  }

  static void _recompute(List<Transaction> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    double inc = 0, exp = 0;
    double tInc = 0, tExp = 0;
    double mInc = 0, mExp = 0;

    for (final t in list) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      if (t.isIncome) {
        inc += t.amount;
        if (day == today) tInc += t.amount;
        if (!day.isBefore(monthStart)) mInc += t.amount;
      } else {
        exp += t.amount;
        if (day == today) tExp += t.amount;
        if (!day.isBefore(monthStart)) mExp += t.amount;
      }
    }

    income.value = inc;
    expense.value = exp;
    totalBalance.value = inc - exp;
    todayIncome.value = tInc;
    todayExpense.value = tExp;
    monthIncome.value = mInc;
    monthExpense.value = mExp;

    _checkBudget(mExp);
  }

  static void _checkBudget(double spent) {
    final budget = monthlyBudget.value;
    if (budget <= 0) {
      _budgetExceededAlerted = false;
      _budgetApproachAlerted = false;
      return;
    }

    final exceeded = spent >= budget;
    final approaching = !exceeded && spent >= budget * 0.8;

    if (notificationsEnabled.value && exceeded && !_budgetExceededAlerted) {
      _budgetExceededAlerted = true;
      _budgetApproachAlerted = true;
      budgetAlert.value =
          'Monthly budget exceeded: $currencySymbol${spent.toStringAsFixed(0)} '
          'spent of $currencySymbol${budget.toStringAsFixed(0)}.';
    } else if (notificationsEnabled.value &&
        approaching &&
        !_budgetApproachAlerted) {
      _budgetApproachAlerted = true;
      budgetAlert.value = 'You have used 80% of your monthly budget.';
    }
  }

  static void _materializeRecurring(List<Transaction> list) {
    if (uid.isEmpty || _materializing) return;
    _materializing = true;
    TransactionService.materializeRecurring(uid, list)
        .whenComplete(() => _materializing = false);
  }

  static ThemeMode _themeModeFrom(Object? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // ─── Write operations (UI calls these; streams refresh the state) ───────

  static Future<void> addTransaction({
    required String title,
    required double amount,
    required String type,
    required DateTime date,
    required String category,
    String note = '',
    String recurring = 'none',
  }) async {
    final now = DateTime.now();
    final txn = Transaction(
      id: _newId(),
      title: title,
      amount: amount,
      type: type,
      date: date,
      category: category,
      note: note,
      createdAt: now,
      updatedAt: now,
      recurring: recurring,
    );
    await TransactionService.addTransaction(uid, txn);
  }

  static Future<void> updateTransaction(Transaction txn) async {
    await TransactionService.updateTransaction(uid, txn.copyWith());
  }

  static Future<void> deleteTransaction(Transaction txn) async {
    final occurrenceIds = transactions.value
        .where((t) => t.sourceId == txn.id)
        .map((t) => t.id)
        .toList();
    await TransactionService.deleteTransaction(uid, txn,
        occurrenceIds: occurrenceIds);
  }

  // ─── Settings persistence ───────────────────────────────────────────────

  static Future<void> saveSettings() async {
    await TransactionService.saveSettings(uid, {
      'name': displayName.value,
      'currency': currencyCode.value,
      'themeMode': themeMode.value.name,
      'notificationsEnabled': notificationsEnabled.value,
      'monthlyBudget': monthlyBudget.value,
      'categoryBudgets': categoryBudgets.value,
    });
  }

  static String _newId() =>
      FirebaseFirestore.instance.collection('transactions').doc().id;
}