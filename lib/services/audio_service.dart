import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _breathCountPlayer = AudioPlayer();
  final AudioPlayer _holdTimerPlayer = AudioPlayer();
  final AudioPlayer _phaseCompletePlayer = AudioPlayer();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load the audio files from assets
      await _breathCountPlayer.setAsset('assets/sounds/count_finished.mp3');
      await _holdTimerPlayer.setAsset('assets/sounds/hold_finished.mp3');
      await _phaseCompletePlayer.setAsset('assets/sounds/soft-ting.m4a');
      _isInitialized = true;
      print('Audio service initialized successfully');
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  Future<void> playBreathCountReached() async {
    if (!_isInitialized) await initialize();

    try {
      await _breathCountPlayer.stop();
      await _breathCountPlayer.seek(Duration.zero);
      await _breathCountPlayer.play();
      print('Playing breath count sound');
    } catch (e) {
      print('Error playing breath count sound: $e');
      // Try to reinitialize if there was an error
      _isInitialized = false;
      await initialize();
      await _breathCountPlayer.play();
    }
  }

  Future<void> playHoldTimerReached() async {
    if (!_isInitialized) await initialize();

    try {
      await _holdTimerPlayer.stop();
      await _holdTimerPlayer.seek(Duration.zero);
      await _holdTimerPlayer.play();
      print('Playing hold timer sound');
    } catch (e) {
      print('Error playing hold timer sound: $e');
      // Try to reinitialize if there was an error
      _isInitialized = false;
      await initialize();
      await _holdTimerPlayer.play();
    }
  }

  Future<void> playPhaseComplete() async {
    if (!_isInitialized) await initialize();

    try {
      await _phaseCompletePlayer.stop();
      await _phaseCompletePlayer.seek(Duration.zero);
      await _phaseCompletePlayer.play();
      print('Playing phase complete sound');
    } catch (e) {
      print('Error playing phase complete sound: $e');
      // Try to reinitialize if there was an error
      _isInitialized = false;
      await initialize();
      await _phaseCompletePlayer.play();
    }
  }

  void dispose() {
    _breathCountPlayer.dispose();
    _holdTimerPlayer.dispose();
    _phaseCompletePlayer.dispose();
  }
}