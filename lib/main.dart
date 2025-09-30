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
import 'package:tripx/screens/trip_details/packing_list.dart';
import 'package:tripx/screens/trip_details/expenses.dart'; 
import 'package:tripx/screens/trip_details/schedule.dart'; 
import 'package:tripx/screens/trip_selection_screen.dart'; 
import 'package:tripx/screens/create_trip_screen.dart'; 
import 'package:tripx/screens/destination_ideas_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load environment variables from .env
  // await dotenv.load(fileName: ".env");

  // ✅ Initialize SQLite FFI for desktop
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
        '/destination_ideas': (context) => const DestinationIdeasScreen(),
        '/trip_selection': (context) => const TripSelectionScreen(),
        '/create_trip': (context) => const CreateTripScreen(),
        '/schedule': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/dashboard');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return ScheduleScreen(
            tripId: args['tripId'] as int,
            tripName: args['tripName'] as String,
          );
        },
        '/packing_list': (context) => const PackingListScreen(),
        '/notes': (context) => const NotesScreen(),
        '/expenses': (context) => const ExpenseScreen(),
      },
    );
  }
}
