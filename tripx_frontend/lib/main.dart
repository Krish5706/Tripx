// File: lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripx_frontend/providers/theme_provider.dart';
import 'package:tripx_frontend/screens/auth/login_screen.dart';
import 'package:tripx_frontend/screens/auth/register_screen.dart';
import 'package:tripx_frontend/screens/dashboard/dashboard_screen.dart';
import 'package:tripx_frontend/screens/destinations/destination_detail_screen.dart';
import 'package:tripx_frontend/screens/destinations/destination_ideas_screen.dart';
import 'package:tripx_frontend/screens/profile/profile_edit_screen.dart';
import 'package:tripx_frontend/screens/profile/setting_screen.dart';
import 'package:tripx_frontend/screens/splash_screen.dart';
import 'package:tripx_frontend/screens/translator/language_selection_screen.dart';
import 'package:tripx_frontend/screens/translator/translator_screen.dart';
import 'package:tripx_frontend/screens/trip/create_trip_screen.dart';
import 'package:tripx_frontend/screens/trip/trip_details/expenses_screen.dart';
import 'package:tripx_frontend/screens/trip/trip_details/notes_screen.dart';
import 'package:tripx_frontend/screens/trip/trip_details/packing_list_screen.dart';
import 'package:tripx_frontend/screens/trip/trip_details/schedule_screen.dart';
import 'package:tripx_frontend/screens/trip/trip_details/trip_detail_dashboard.dart';
import 'package:tripx_frontend/screens/trip/trip_selection_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Load saved theme preference
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(initialIsDark: isDark),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'TripX',
      debugShowCheckedModeBanner: false,

      // 🌗 Theme now responds to provider
      themeMode: themeProvider.themeMode,

      // ☀️ Light Theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          primary: const Color(0xFF1565C0),
          secondary: const Color(0xFFFFC107),
          surface: Colors.grey[100],
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
          titleMedium: TextStyle(
            color: Color(0xFF424242),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          shadowColor: Colors.grey.withValues(alpha: 0.2),
          scrolledUnderElevation: 4,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
        ),
        cardTheme: CardTheme.of(context).copyWith(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
          ),
        ),
      ),

      // 🌙 Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          brightness: Brightness.dark,
          primary: const Color(0xFF90CAF9),
          secondary: const Color(0xFFFFC107),
          surface: Colors.grey[900],
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            color: Colors.white70,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.5),
          scrolledUnderElevation: 4,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
        ),
        cardTheme: CardTheme.of(context).copyWith(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF90CAF9),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[850],
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF90CAF9), width: 2),
          ),
        ),
      ),

      home: const SplashScreen(),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/trip-selection': (context) => const TripSelectionScreen(),
        '/create-trip': (context) => const CreateTripScreen(),
        '/trip-detail-dashboard': (context) => const TripDetailDashboard(),
        '/schedule': (context) => const ScheduleScreen(),
        '/expenses': (context) => const ExpensesScreen(),
        '/notes': (context) => const NotesScreen(),
        '/packing-list': (context) => const PackingListScreen(),
        '/settings': (context) => const SettingScreen(),
        '/profile-edit': (context) => const ProfileEditScreen(),
        '/translator': (context) => const TranslatorScreen(),
        '/language-selection': (context) =>
            const LanguageSelectionScreen(selectedLanguageCode: 'en'),
        '/destination-ideas': (context) => const DestinationIdeasScreen(),
        '/destination-detail': (context) => const DestinationDetailScreen(),
      },
    );
  }
}