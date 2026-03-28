import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
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

  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;

  // We need to keep track of the code verifier and a completer to notify the UI
  String? _lastCodeVerifier;
  Completer<void>? _authCompleter;

  void setReAuthRequired(bool required) {
    if (_reAuthRequired != required) {
      _reAuthRequired = required;
      _reAuthSubject.add(required);
    }
  }

  AuthService._internal() {
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) async {
        debugPrint('Received Deep Link: $uri');

        // Check if this is our auth callback
        if (uri.scheme == 'ruby-app' && uri.host == 'auth') {
          final code = uri.queryParameters['code'];
          if (code != null && _lastCodeVerifier != null) {
            try {
              debugPrint('Exchanging code for token...');
              final authData = await _pb.collection('users').authWithOAuth2Code(
                    'google',
                    code,
                    _lastCodeVerifier!,
                    'https://backend.kingsaif.cloud/api/mobile-auth',
                  );
              debugPrint('Auth Successful via Deep Link! User ID: ${authData.record.id}');
              _reAuthRequired = false;
              _reAuthSubject.add(false);

              // Trigger sync immediately on login
              SyncService.instance.sync();
              
              if (_authCompleter != null && !_authCompleter!.isCompleted) {
                _authCompleter!.complete();
              }
            } catch (e) {
              debugPrint('Auth exchange error: $e');
              if (_authCompleter != null && !_authCompleter!.isCompleted) {
                _authCompleter!.completeError(e);
              }
            } finally {
              _lastCodeVerifier = null;
              _authCompleter = null;
            }
          }
        }
      },
      onError: (err) {
        debugPrint('Deep Link Error: $err');
      },
    );
  }

  void dispose() {
    _reAuthSubject.close();
    _linkSubscription?.cancel();
  }

  PocketBase get _pb => BackendService.instance.pb;

  Stream<RecordModel?> get authStateChange =>
      _pb.authStore.onChange.map((event) => event.record);

  RecordModel? get currentUser {
    final model = _pb.authStore.record;
    if (model is RecordModel) return model;
    return null;
  }

  String? get currentUserId {
    final record = _pb.authStore.record;
    if (record is RecordModel) return record.id;
    return null;
  }

  bool get isAuthenticated => _pb.authStore.isValid;

  Future<void> signInWithGoogle() async {
    try {
      debugPrint('Initializing Google Sign-In via Manual Bouncer flow...');

      // 1. Fetch available auth methods from PocketBase
      final authMethods = await _pb.collection('users').listAuthMethods();

      // 2. Find the Google provider
      final googleProvider = authMethods.oauth2.providers.firstWhere(
        (p) => p.name == 'google',
        orElse: () => throw Exception('Google auth provider not found'),
      );

      // 3. Store the code verifier for the exchange 
      _lastCodeVerifier = googleProvider.codeVerifier;
      _authCompleter = Completer<void>();

      // 4. Construct the auth URL with our custom redirect_uri
      final baseUri = Uri.parse(googleProvider.authURL);
      final authUrl = baseUri.replace(
        queryParameters: {
          ...baseUri.queryParameters,
          'redirect_uri': 'https://backend.kingsaif.cloud/api/mobile-auth',
        },
      );

      debugPrint('Opening Google Auth URL: $authUrl');
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);

      // 5. Wait for the deep link listener to handle the callback
      return _authCompleter?.future;
    } catch (e) {
      debugPrint('Auth error: $e');
      _lastCodeVerifier = null;
      _authCompleter = null;
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
