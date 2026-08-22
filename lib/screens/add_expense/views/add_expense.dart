import 'dart:math';

import 'package:expense_track/constants.dart';
import 'package:expense_track/data/data.dart';
import 'package:expense_track/models/transaction.dart';
import 'package:expense_track/utils/formatters.dart';
import 'package:flutter/material.dart';

class AddExpense extends StatefulWidget {
  const AddExpense({super.key, this.transaction});

  /// When provided, the screen runs in edit mode.
  final Transaction? transaction;

  bool get isEditing => transaction != null;

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  late bool isIncome;
  late DateTime selectedDate;
  late String recurring;
  String? selectedCategory;
  final List<String> _customCategories = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final txn = widget.transaction;
    isIncome = txn?.isIncome ?? false;
    selectedDate = txn?.date ?? DateTime.now();
    recurring = txn?.recurring ?? 'none';

    if (txn != null) {
      titleController.text = txn.title;
      amountController.text = txn.amount.toStringAsFixed(2);
      noteController.text = txn.note;
      selectedCategory = txn.category;
      if (!_isBuiltInCategory(txn.category)) {
        _customCategories.add(txn.category);
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  bool _isBuiltInCategory(String category) {
    for (final c in AppConstants.expenseCategories) {
      if (c['name'] == category) return true;
    }
    for (final c in AppConstants.incomeCategories) {
      if (c['name'] == category) return true;
    }
    return false;
  }

  List<Map<String, dynamic>> get _categories => isIncome
      ? AppConstants.incomeCategories
      : AppConstants.expenseCategories;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _addCustomCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    setState(() {
      _customCategories.add(name);
      selectedCategory = name;
    });
  }

  Future<void> save() async {
    if (_isSaving) return;

    String title = titleController.text.trim();
    String amountText = amountController.text.trim();

    if (title.isEmpty) {
      _showMessage('Please enter a title');
      return;
    }
    if (amountText.isEmpty) {
      _showMessage('Please enter an amount');
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showMessage('Amount must be a number greater than 0');
      return;
    }
    if (selectedCategory == null) {
      _showMessage('Please select a category');
      return;
    }

    _isSaving = true;

    try {
      if (widget.isEditing) {
        await AppData.updateTransaction(
          widget.transaction!.copyWith(
            title: title,
            amount: amount,
            type: isIncome ? 'income' : 'expense',
            date: selectedDate,
            category: selectedCategory,
            note: noteController.text.trim(),
            recurring: recurring,
          ),
        );
        if (!mounted) return;
        _showMessage('Transaction updated');
      } else {
        await AppData.addTransaction(
          title: title,
          amount: amount,
          type: isIncome ? 'income' : 'expense',
          date: selectedDate,
          category: selectedCategory!,
          note: noteController.text.trim(),
          recurring: recurring,
        );
        if (!mounted) return;
        _showMessage('Transaction saved successfully');
      }
      Navigator.pop(context);
    } catch (e) {
      _isSaving = false;
      if (!mounted) return;
      _showMessage(Formatters.friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TYPE TOGGLE (Expense / Income)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Expense',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Switch(
                  value: isIncome,
                  onChanged: (value) {
                    setState(() {
                      isIncome = value;
                      if (selectedCategory != null &&
                          !_categories.any((c) => c['name'] == selectedCategory)) {
                        selectedCategory = null;
                      }
                    });
                  },
                ),
                const Text(
                  'Income',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// TITLE
            TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),

            /// AMOUNT
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${AppData.currencySymbol} ',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 12),

            /// DATE
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(Formatters.date(selectedDate)),
              ),
            ),
            const SizedBox(height: 20),

            /// CATEGORY
            Text(
              'Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in _categories)
                  ChoiceChip(
                    avatar: Icon(
                      cat['icon'] as IconData,
                      size: 18,
                      color: selectedCategory == cat['name']
                          ? Colors.white
                          : null,
                    ),
                    label: Text(cat['name'] as String),
                    selected: selectedCategory == cat['name'],
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = selected ? cat['name'] as String : null;
                      });
                    },
                  ),
                for (final cat in _customCategories)
                  ChoiceChip(
                    label: Text(cat),
                    selected: selectedCategory == cat,
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = selected ? cat : null;
                      });
                    },
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Custom'),
                  onPressed: _addCustomCategory,
                ),
              ],
            ),
            const SizedBox(height: 20),

            /// NOTES
            TextField(
              controller: noteController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),

            /// RECURRING
            DropdownButtonFormField<String>(
              initialValue: recurring,
              decoration: const InputDecoration(
                labelText: 'Repeat',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat),
              ),
              items: [
                for (final option in AppConstants.recurringOptions)
                  DropdownMenuItem(
                    value: option,
                    child: Text(AppConstants.recurringLabels[option]!),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => recurring = value);
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: GestureDetector(
          onTap: _isSaving ? null : save,
          child: Container(
            height: 56,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                  Theme.of(context).colorScheme.tertiary,
                ],
                transform: const GradientRotation(pi / 4),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.isEditing ? 'Update' : 'Save',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}