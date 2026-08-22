import 'package:expense_track/constants.dart';
import 'package:expense_track/models/transaction.dart';
import 'package:expense_track/utils/formatters.dart';
import 'package:flutter/material.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  final Transaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcon(transaction.category);
    final color = transaction.isIncome ? Colors.green : Colors.red;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(
        transaction.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${transaction.category}  •  ${Formatters.date(transaction.date)}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Formatters.signedAmount(transaction.amount,
                isIncome: transaction.isIncome),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          if (transaction.isRecurring)
            const Text(
              'repeats',
              style: TextStyle(fontSize: 10, color: Colors.blueGrey),
            ),
        ],
      ),
    );
  }

  static IconData categoryIcon(String category) => _categoryIcon(category);
}

IconData _categoryIcon(String category) {
  for (final c in AppConstants.expenseCategories) {
    if (c['name'] == category) return c['icon'] as IconData;
  }
  for (final c in AppConstants.incomeCategories) {
    if (c['name'] == category) return c['icon'] as IconData;
  }
  return Icons.more_horiz;
}