import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const String _wallpaperKey = 'wallpaper_path';
  static const String _notificationsKey = 'enable_notifications';
  static const String _wallpaperTypeKey =
      'wallpaper_type'; // 'color', 'image', 'gradient'

  final SharedPreferences _prefs;

  String? _wallpaperPath;
  String _wallpaperType = 'color'; // Default to solid color
  int _backgroundColorCheck = 0xFFFFFFFF; // Default white background
  bool _enableNotifications = true;

  SettingsController(this._prefs) {
    _loadSettings();
  }

  // Getters
  String? get wallpaperPath => _wallpaperPath;
  String get wallpaperType => _wallpaperType;
  Color get backgroundColor => Color(_backgroundColorCheck);
  bool get enableNotifications => _enableNotifications;

  void _loadSettings() {
    _wallpaperPath = _prefs.getString(_wallpaperKey);
    _wallpaperType = _prefs.getString(_wallpaperTypeKey) ?? 'color';
    _backgroundColorCheck = _prefs.getInt('background_color') ?? 0xFF121212;
    _enableNotifications = _prefs.getBool(_notificationsKey) ?? true;
    notifyListeners();
  }

  Future<void> setWallpaperType(String type) async {
    _wallpaperType = type;
    await _prefs.setString(_wallpaperTypeKey, type);
    notifyListeners();
  }

  Future<void> setBackgroundColor(Color color) async {
    _backgroundColorCheck = color.value;
    await _prefs.setInt('background_color', color.value);
    await setWallpaperType('color'); // Switch to color mode
    notifyListeners();
  }

  Future<void> setWallpaperImage(String path) async {
    _wallpaperPath = path;
    await _prefs.setString(_wallpaperKey, path);
    await setWallpaperType('image'); // Switch to image mode
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _enableNotifications = value;
    await _prefs.setBool(_notificationsKey, value);
    notifyListeners();
  }
}
