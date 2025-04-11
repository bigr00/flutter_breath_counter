import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _breathCountPlayer = AudioPlayer();
  final AudioPlayer _holdTimerPlayer = AudioPlayer();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load the audio files from assets
      await _breathCountPlayer.setAsset('assets/sounds/glass-ting.mp3');
      await _holdTimerPlayer.setAsset('assets/sounds/glass-ting.mp3');
      _isInitialized = true;
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  Future<void> playBreathCountReached() async {
    if (!_isInitialized) await initialize();

    try {
      await _breathCountPlayer.seek(Duration.zero);
      await _breathCountPlayer.play();
    } catch (e) {
      print('Error playing breath count sound: $e');
    }
  }

  Future<void> playHoldTimerReached() async {
    if (!_isInitialized) await initialize();

    try {
      await _holdTimerPlayer.seek(Duration.zero);
      await _holdTimerPlayer.play();
    } catch (e) {
      print('Error playing hold timer sound: $e');
    }
  }

  void dispose() {
    _breathCountPlayer.dispose();
    _holdTimerPlayer.dispose();
  }
}