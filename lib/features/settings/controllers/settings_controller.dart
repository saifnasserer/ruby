import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class SettingsController extends ChangeNotifier {
  static const String _wallpaperPathKey = 'wallpaper_path';
  static const String _wallpaperTypeKey = 'wallpaper_type'; // 'color', 'image'
  static const String _wallpaperOpacityKey = 'wallpaper_opacity';
  static const String _backgroundColorKey = 'background_color';
  static const String _notificationsKey = 'enable_notifications';
  static const String _isAssetWallpaperKey = 'is_asset_wallpaper';
  static const String _darkModeKey = 'dark_mode';
  static const String _recentWallpapersKey = 'recent_wallpapers';
  static const String _guestModeKey = 'guest_mode';
  static const String _isFirstLaunchKey = 'is_first_launch';

  final SharedPreferences _prefs;

  String? _wallpaperPath;
  String _wallpaperType = 'image'; // Default to image
  double _wallpaperOpacity = 0.2; // Default to 20%
  int _backgroundColorValue = 0xFFFFFFFF; // Default white background
  bool _enableNotifications = true;
  bool _isAssetWallpaper = true;
  bool _isDarkMode = false;
  bool _isGuestMode = false;
  bool _isFirstLaunch = true;
  List<String> _recentWallpapers = [];

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
  bool get isGuestMode => _isGuestMode;
  bool get isFirstLaunch => _isFirstLaunch;
  List<String> get recentWallpapers => _recentWallpapers;

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
    _isGuestMode = _prefs.getBool(_guestModeKey) ?? false;
    _recentWallpapers = _prefs.getStringList(_recentWallpapersKey) ?? [];
    _isFirstLaunch = _prefs.getBool(_isFirstLaunchKey) ?? true;
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

  Future<void> setWallpaperImage(
    String imagePath, {
    bool isAsset = false,
  }) async {
    String finalPath = imagePath;

    // If it's a file from picker (cached), persist it to local storage
    if (!isAsset) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = path.basename(imagePath);
        final savedImage = await File(
          imagePath,
        ).copy('${directory.path}/$fileName');
        finalPath = savedImage.path;
      } catch (e) {
        print('Error saving image: $e');
        // Fallback to original path if copy fails
      }
    }

    _wallpaperPath = finalPath;
    _isAssetWallpaper = isAsset;

    // Add to recent wallpapers if it's a file path (not asset) and unique
    if (!isAsset && !_recentWallpapers.contains(finalPath)) {
      _recentWallpapers.add(finalPath); // Add to end
      if (_recentWallpapers.length > 5) {
        _recentWallpapers.removeAt(0); // Remove oldest (first)
      }
      await _prefs.setStringList(_recentWallpapersKey, _recentWallpapers);
    }

    await _prefs.setString(_wallpaperPathKey, finalPath);
    await _prefs.setBool(_isAssetWallpaperKey, isAsset);
    await setWallpaperType('image');
    notifyListeners();
  }

  Future<void> removeWallpaper(String path) async {
    _recentWallpapers.remove(path);
    await _prefs.setStringList(_recentWallpapersKey, _recentWallpapers);
    // If we deleted the current wallpaper, reset to default
    if (_wallpaperPath == path) {
      await setWallpaperImage('assets/pattern.jpg', isAsset: true);
    }
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

  Future<void> setGuestMode(bool value) async {
    _isGuestMode = value;
    await _prefs.setBool(_guestModeKey, value);
    notifyListeners();
  }

  Future<void> setFirstLaunch(bool value) async {
    _isFirstLaunch = value;
    await _prefs.setBool(_isFirstLaunchKey, value);
    notifyListeners();
  }
}
