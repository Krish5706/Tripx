import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoProvider extends ChangeNotifier {
  String _version = '';
  String _buildNumber = '';
  bool _isLoading = true;

  AppInfoProvider() {
    _loadAppInfo();
  }

  String get version => _version;
  String get buildNumber => _buildNumber;
  bool get isLoading => _isLoading;

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _version = 'Unknown';
      _buildNumber = 'Unknown';
      _isLoading = false;
      notifyListeners();
    }
  }
}