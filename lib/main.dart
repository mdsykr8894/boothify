import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app/app.dart';
import 'data/seed/database_seeder.dart';
import 'firebase_options.dart';

void main() async {
  // Initialize Flutter before running async setup.
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep splash screen while Firebase is loading.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase for the current platform.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Run seed once manually, then comment this line after seed completed.
  // await DatabaseSeeder.seedLargeDemoData();

  // Start the Boothify app.
  runApp(const BoothifyApp());
}
