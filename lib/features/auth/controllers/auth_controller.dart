import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authService.isAuthenticated;
  String? get errorMessage => _errorMessage;

  // Current user email/name if needed
  String? get userEmail => _authService.currentUser?.data['email'];

  AuthController() {
    // Listen to auth changes
    _authService.authStateChange.listen((_) {
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.signInWithGoogle();
      // Authentication change is handled by the listener in constructor
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Signin error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _authService.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
