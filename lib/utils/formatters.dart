import 'package:expense_track/data/data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String amount(double value, {int decimals = 2}) {
    final symbol = AppData.currencySymbol;
    final text = value.toStringAsFixed(decimals);
    if (symbol == '₹') return '$symbol$text';
    return '$symbol$text';
  }

  static String signedAmount(double value, {bool isIncome = true}) {
    final prefix = isIncome ? '+' : '-';
    return '$prefix${amount(value)}';
  }

  static String date(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  static String monthYear(DateTime date) =>
      DateFormat('MMM yyyy').format(date);

  static String dayOfMonth(DateTime date) => DateFormat('d').format(date);

  static String monthName(DateTime date) => DateFormat('MMM').format(date);

  /// Maps a Firebase Auth error code to a user-friendly message.
  ///
  /// Every branch returns a specific message instead of hiding the error
  /// behind a generic one, so the user knows exactly what went wrong.
  static String authError(Object error, {FirebaseAuthException? exception}) {
    final e = exception ?? (error is FirebaseAuthException ? error : null);
    if (e != null) {
      debugPrint('FirebaseAuthException code="${e.code}" message="${e.message}"');
      switch (e.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-password':
          return 'Invalid email or password.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled for this app.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'network-request-failed':
          return 'Please check your internet connection.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'requires-recent-login':
          return 'Please sign in again before making this change.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with a different sign-in method.';
        case 'invalid-verification-code':
          return 'The verification code is invalid.';
        case 'credential-already-in-use':
          return 'This credential is already linked to an account.';
        default:
          debugPrint('Unhandled FirebaseAuthException code="${e.code}"');
          return 'Unable to sign in. Please try again.';
      }
    }
    if (error is FirebaseException) {
      debugPrint('FirebaseException code="${error.code}" message="${error.message}"');
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to access this data.';
        case 'unavailable':
        case 'network-request-failed':
          return 'Network unavailable. Please check your connection.';
        case 'invalid-argument':
          return 'The data entered is invalid.';
        case 'not-found':
          return 'The requested data was not found.';
        case 'internal':
          return 'Something went wrong on the server. Try again.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    if (error is PlatformException) {
      debugPrint('PlatformException code="${error.code}" message="${error.message}"');
      return 'Something went wrong on this device. Please try again.';
    }
    debugPrint('Unhandled auth error: $error');
    return 'Something went wrong. Please try again.';
  }

  /// Kept for non-auth Firebase errors (e.g. Firestore) and other failures.
  static String friendlyError(Object error) {
    if (error is FirebaseAuthException) return authError(error);
    if (error is FirebaseException) return authError(error);
    if (error is FormatException) return 'The data entered is invalid.';
    return authError(error);
  }
}