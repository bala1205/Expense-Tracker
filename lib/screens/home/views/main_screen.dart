import 'dart:math';

import 'package:expense_track/data/data.dart';
import 'package:expense_track/screens/settings/settings_screen.dart';
import 'package:expense_track/utils/formatters.dart';
import 'package:expense_track/view_all.dart';
import 'package:expense_track/widgets/states.dart';
import 'package:expense_track/widgets/transaction_detail_sheet.dart';
import 'package:expense_track/widgets/transaction_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isPushing = false;
  String? _lastAlert;

  @override
  void initState() {
    super.initState();
    AppData.budgetAlert.addListener(_onBudgetAlert);
  }

  @override
  void dispose() {
    AppData.budgetAlert.removeListener(_onBudgetAlert);
    super.dispose();
  }

  void _onBudgetAlert() {
    final message = AppData.budgetAlert.value;
    if (message == null || message == _lastAlert) return;
    _lastAlert = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  void _openSettings() {
    if (_isPushing) return;
    _isPushing = true;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    ).then((_) => _isPushing = false);
  }

  void _openViewAll() {
    if (_isPushing) return;
    _isPushing = true;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ViewAll()),
    ).then((_) => _isPushing = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppData.currencyCode,
      builder: (context, _, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Column(
              children: [
                /// 🔹 TOP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "EXPENSE TRACKER",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    IconButton(
                      onPressed: _openSettings,
                      icon: const Icon(CupertinoIcons.settings),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                /// 🔹 BALANCE CARD
                _BalanceCard(),
                const SizedBox(height: 16),

                /// 🔹 THIS MONTH SUMMARY
                _MonthSummaryCard(),
                const SizedBox(height: 16),

                /// 🔹 BUDGET
                ValueListenableBuilder<double>(
                  valueListenable: AppData.monthlyBudget,
                  builder: (context, budget, _) {
                    if (budget <= 0) return const SizedBox.shrink();
                    return _BudgetCard(budget: budget);
                  },
                ),
                const SizedBox(height: 16),

                /// 🔹 TRANSACTIONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(5, 5, 0, 0),
                      child: Text(
                        "Transactions",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _openViewAll,
                      child: const Text("View All"),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                /// 🔹 RECENT LIST / STATES
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: AppData.transactions,
                    builder: (context, list, _) {
                      if (AppData.isLoading.value) {
                        return const LoadingState();
                      }
                      if (AppData.errorMessage.value != null) {
                        return Column(
                          children: [
                            ErrorBanner(message: AppData.errorMessage.value!),
                            TextButton(
                              onPressed: () => AppData.init(),
                              child: const Text('Retry'),
                            ),
                          ],
                        );
                      }
                      if (list.isEmpty) {
                        return const EmptyState(
                          icon: Icons.receipt_long,
                          message: 'No transactions yet',
                          subMessage: 'Tap + to add your first transaction',
                        );
                      }
                      return ListView.builder(
                        itemCount: list.length > 5 ? 5 : list.length,
                        itemBuilder: (context, i) {
                          final txn = list[i];
                          return TransactionTile(
                            transaction: txn,
                            onTap: () => showTransactionDetail(context, txn),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 🔹 Balance card — keeps the original gradient design, adds today's totals.
class _BalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            scheme.secondary,
            scheme.tertiary,
          ],
          transform: const GradientRotation(pi / 4),
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          const Text(
            "Total Balance",
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<double>(
            valueListenable: AppData.totalBalance,
            builder: (context, value, _) => Text(
              Formatters.amount(value),
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: AppData.income,
                builder: (context, value, _) => Text(
                  "Income ${Formatters.amount(value, decimals: 0)}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: AppData.expense,
                builder: (context, value, _) => Text(
                  "Expense ${Formatters.amount(value, decimals: 0)}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: AppData.todayIncome,
                  builder: (context, value, _) => Text(
                    "Today in: ${Formatters.amount(value, decimals: 0)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ValueListenableBuilder<double>(
                  valueListenable: AppData.todayExpense,
                  builder: (context, value, _) => Text(
                    "Today out: ${Formatters.amount(value, decimals: 0)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔹 This month income / expense / savings.
class _MonthSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Month (${Formatters.monthYear(DateTime.now())})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder(
            valueListenable: AppData.transactions,
            builder: (context, _, _) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryItem(
                  label: 'Income',
                  value: Formatters.amount(AppData.monthIncome.value,
                      decimals: 0),
                  color: Colors.green,
                ),
                _SummaryItem(
                  label: 'Expense',
                  value: Formatters.amount(AppData.monthExpense.value,
                      decimals: 0),
                  color: Colors.red,
                ),
                _SummaryItem(
                  label: 'Savings',
                  value: Formatters.amount(
                    AppData.monthIncome.value - AppData.monthExpense.value,
                    decimals: 0,
                  ),
                  color: scheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// 🔹 Monthly budget progress with warning states.
class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget});

  final double budget;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: AppData.monthExpense,
      builder: (context, spent, _) {
        final ratio = budget > 0 ? (spent / budget).clamp(0.0, 1.2) : 0.0;
        final remaining = budget - spent;
        final exceeded = spent >= budget;
        final approaching = !exceeded && spent >= budget * 0.8;
        final barColor = exceeded
            ? Colors.redAccent
            : approaching
                ? Colors.amber
                : Theme.of(context).colorScheme.primary;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Monthly Budget',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${Formatters.amount(spent, decimals: 0)} / ${Formatters.amount(budget, decimals: 0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio.toDouble(),
                  minHeight: 8,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    exceeded
                        ? 'Budget exceeded by ${Formatters.amount(-remaining, decimals: 0)}'
                        : 'Remaining: ${Formatters.amount(remaining, decimals: 0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: exceeded
                          ? Colors.redAccent
                          : approaching
                              ? Colors.amber.shade800
                              : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (approaching && !exceeded)
                    Text(
                      '⚠ Approaching limit',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (exceeded)
                    const Text(
                      '⚠ Budget exceeded',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}