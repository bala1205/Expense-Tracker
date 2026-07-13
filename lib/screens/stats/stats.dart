import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_track/data/data.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          /// TITLE
          const Text(
            "Statistics",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          /// PIE CHART
          ValueListenableBuilder(
            valueListenable: AppData.totalBalance,
            builder: (context, value, child) {
              if (AppData.income.value == 0 &&
                  AppData.expense.value == 0) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text("No data for chart"),
                  ),
                );
              }

              return SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: AppData.income.value.toDouble(),
                        color: Colors.green,
                        title: "Income",
                        radius: 50,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PieChartSectionData(
                        value: AppData.expense.value.toDouble(),
                        color: Colors.red,
                        title: "Expense",
                        radius: 50,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          /// LABELS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              Row(
                children: [
                  Icon(Icons.circle, color: Colors.green, size: 12),
                  SizedBox(width: 5),
                  Text("Income"),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.circle, color: Colors.red, size: 12),
                  SizedBox(width: 5),
                  Text("Expense"),
                ],
              ),
            ],
          ),

          const SizedBox(height: 30),

          /// BAR CHART
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: AppData.transactions,
              builder: (context, list, child) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text("No transactions yet"),
                  );
                }

                return BarChart(
                  BarChartData(
                    barGroups: List.generate(list.length, (i) {
                      final data = list[i];

                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: (data['amount'] as num).toDouble(),
                            color: data['isIncome']
                                ? Colors.green
                                : Colors.red,
                            width: 12,
                          ),
                        ],
                      );
                    }),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}