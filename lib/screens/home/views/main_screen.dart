import 'dart:math';
import 'package:expense_track/view_all.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expense_track/data/data.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Column(
          children: [
            /// 🔹 TOP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("EXPENSE TRACKER",style: TextStyle(fontSize: 25,fontWeight: FontWeight.w400,color: Colors.black54),),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(CupertinoIcons.settings),
                )
              ],
            ),

            const SizedBox(height: 20),

            /// 🔹 BALANCE CARD
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                  transform: const GradientRotation(pi / 4),
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Total Balance",
                    style: TextStyle(color: Colors.white),
                  ),

                  /// 🔥 BALANCE
                  ValueListenableBuilder(
                    valueListenable: AppData.totalBalance,
                    builder: (context, value, child) {
                      return Text(
                        "₹ ${value.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  /// 🔹 INCOME / EXPENSE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ValueListenableBuilder(
                        valueListenable: AppData.income,
                        builder: (context, value, child) {
                          return Text(
                            "Income ₹${value.toStringAsFixed(0)}",
                            style: const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                      ValueListenableBuilder(
                        valueListenable: AppData.expense,
                        builder: (context, value, child) {
                          return Text(
                            "Expense ₹${value.toStringAsFixed(0)}",
                            style: const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 TITLE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(5,5,0,0),
                  child: Text("Transactions"),

                ),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewAll(),
                      ),
                    );
                  },

                  child: const Text("View All"),

                ),
              ],

            ),



            const SizedBox(height: 10),

            /// 🔹 LIST
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: AppData.transactions,
                builder: (context, list, child) {
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final data = list[i];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: data['color'],
                          child: Icon(data['icon'], color: Colors.white),
                        ),
                        title: Text(data['name']),
                        subtitle: Text(data['date']),

                        /// 🔥 FINAL FIX (Income / Expense UI)
                        trailing: Text(
                          data['isIncome']
                              ? "+₹${data['amount']}"
                              : "-₹${data['amount']}",
                          style: TextStyle(
                            color: data['isIncome']
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}