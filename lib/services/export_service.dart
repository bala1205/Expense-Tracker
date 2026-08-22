import 'dart:io';

import 'package:expense_track/models/transaction.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  ExportService._();

  static String buildCsv(List<Transaction> transactions) {
    final buffer = StringBuffer();
    buffer.writeln('Date,Title,Category,Type,Amount,Notes');

    for (final t in transactions) {
      final date = DateFormat('yyyy-MM-dd').format(t.date);
      final amount = t.amount.toStringAsFixed(2);
      final type = t.isIncome ? 'Income' : 'Expense';
      final note = t.note.replaceAll(',', ' ').replaceAll('\n', ' ');
      final title = t.title.replaceAll(',', ' ');
      buffer.writeln('$date,$title,${t.category},$type,$amount,$note');
    }
    return buffer.toString();
  }

  static Future<File> writeCsvFile(String csv) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/expense_export_$timestamp.csv');
    await file.writeAsString(csv);
    return file;
  }

  static Future<void> exportAndShare(List<Transaction> transactions) async {
    final file = await writeCsvFile(buildCsv(transactions));
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      text: 'Expense Tracker export',
    );
  }
}