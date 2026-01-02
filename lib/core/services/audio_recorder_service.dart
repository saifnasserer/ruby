import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<void> startRecording(String fileName) async {
    if (await hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      final String path = '${directory.path}/$fileName.m4a';

      await _audioRecorder.start(const RecordConfig(), path: path);
      _isRecording = true;
    }
  }

  Future<String?> stopRecording() async {
    final path = await _audioRecorder.stop();
    _isRecording = false;
    return path;
  }

  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _audioRecorder.stop();
      // Optionally delete the file if it was created
    }
    _isRecording = false;
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
