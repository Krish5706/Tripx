
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db_helper.dart';
import 'profile_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const SettingsScreen({
    Key? key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoSave = true;

  ThemeMode? _selectedThemeMode;
  String? _userEmail;
  Map<String, dynamic>? _userProfile;
  File? _profileImage;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    _selectedThemeMode = widget.currentThemeMode;
    super.initState();
    _loadUserProfile();
  }

  void _onThemeChanged(String? value) {
    if (value == null) return;
    final mode = value == 'System'
        ? ThemeMode.system
        : value == 'Dark'
            ? ThemeMode.dark
            : ThemeMode.light;

    setState(() => _selectedThemeMode = mode);
    widget.onThemeChanged(mode);
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final profileImagePath = prefs.getString('profileImagePath');
    File? imageFile;
    if (profileImagePath != null && profileImagePath.isNotEmpty) {
      final file = File(profileImagePath);
      if (await file.exists()) {
        imageFile = file;
      }
    }
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _userEmail = prefs.getString('userEmail') ?? 'user@qmail.com';
        _userProfile = null;
        _profileImage = null;
      });
      return;
    }

    final profile = await _databaseHelper.getUserById(userId);
    if (!mounted) return;
    setState(() {
      _userProfile = profile;
      _userEmail = profile?['email'] ?? prefs.getString('userEmail') ?? 'user@qmail.com';
      _profileImage = imageFile;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored data on logout
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader("Profile"),
          _modernTile(
            leading: _profileImage != null
                ? CircleAvatar(
                    radius: 40,
                    backgroundImage: FileImage(_profileImage!),
                  )
                : const CircleAvatar(radius: 40, child: Icon(Icons.person)),
            title: _userProfile != null && _userProfile!['name'] != null
                ? _userProfile!['name']
                : 'Loading...',
            subtitle: _userEmail ?? '',
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
              );
              if (result == true) {
                // Refresh profile data after edit
                _loadUserProfile();
              }
            },
          ),
          const SizedBox(height: 24),

          _sectionHeader("Theme"),
          _modernTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: "App Theme",
            trailing: DropdownButton<String>(
              value: _selectedThemeModeToString(),
              items: const [
                DropdownMenuItem(value: 'System', child: Text('System Default')),
                DropdownMenuItem(value: 'Light', child: Text('Light Mode')),
                DropdownMenuItem(value: 'Dark', child: Text('Dark Mode')),
              ],
              onChanged: _onThemeChanged,
            ),
          ),
          const SizedBox(height: 24),

          _sectionHeader("App Preferences"),
          _switchTile(
            icon: Icons.save,
            title: "Auto Save",
            subtitle: "Automatically save app data",
            value: _autoSave,
            onChanged: (value) => setState(() => _autoSave = value),
          ),
          const SizedBox(height: 24),

          _sectionHeader("Data & Privacy"),
          _modernTile(
            leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
            title: "Clear App Data",
            subtitle: "Remove all locally stored data",
            onTap: _confirmClearData,
          ),
          _modernTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: "Privacy Policy",
            onTap: () {}, // Add navigation
          ),
          _modernTile(
            leading: const Icon(Icons.description_outlined),
            title: "Terms of Service",
            onTap: () {}, // Add navigation
          ),
          const SizedBox(height: 24),

          _sectionHeader("Support"),
          _modernTile(
            leading: const Icon(Icons.help_outline),
            title: "Help & FAQ",
            onTap: () {},
          ),
          _modernTile(
            leading: const Icon(Icons.feedback_outlined),
            title: "Send Feedback",
            onTap: () {},
          ),
          const SizedBox(height: 24),

          _sectionHeader("About"),
          _modernTile(
            leading: const Icon(Icons.info_outline),
            title: "App Version",
            subtitle: "v1.0.0",
          ),
          const SizedBox(height: 24),

          _sectionHeader("Account"),
          _modernTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: "Logout",
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  String _selectedThemeModeToString() {
    switch (_selectedThemeMode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
      default:
        return 'System';
    }
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear App Data'),
        content: const Text(
            'Are you sure you want to remove all app data? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: Add your data clearing logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App data cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _modernTile({
    required Widget leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: leading,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon),
      ),
    );
  }
}
