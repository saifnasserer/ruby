import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const String _wallpaperPathKey = 'wallpaper_path';
  static const String _wallpaperTypeKey = 'wallpaper_type'; // 'color', 'image'
  static const String _wallpaperOpacityKey = 'wallpaper_opacity';
  static const String _backgroundColorKey = 'background_color';
  static const String _notificationsKey = 'enable_notifications';
  static const String _isAssetWallpaperKey = 'is_asset_wallpaper';
  static const String _darkModeKey = 'dark_mode';

  final SharedPreferences _prefs;

  String? _wallpaperPath;
  String _wallpaperType = 'image'; // Default to image
  double _wallpaperOpacity = 0.2; // Default to 20%
  int _backgroundColorValue = 0xFFFFFFFF; // Default white background
  bool _enableNotifications = true;
  bool _isAssetWallpaper = true;
  bool _isDarkMode = false;

  SettingsController(this._prefs) {
    _loadSettings();
  }

  // Getters
  String? get wallpaperPath => _wallpaperPath;
  String get wallpaperType => _wallpaperType;
  double get wallpaperOpacity => _wallpaperOpacity;
  Color get backgroundColor => Color(_backgroundColorValue);
  bool get enableNotifications => _enableNotifications;
  bool get isAssetWallpaper => _isAssetWallpaper;
  bool get isDarkMode => _isDarkMode;

  void _loadSettings() {
    _wallpaperType = _prefs.getString(_wallpaperTypeKey) ?? 'image';
    _wallpaperPath =
        _prefs.getString(_wallpaperPathKey) ?? 'assets/pattern.jpg';
    _wallpaperOpacity = _prefs.getDouble(_wallpaperOpacityKey) ?? 0.2;
    _backgroundColorValue = _prefs.getInt(_backgroundColorKey) ?? 0xFFFFFFFF;
    _enableNotifications = _prefs.getBool(_notificationsKey) ?? true;
    _isAssetWallpaper =
        _prefs.getBool(_isAssetWallpaperKey) ??
        (_wallpaperPath == 'assets/pattern.jpg');
    _isDarkMode = _prefs.getBool(_darkModeKey) ?? false;
    notifyListeners();
  }

  Future<void> setWallpaperType(String type) async {
    _wallpaperType = type;
    await _prefs.setString(_wallpaperTypeKey, type);
    notifyListeners();
  }

  Future<void> setBackgroundColor(Color color) async {
    _backgroundColorValue = color.value;
    await _prefs.setInt(_backgroundColorKey, color.value);
    await setWallpaperType('color');
    notifyListeners();
  }

  Future<void> setWallpaperImage(String path, {bool isAsset = false}) async {
    _wallpaperPath = path;
    _isAssetWallpaper = isAsset;
    await _prefs.setString(_wallpaperPathKey, path);
    await _prefs.setBool(_isAssetWallpaperKey, isAsset);
    await setWallpaperType('image');
    notifyListeners();
  }

  Future<void> setWallpaperOpacity(double opacity) async {
    _wallpaperOpacity = opacity;
    await _prefs.setDouble(_wallpaperOpacityKey, opacity);
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _enableNotifications = value;
    await _prefs.setBool(_notificationsKey, value);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    await _prefs.setBool(_darkModeKey, value);
    notifyListeners();
  }
}
