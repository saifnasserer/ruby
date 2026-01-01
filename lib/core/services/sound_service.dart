import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService instance = SoundService._();
  SoundService._();

  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Play task completion sound
  Future<void> playTaskCompletionSound() async {
    try {
      await _audioPlayer.play(AssetSource('done.mp3'));
    } catch (e) {
      // Silent error handling for production
    }
  }

  /// Dispose audio player
  void dispose() {
    _audioPlayer.dispose();
  }
}

