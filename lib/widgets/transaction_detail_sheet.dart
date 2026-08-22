import 'package:expense_track/constants.dart';
import 'package:expense_track/data/data.dart';
import 'package:expense_track/models/transaction.dart';
import 'package:expense_track/screens/add_expense/views/add_expense.dart';
import 'package:expense_track/utils/formatters.dart';
import 'package:expense_track/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';

/// Bottom sheet showing transaction details with Edit and Delete actions.
Future<void> showTransactionDetail(BuildContext context, Transaction txn) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _TransactionDetailSheet(transaction: txn),
  );
}

class _TransactionDetailSheet extends StatefulWidget {
  const _TransactionDetailSheet({required this.transaction});

  final Transaction transaction;

  @override
  State<_TransactionDetailSheet> createState() =>
      _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<_TransactionDetailSheet> {
  bool _deleting = false;
  bool _navigating = false;

  Future<void> _delete() async {
    if (_deleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text(
            'Are you sure you want to delete "${widget.transaction.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _deleting = true;
    try {
      await AppData.deleteTransaction(widget.transaction);
      if (!mounted) return;
      Navigator.pop(context); // close detail sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted')),
      );
    } catch (e) {
      _deleting = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Formatters.friendlyError(e))),
      );
    }
  }

  void _edit() {
    if (_navigating) return;
    _navigating = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpense(transaction: widget.transaction),
      ),
    ).then((_) => _navigating = false);
  }

  @override
  Widget build(BuildContext context) {
    final txn = widget.transaction;
    final color = txn.isIncome ? Colors.green : Colors.red;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(
                  TransactionTile.categoryIcon(txn.category),
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txn.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${txn.category} • ${Formatters.date(txn.date)}',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.signedAmount(txn.amount, isIncome: txn.isIncome),
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (txn.note.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Note: ${txn.note}'),
            ),
          if (txn.isRecurring) ...[
            const SizedBox(height: 12),
            Text(
              'Repeats ${AppConstants.recurringLabels[txn.recurring] ?? txn.recurring}',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _deleting ? null : _delete,
                  icon: _deleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _edit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}