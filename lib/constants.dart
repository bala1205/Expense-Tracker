import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Expense Tracker';
  static const String appVersion = '1.0.0+1';

  static const List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Travel', 'icon': Icons.directions_bus},
    {'name': 'Shopping', 'icon': Icons.shopping_bag},
    {'name': 'Bills', 'icon': Icons.receipt_long},
    {'name': 'Education', 'icon': Icons.school},
    {'name': 'Health', 'icon': Icons.favorite},
    {'name': 'Entertainment', 'icon': Icons.movie},
    {'name': 'Rent', 'icon': Icons.home},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];

  static const List<Map<String, dynamic>> incomeCategories = [
    {'name': 'Salary', 'icon': Icons.payments},
    {'name': 'Freelance', 'icon': Icons.laptop},
    {'name': 'Business', 'icon': Icons.storefront},
    {'name': 'Investment', 'icon': Icons.trending_up},
    {'name': 'Gift', 'icon': Icons.card_giftcard},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];

  static const List<String> recurringOptions = [
    'none',
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  static const Map<String, String> recurringLabels = {
    'none': 'Does not repeat',
    'daily': 'Daily',
    'weekly': 'Weekly',
    'monthly': 'Monthly',
    'yearly': 'Yearly',
  };

  static const List<Map<String, String>> currencies = [
    {'code': 'INR', 'symbol': '₹'},
    {'code': 'USD', 'symbol': r'$'},
    {'code': 'EUR', 'symbol': '€'},
    {'code': 'GBP', 'symbol': '£'},
    {'code': 'JPY', 'symbol': '¥'},
  ];

  static const Map<String, String> currencySymbols = {
    'INR': '₹',
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
  };
}