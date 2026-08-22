import 'package:expense_track/app.dart';
import 'package:expense_track/data/data.dart';
import 'package:expense_track/firebase_options.dart';
import 'package:expense_track/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  AuthService.userStream.listen(AppData.onAuthChanged);

  runApp(const MyApp());
}