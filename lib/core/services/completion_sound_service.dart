import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

/// Service for playing completion sound effects
/// Uses ANDROID_MODE_LOW_LATENCY to avoid interrupting device audio
class CompletionSoundService {
  static final CompletionSoundService _instance =
      CompletionSoundService._internal();
  factory CompletionSoundService() => _instance;
  CompletionSoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  // List of all available completion sounds
  final List<String> _taskCompletionSounds = [
    'assets/audio/done_honkai_blade.mp3',
    'assets/audio/done_riku_kh3d.mp3',
    'assets/audio/git_er_done.mp3',
    'assets/audio/have_done_nothing.mp3',
    'assets/audio/he_done_it.mp3',
    'assets/audio/how_its_done_done_done.mp3',
    'assets/audio/jobs_done.mp3',
    'assets/audio/markiplier_done_good.mp3',
    'assets/audio/pokemon_snap_well.mp3',
    'assets/audio/urrrr_done.mp3',
    'assets/audio/well_done_lad.mp3',
    'assets/audio/ya_done.mp3',
  ];

  final Random _random = Random();

  Future<void> _initializePlayer() async {
    // Set audio mode to low latency to avoid interrupting other audio
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    // Set volume to a reasonable level
    await _audioPlayer.setVolume(0.7);
  }

  /// Play sound when a subtask is completed
  Future<void> playSubtaskCompletionSound() async {
    try {
      await _initializePlayer();
      await _audioPlayer.play(AssetSource('audio/done_2001.mp3'));
    } catch (e) {
      print('Error playing subtask completion sound: $e');
    }
  }

  /// Play a random sound when a full task is completed
  Future<void> playTaskCompletionSound() async {
    try {
      await _initializePlayer();
      final randomSound =
          _taskCompletionSounds[_random.nextInt(_taskCompletionSounds.length)];
      // Extract just the filename from the path
      final soundFile = randomSound.split('/').last;
      await _audioPlayer.play(AssetSource('audio/$soundFile'));
    } catch (e) {
      print('Error playing task completion sound: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
