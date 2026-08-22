import 'package:expense_track/data/data.dart';
import 'package:expense_track/models/transaction.dart';
import 'package:expense_track/widgets/states.dart';
import 'package:expense_track/widgets/transaction_detail_sheet.dart';
import 'package:expense_track/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';

enum _TypeFilter { all, income, expense }

enum _DateFilter { all, today, week, month, custom }

enum _SortBy { newest, oldest, highest, lowest }

class ViewAll extends StatefulWidget {
  const ViewAll({super.key});

  @override
  State<ViewAll> createState() => _ViewAllState();
}

class _ViewAllState extends State<ViewAll> {
  final _searchController = TextEditingController();

  _TypeFilter _typeFilter = _TypeFilter.all;
  _DateFilter _dateFilter = _DateFilter.all;
  _SortBy _sortBy = _SortBy.newest;
  DateTimeRange? _customRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _applyFilters(List<Transaction> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));
    final monthStart = DateTime(now.year, now.month, 1);

    final query = _searchController.text.trim().toLowerCase();

    var result = all.where((t) {
      if (_typeFilter == _TypeFilter.income && !t.isIncome) return false;
      if (_typeFilter == _TypeFilter.expense && t.isIncome) return false;

      final day = DateTime(t.date.year, t.date.month, t.date.day);
      switch (_dateFilter) {
        case _DateFilter.today:
          if (day != today) return false;
        case _DateFilter.week:
          if (day.isBefore(weekStart) || day.isAfter(today)) return false;
        case _DateFilter.month:
          if (day.isBefore(monthStart)) return false;
        case _DateFilter.custom:
          if (_customRange == null) return false;
          if (day.isBefore(_customRange!.start) ||
              day.isAfter(_customRange!.end)) {
            return false;
          }
        case _DateFilter.all:
          break;
      }

      if (query.isEmpty) return true;
      return t.title.toLowerCase().contains(query) ||
          t.category.toLowerCase().contains(query) ||
          t.note.toLowerCase().contains(query);
    }).toList();

    switch (_sortBy) {
      case _SortBy.newest:
        result.sort((a, b) => b.date.compareTo(a.date));
      case _SortBy.oldest:
        result.sort((a, b) => a.date.compareTo(b.date));
      case _SortBy.highest:
        result.sort((a, b) => b.amount.compareTo(a.amount));
      case _SortBy.lowest:
        result.sort((a, b) => a.amount.compareTo(b.amount));
    }
    return result;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );
    if (range != null && mounted) {
      setState(() {
        _customRange = range;
        _dateFilter = _DateFilter.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Transactions')),
      body: Column(
        children: [
          /// SEARCH
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by title, category or notes',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          /// TYPE + SORT FILTERS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<_TypeFilter>(
                    segments: const [
                      ButtonSegment(value: _TypeFilter.all, label: Text('All')),
                      ButtonSegment(
                          value: _TypeFilter.income, label: Text('Income')),
                      ButtonSegment(
                          value: _TypeFilter.expense, label: Text('Expense')),
                    ],
                    selected: {_typeFilter},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      setState(() => _typeFilter = selection.first);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<_SortBy>(
                  tooltip: 'Sort',
                  icon: const Icon(Icons.sort),
                  initialValue: _sortBy,
                  onSelected: (value) => setState(() => _sortBy = value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _SortBy.newest,
                      child: Text('Newest first'),
                    ),
                    PopupMenuItem(
                      value: _SortBy.oldest,
                      child: Text('Oldest first'),
                    ),
                    PopupMenuItem(
                      value: _SortBy.highest,
                      child: Text('Highest amount'),
                    ),
                    PopupMenuItem(
                      value: _SortBy.lowest,
                      child: Text('Lowest amount'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          /// DATE FILTER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<_DateFilter>(
                    initialValue: _dateFilter,
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: 'Date',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: _DateFilter.all,
                        child: Text('All dates'),
                      ),
                      DropdownMenuItem(
                        value: _DateFilter.today,
                        child: Text('Today'),
                      ),
                      DropdownMenuItem(
                        value: _DateFilter.week,
                        child: Text('This week'),
                      ),
                      DropdownMenuItem(
                        value: _DateFilter.month,
                        child: Text('This month'),
                      ),
                      DropdownMenuItem(
                        value: _DateFilter.custom,
                        child: Text('Custom range'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      if (value == _DateFilter.custom) {
                        _pickCustomRange();
                        return;
                      }
                      setState(() => _dateFilter = value);
                    },
                  ),
                ),
                if (_dateFilter == _DateFilter.custom && _customRange != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TextButton(
                      onPressed: () {
                        setState(() => _dateFilter = _DateFilter.all);
                      },
                      child: const Text('Clear'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          /// LIST
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
                final filtered = _applyFilters(list);
                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    message: 'No matching transactions',
                    subMessage: 'Try changing the search or filters',
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final txn = filtered[i];
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
    );
  }
}