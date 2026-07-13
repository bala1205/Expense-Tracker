import 'package:expense_track/data/data.dart';
import 'package:flutter/material.dart';

class ViewAll extends StatelessWidget {
  const ViewAll({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Transactions"),
      ),

      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: AppData.transactions,
        builder: (context, transactions, child) {

          if (transactions.isEmpty) {
            return const Center(
              child: Text("No Transactions"),
            );
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {

              final transaction = transactions[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: transaction['color'],
                  child: Icon(
                    transaction['icon'],
                    color: Colors.white,
                  ),
                ),

                title: Text(transaction['name']),

                subtitle: Text(transaction['date']),

                trailing: Text(
                  "${transaction['isIncome'] ? '+' : '-'} ₹${transaction['amount']}",
                  style: TextStyle(
                    color: transaction['color'],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}