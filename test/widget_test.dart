import 'package:expense_track/data/data.dart';
import 'package:expense_track/screens/add_expense/views/add_expense.dart';
import 'package:expense_track/screens/home/views/home_screen.dart';
import 'package:expense_track/screens/stats/stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tapSave(WidgetTester tester) async {
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

Future<void> dismissSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Dashboard smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('EXPENSE TRACKER'), findsOneWidget);
    expect(find.text('Total Balance'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('View All'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('AddExpense shows categories and type toggle',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddExpense()));

    expect(find.text('Add Transaction'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('Salary'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Freelance'), findsOneWidget);
    expect(find.text('Food'), findsNothing);
  });

  testWidgets('AddExpense validates input before saving',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddExpense()));

    await tapSave(tester);
    expect(find.text('Please enter a title'), findsOneWidget);
    await dismissSnackBar(tester);

    await tester.enterText(find.byType(TextField).at(0), 'Lunch');
    await tapSave(tester);
    expect(find.text('Please enter an amount'), findsOneWidget);
    await dismissSnackBar(tester);

    await tester.enterText(find.byType(TextField).at(1), '0');
    await tapSave(tester);
    expect(
      find.text('Amount must be a number greater than 0'),
      findsOneWidget,
    );
    await dismissSnackBar(tester);

    await tester.enterText(find.byType(TextField).at(1), '100');
    await tapSave(tester);
    expect(find.text('Please select a category'), findsOneWidget);
  });

  testWidgets('AddExpense shows friendly error when save fails',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddExpense()));

    await tester.enterText(find.byType(TextField).at(0), 'Lunch');
    await tester.enterText(find.byType(TextField).at(1), '100');
    await tester.ensureVisible(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food'));
    await tester.pump();

    await tapSave(tester);

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('Stats screen shows empty state', (WidgetTester tester) async {
    AppData.isLoading.value = false;
    AppData.transactions.value = const [];

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatsScreen())),
    );

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('No data for this period'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);
  });
}
