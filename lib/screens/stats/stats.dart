import 'package:expense_track/constants.dart';
import 'package:expense_track/data/data.dart';
import 'package:expense_track/models/transaction.dart';
import 'package:expense_track/utils/formatters.dart';
import 'package:expense_track/widgets/states.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

enum _Period { day, week, month, year }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  _Period _period = _Period.month;

  (DateTime, DateTime) get _range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case _Period.day:
        return (today, today);
      case _Period.week:
        return (today.subtract(const Duration(days: 6)), today);
      case _Period.month:
        return (DateTime(now.year, now.month, 1), today);
      case _Period.year:
        return (DateTime(now.year, 1, 1), today);
    }
  }

  String get _periodLabel {
    switch (_period) {
      case _Period.day:
        return 'Today';
      case _Period.week:
        return 'Last 7 days';
      case _Period.month:
        return Formatters.monthYear(DateTime.now());
      case _Period.year:
        return '${DateTime.now().year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<String>(
      valueListenable: AppData.currencyCode,
      builder: (context, _, _) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TITLE
              const Text(
                "Statistics",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              /// PERIOD SELECTOR
              Wrap(
                spacing: 8,
                children: [
                  for (final period in _Period.values)
                    ChoiceChip(
                      label: Text(_chipLabel(period)),
                      selected: _period == period,
                      onSelected: (_) => setState(() => _period = period),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ValueListenableBuilder<List<Transaction>>(
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

                    final (start, end) = _range;
                    final filtered = list
                        .where((t) {
                          final day =
                              DateTime(t.date.year, t.date.month, t.date.day);
                          return !day.isBefore(start) && !day.isAfter(end);
                        })
                        .toList();

                    return _buildStats(context, filtered, scheme);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _chipLabel(_Period period) {
    switch (period) {
      case _Period.day:
        return 'Daily';
      case _Period.week:
        return 'Weekly';
      case _Period.month:
        return 'Monthly';
      case _Period.year:
        return 'Yearly';
    }
  }

  Widget _buildStats(
      BuildContext context, List<Transaction> filtered, ColorScheme scheme) {
    double incomeTotal = 0;
    double expenseTotal = 0;
    final categoryExpense = <String, double>{};

    for (final t in filtered) {
      if (t.isIncome) {
        incomeTotal += t.amount;
      } else {
        expenseTotal += t.amount;
        categoryExpense[t.category] =
            (categoryExpense[t.category] ?? 0) + t.amount;
      }
    }

    if (filtered.isEmpty) {
      return const EmptyState(
        icon: Icons.insights,
        message: 'No data for this period',
        subMessage: 'Add transactions to see statistics',
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// SUMMARY TILES
          Text(
            _periodLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatTile(
                label: 'Income',
                value: Formatters.amount(incomeTotal, decimals: 0),
                color: Colors.green,
              ),
              const SizedBox(width: 10),
              _StatTile(
                label: 'Expense',
                value: Formatters.amount(expenseTotal, decimals: 0),
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatTile(
                label: 'Net savings',
                value: Formatters.amount(
                  incomeTotal - expenseTotal,
                  decimals: 0,
                ),
                color: scheme.primary,
              ),
              const SizedBox(width: 10),
              _StatTile(
                label: 'Transactions',
                value: '${filtered.length}',
                color: scheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 20),

          /// DONUT CHART
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Income vs Expense',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 45,
                      sections: [
                        PieChartSectionData(
                          value: incomeTotal,
                          color: Colors.green,
                          title: 'Income',
                          radius: 50,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        PieChartSectionData(
                          value: expenseTotal,
                          color: Colors.red,
                          title: 'Expense',
                          radius: 50,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.circle, color: Colors.green, size: 12),
                        SizedBox(width: 5),
                        Text('Income'),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.circle, color: Colors.red, size: 12),
                        SizedBox(width: 5),
                        Text('Expense'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          /// CATEGORY-WISE EXPENSE
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expense by category',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (categoryExpense.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: Text('No expenses in this period')),
                  )
                else
                  for (final entry in _sortedCategories(categoryExpense))
                    _CategoryBar(
                      category: entry.key,
                      amount: entry.value,
                      total: expenseTotal,
                      color: _categoryColor(entry.key),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<MapEntry<String, double>> _sortedCategories(
      Map<String, double> categoryExpense) {
    final sorted = categoryExpense.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.length > 6 ? sorted.sublist(0, 6) : sorted;
  }

  Color _categoryColor(String category) {
    final index = AppConstants.expenseCategories
        .indexWhere((c) => c['name'] == category);
    if (index < 0) return Colors.blueGrey;
    const colors = [
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.category,
    required this.amount,
    required this.total,
    required this.color,
  });

  final String category;
  final double amount;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${Formatters.amount(amount, decimals: 0)}  (${(fraction * 100).toStringAsFixed(0)}%)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.toDouble(),
              minHeight: 6,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}