import 'package:pocketbase/pocketbase.dart';
import 'package:url_launcher/url_launcher.dart';

class BackendService {
  // TODO: Replace with your actual VPS domain, avoiding port 8090 if proxied
  static const String _baseUrl = 'https://backend.kingsaif.cloud';

  static final BackendService _instance = BackendService._internal();
  static BackendService get instance => _instance;

  late final PocketBase pb;

  BackendService._internal() {
    pb = PocketBase(_baseUrl);
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
