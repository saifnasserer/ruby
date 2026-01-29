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

  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;

  // We need to keep track of the code verifier and a completer to notify the UI
  String? _lastCodeVerifier;
  Completer<void>? _authCompleter;
  bool _reAuthRequired = false;
  bool get reAuthRequired => _reAuthRequired;

  void setReAuthRequired(bool required) {
    _reAuthRequired = required;
  }

  AuthService._internal() {
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) async {
        debugPrint('Received Deep Link: $uri');

        final code = uri.queryParameters['code'];
        if (code != null && _lastCodeVerifier != null) {
          try {
            debugPrint('Exchanging code for token...');
            await _pb
                .collection('users')
                .authWithOAuth2Code(
                  'google',
                  code,
                  _lastCodeVerifier!,
                  'https://backend.kingsaif.cloud/api/mobile-auth',
                );
            debugPrint('Auth Successful via Deep Link!');
            _reAuthRequired = false;
            // Trigger sync immediately on login
            SyncService.instance.sync();
            _authCompleter?.complete();
          } catch (e) {
            debugPrint('Auth exchange error: $e');
            _authCompleter?.completeError(e);
          } finally {
            _lastCodeVerifier = null;
            _authCompleter = null;
          }
        }
      },
      onError: (err) {
        debugPrint('Deep Link Error: $err');
      },
    );
  }

  void dispose() {
    _linkSubscription?.cancel();
  }

  PocketBase get _pb => BackendService.instance.pb;

  Stream<RecordModel?> get authStateChange =>
      _pb.authStore.onChange.map((event) => event.model);

  RecordModel? get currentUser => _pb.authStore.model is RecordModel
      ? _pb.authStore.model as RecordModel
      : null;

  bool get isAuthenticated => _pb.authStore.isValid;

  Future<void> signInWithGoogle() async {
    try {
      // 1. Fetch available auth methods from PocketBase
      final authMethods = await _pb.collection('users').listAuthMethods();

      // 2. Find the Google provider
      final googleProvider = authMethods.oauth2.providers.firstWhere(
        (p) => p.name == 'google',
        orElse: () =>
            throw Exception('Google provider not configured in PocketBase'),
      );

      // 3. Store the verifier and create a completer
      _lastCodeVerifier = googleProvider.codeVerifier;
      _authCompleter = Completer<void>();

      // 4. Construct the auth URL with our custom ruby-app://auth redirect_uri
      final baseUri = Uri.parse(googleProvider.authUrl);
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
    // Clear local data on sign out for account safety
    StorageService.clearTasks();
    ChatHistoryService.clearChatHistory();
  }

  String get token => _pb.authStore.token;
}
