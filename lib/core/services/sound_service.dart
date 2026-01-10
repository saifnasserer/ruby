import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService instance = SoundService._();

  // Separate players to avoid conflicts
  final AudioPlayer _subtaskPlayer = AudioPlayer();
  final AudioPlayer _taskPlayer = AudioPlayer();
  final Random _random = Random();

  // List of all available task completion sounds (excluding done_2001.mp3 which is for subtasks)
  final List<String> _taskCompletionSounds = [
    'audio/done_honkai_blade.mp3',
    'audio/done_riku_kh3d.mp3',
    'audio/git_er_done.mp3',
    'audio/have_done_nothing.mp3',
    'audio/he_done_it.mp3',
    'audio/how_its_done_done_done.mp3',
    'audio/jobs_done.mp3',
    'audio/markiplier_done_good.mp3',
    'audio/pokemon_snap_well.mp3',
    'audio/urrrr_done.mp3',
    'audio/well_done_lad.mp3',
    'audio/ya_done.mp3',
  ];

  SoundService._() {
    _initPlayers();
  }

  Future<void> _initPlayers() async {
    // Configure players once on initialization
    try {
      await _subtaskPlayer.setReleaseMode(ReleaseMode.stop);
      await _subtaskPlayer.setVolume(1.0);

      await _taskPlayer.setReleaseMode(ReleaseMode.stop);
      await _taskPlayer.setVolume(1.0);
    } catch (e) {
      print('Error initializing SoundService players: $e');
    }
  }

  /// Play sound when a subtask is completed
  Future<void> playSubtaskCompletionSound() async {
    try {
      if (_subtaskPlayer.state == PlayerState.playing) {
        await _subtaskPlayer.stop();
      }
      await _subtaskPlayer.play(AssetSource('audio/done_2001.mp3'));
    } catch (e) {
      print('Error playing subtask sound: $e');
    }
  }

  /// Play a random sound when a full task is completed
  Future<void> playTaskCompletionSound() async {
    try {
      if (_taskPlayer.state == PlayerState.playing) {
        await _taskPlayer.stop();
      }

      final randomSound =
          _taskCompletionSounds[_random.nextInt(_taskCompletionSounds.length)];

      await _taskPlayer.play(AssetSource(randomSound));
    } catch (e) {
      print('Error playing task sound: $e');
    }
  }

  /// Dispose audio players
  void dispose() {
    _subtaskPlayer.dispose();
    _taskPlayer.dispose();
  }
}
