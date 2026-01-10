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

      // Start audio recording
      await _audioRecorder.start(const RecordConfig(), path: path);

      _isRecording = true;
    }
  }

  Future<Map<String, dynamic>> stopRecording() async {
    final path = await _audioRecorder.stop();
    _isRecording = false;

    // Generate deterministic waveform data based on file path
    List<double>? waveformData;
    if (path != null) {
      waveformData = _generateWaveformData(path);
    }

    return {'path': path, 'waveformData': waveformData};
  }

  // Generate deterministic waveform data based on file path hash
  // This creates unique but consistent waveforms for each recording
  List<double> _generateWaveformData(String filePath) {
    const segments = 64; // WhatsApp uses 64 segments
    final hash = filePath.hashCode;
    final random = _SeededRandom(hash);

    final waveform = <double>[];
    for (int i = 0; i < segments; i++) {
      // Generate values between 0.2 and 1.0 for visual variety
      final value = 0.2 + (random.nextDouble() * 0.8);
      waveform.add(value);
    }

    return waveform;
  }

  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _audioRecorder.stop();
    }
    _isRecording = false;
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}

// Simple seeded random number generator for deterministic waveforms
class _SeededRandom {
  int _seed;

  _SeededRandom(this._seed);

  double nextDouble() {
    _seed = ((_seed * 1103515245) + 12345) & 0x7fffffff;
    return (_seed % 10000) / 10000.0;
  }
}
