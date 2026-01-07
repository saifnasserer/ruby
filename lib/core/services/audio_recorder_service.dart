import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final SpeechToText _speechToText = SpeechToText();
  bool _isRecording = false;
  String _lastTranscription = '';
  bool _isSpeechAvailable = false;

  bool get isRecording => _isRecording;
  String get lastTranscription => _lastTranscription;

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.request();
    // Also check for speech recognition permission if needed on some platforms
    return status == PermissionStatus.granted;
  }

  Future<void> startRecording(String fileName) async {
    if (await hasPermission()) {
      _lastTranscription = '';

      // Initialize speech recognition if not already
      if (!_isSpeechAvailable) {
        _isSpeechAvailable = await _speechToText.initialize(
          onStatus: (status) => print('Speech status: $status'),
          onError: (error) => print('Speech error: $error'),
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final String path = '${directory.path}/$fileName.m4a';

      // Start audio recording
      await _audioRecorder.start(const RecordConfig(), path: path);

      // Start speech-to-text if available
      if (_isSpeechAvailable) {
        await _speechToText.listen(
          localeId: 'ar_EG', // Egyptian Arabic for better recognition
          listenMode:
              ListenMode.dictation, // Critical: enables continuous dictation
          onResult: (result) {
            _lastTranscription = result.recognizedWords;
            print('Live transcription: $_lastTranscription');
          },
          cancelOnError: true,
          partialResults: true,
        );
      }

      _isRecording = true;
    }
  }

  Future<Map<String, String?>> stopRecording() async {
    final path = await _audioRecorder.stop();
    if (_isSpeechAvailable) {
      await _speechToText.stop();
    }
    _isRecording = false;

    return {
      'path': path,
      'transcription': _lastTranscription.isNotEmpty
          ? _lastTranscription
          : null,
    };
  }

  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _audioRecorder.stop();
      if (_isSpeechAvailable) {
        await _speechToText.stop();
      }
    }
    _isRecording = false;
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
