import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'backend_service.dart';
import 'package:ruby/core/services/sync_service.dart';
import 'package:ruby/core/services/storage_service.dart';
import 'package:ruby/core/services/chat_history_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;

  final _reAuthSubject = StreamController<bool>.broadcast();
  bool _reAuthRequired = false;
  bool get reAuthRequired => _reAuthRequired;

  Stream<bool> get reAuthStream => _reAuthSubject.stream;

  void setReAuthRequired(bool required) {
    if (_reAuthRequired != required) {
      _reAuthRequired = required;
      _reAuthSubject.add(required);
    }
  }

  AuthService._internal();

  void dispose() {
    _reAuthSubject.close();
  }

  PocketBase get _pb => BackendService.instance.pb;

  Stream<RecordModel?> get authStateChange =>
      _pb.authStore.onChange.map((event) => event.model);

  RecordModel? get currentUser {
    final model = _pb.authStore.model;
    if (model is RecordModel) return model;
    return null;
  }

  String? get currentUserId {
    final model = _pb.authStore.model;
    if (model is RecordModel) return model.id;
    if (model is Map<String, dynamic>) return model['id'] as String?;
    return null;
  }

  bool get isAuthenticated => _pb.authStore.isValid;

  Future<void> signInWithGoogle() async {
    try {
      debugPrint('Initializing Google Sign-In via PocketBase realtime flow...');

      final authData = await _pb.collection('users').authWithOAuth2('google', (
        url,
      ) async {
        debugPrint('Opening Google Auth URL: $url');
        await launchUrl(url, mode: LaunchMode.externalApplication);
      });

      debugPrint('Auth Successful! User ID: ${authData.record.id}');
      _reAuthRequired = false;

      // Trigger sync immediately on login
      SyncService.instance.sync();
    } catch (e) {
      debugPrint('Auth error: $e');
      rethrow;
    }
  }

  void signOut() {
    _pb.authStore.clear();
    setReAuthRequired(false);
    // Clear local data on sign out for account safety
    StorageService.clearTasks();
    ChatHistoryService.clearChatHistory();
  }

  Future<bool> validateSession() async {
    if (!isAuthenticated) return false;
    try {
      // Just try to fetch auth methods as a lightweight check
      await _pb.collection('users').listAuthMethods();
      return true;
    } catch (e) {
      debugPrint('SyncService: Session validation failed: $e');
      if (e is ClientException) {
        if (e.statusCode == 401 || e.statusCode == 403) {
          setReAuthRequired(true);
          return false;
        }
        if (e.statusCode == 404) {
          debugPrint(
            'CRITICAL: PocketBase auth endpoint returned 404. Check server URL or SSL certificate.',
          );
        }
      }
      return false;
    }
  }

  String get token => _pb.authStore.token;
}
