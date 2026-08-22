import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_track/utils/formatters.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<User?> get userStream => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  /// Real Firebase email/password sign-in. The exception (if any) propagates
  /// to the caller with its FirebaseAuthException code intact.
  static Future<User> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'operation-not-allowed',
          message: 'Sign-in returned no user.',
        );
      }
      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Unexpected sign-in error: $e');
      rethrow;
    }
  }

  /// Real Firebase email/password registration.
  ///
  /// Returns the created Firebase user. The Firestore profile is created
  /// separately by [ensureProfile] and its failure never fails the
  /// registration itself: the Firebase Authentication user is the source of
  /// truth and is created regardless.
  static Future<User> registerWithEmail(
    String email,
    String password, {
    String? name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'Registration returned no user.',
      );
    }
    if (name != null && name.trim().isNotEmpty) {
      try {
        await user.updateDisplayName(name.trim());
      } catch (e) {
        debugPrint('displayName update failed: $e');
      }
    }
    await ensureProfile(user, name: name);
    return user;
  }

  /// Seeds `users/{uid}` with the profile fields. Uses merge so settings
  /// written later are never clobbered. Does not store the password.
  static Future<void> ensureProfile(User user, {String? name}) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
            {
              'uid': user.uid,
              'name': (name ?? user.displayName ?? '').trim(),
              'email': user.email ?? '',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('Firestore profile creation failed (auth is unaffected): '
          '${Formatters.authError(e)}');
    }
  }

  static Future<void> signInAsGuest() async {
    final credential = await _auth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'Guest sign-in returned no user.',
      );
    }
  }

  static Future<void> linkGuestToEmail(
    String email,
    String password, {
    String? name,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    final result = await user.linkWithCredential(credential);
    if (name != null && name.trim().isNotEmpty) {
      await result.user?.updateDisplayName(name.trim());
    }
  }

  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  static Future<void> updateName(String name) async {
    await _auth.currentUser?.updateDisplayName(name.trim());
  }

  static Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
