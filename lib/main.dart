import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Load env file
  await dotenv.load(fileName: ".env");

  // Open necessary boxes
  await Hive.openBox('settingsBox');
  await Hive.openBox('historyBox');

  runApp(const ProviderScope(child: AgroNetApp()));
}
