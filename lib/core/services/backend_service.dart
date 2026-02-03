import 'dart:convert';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersistedAuthStore extends AuthStore {
  final SharedPreferences _prefs;
  static const String _authKey = 'pb_auth';

  PersistedAuthStore(this._prefs) {
    final saved = _prefs.getString(_authKey);
    if (saved != null) {
      try {
        final data = jsonDecode(saved);
        final token = data['token'] as String;
        final modelData = data['model'];

        dynamic model;
        if (modelData != null && modelData is Map<String, dynamic>) {
          model = RecordModel.fromJson(modelData);
        } else {
          model = modelData;
        }

        save(token, model);
      } catch (e) {
        print('Error loading persisted auth: $e');
      }
    }
  }

  @override
  void save(String token, dynamic model) {
    super.save(token, model);
    _prefs.setString(
      _authKey,
      jsonEncode({
        'token': token,
        'model': model is RecordModel ? model.toJson() : model,
      }),
    );
  }

  @override
  void clear() {
    super.clear();
    _prefs.remove(_authKey);
  }
}

class BackendService {
  // TODO: Replace with your actual VPS domain, avoiding port 8090 if proxied
  static const String _baseUrl = 'https://backend.kingsaif.cloud';

  static final BackendService _instance = BackendService._internal();
  static BackendService get instance => _instance;

  late PocketBase pb;

  BackendService._internal() {
    // Default in-memory store, should be initialized with init(prefs) for persistence
    pb = PocketBase(_baseUrl);
  }

  Future<void> init(SharedPreferences prefs) async {
    pb = PocketBase(_baseUrl, authStore: PersistedAuthStore(prefs));
  }

  /// Check if server is reachable (health check)
  Future<bool> isConnected() async {
    try {
      final health = await pb.health.check();
      return health.code == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get the task collection
  RecordService get tasks => pb.collection('tasks');

  /// Get the users collection
  RecordService get users => pb.collection('users');

  /// Get file url
  Uri getFileUrl(RecordModel record, String filename) {
    return pb.files.getUrl(record, filename);
  }
}
