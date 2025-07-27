import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tripx/screens/dashboard_screen.dart';
import 'package:tripx/screens/login_screen.dart';
import 'package:tripx/screens/setting_screen.dart';
import 'package:tripx/screens/splash_screen.dart';
import 'package:tripx/services/db_helper.dart';
import 'package:tripx/screens/trip_details/notes.dart';

void main() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    DatabaseHelper.initFfi();
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _updateThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TripX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/settings': (context) => SettingsScreen(
              currentThemeMode: _themeMode,
              onThemeChanged: _updateThemeMode,
            ),
        // Future screens can be added below
        // '/destination': (context) => const DestinationIdeasScreen(),
        // '/trip_planner': (context) => const CreateTripScreen(),
        // '/schedule': (context) => const ScheduleScreen(),
        // '/packing_list': (context) => const PackingListScreen(),
        '/notes': (context) => const NotesScreen(),
        // '/expenses': (context) => const ExpensesScreen(),
      },
    );
  }
}
