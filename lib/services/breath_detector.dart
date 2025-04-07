import 'dart:async';
import 'dart:ui';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

enum BreathState {
  idle,
  inhaling,
  exhaling,
}

class BreathDetector {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamSubscription? _amplitudeSubscription;

  // Callback functions
  final VoidCallback onCalibrationStart;
  final VoidCallback onCalibrationComplete;
  final VoidCallback onBreathDetected;
  final Function(double) onAmplitudeChange;
  final Function(BreathState) onStateChange;

  // Detection parameters
  double _breathThreshold = 0.15;
  double get breathThreshold => _breathThreshold;

  // Amplitude levels
  double _ambientNoiseLevel = 0.0;
  double _maxAmplitude = 1.0;

  // Breath state
  bool _isInhaling = false;
  bool _isExhaling = false;
  bool get isInhaling => _isInhaling;
  bool get isExhaling => _isExhaling;

  // Track complete breath cycles with more robust timing
  DateTime? _inhaleStartTime;
  DateTime? _exhaleStartTime;
  DateTime? _lastBreathCountedTime;

  // Control flags
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isCalibrating = false;
  bool _isDetectingBreaths = false;
  bool _calibrationCompleted = false;

  // Timing - adjusted to be more responsive
  DateTime? _lastPeakTime;
  DateTime? _lastBreathTime;
  final Duration _peakDebounceDuration = const Duration(milliseconds: 200);
  final Duration _minInhaleDuration = const Duration(milliseconds: 200);   // Reduced from 400ms
  final Duration _minExhaleDuration = const Duration(milliseconds: 150);   // Reduced from 400ms
  final Duration _minBreathCycleDuration = const Duration(milliseconds: 500); // Reduced from 1200ms
  final Duration _breathCountDebounce = const Duration(milliseconds: 800);  // Reduced from 1500ms

  // Calibration data
  List<double> _recentAmplitudes = [];
  int _calibrationSamples = 30;

  BreathDetector({
    required this.onCalibrationStart,
    required this.onCalibrationComplete,
    required this.onBreathDetected,
    required this.onAmplitudeChange,
    required this.onStateChange,
  });

  Future<void> initialize() async {
    if (_isInitialized) return;

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(const Duration(milliseconds: 50));
    _isInitialized = true;
  }

  void startCalibration() async {
    if (!_isInitialized) await initialize();
    if (_isCalibrating || _calibrationCompleted) return;

    _isCalibrating = true;
    _calibrationCompleted = false;
    _recentAmplitudes = [];

    // Notify calibration started
    onCalibrationStart();

    if (!_isRecording) {
      try {
        await _recorder.startRecorder(
          toFile: 'calibration_recording.aac',
          codec: Codec.aacADTS,
        );
        _isRecording = true;

        // Set up listener only once
        if (_amplitudeSubscription == null) {
          _amplitudeSubscription = _recorder.onProgress!.listen((event) {
            if (event.decibels != null) {
              double amplitude = event.decibels!;

              // Always update the amplitude visualization
              double normalizedAmplitude = _normalizeAmplitude(amplitude);
              onAmplitudeChange(normalizedAmplitude);

              // Process the amplitude based on current mode
              if (_isCalibrating && !_calibrationCompleted) {
                _calibrateThreshold(amplitude);
              } else if (_isDetectingBreaths) {
                _processAmplitude(amplitude);
              }
            }
          });
        }
      } catch (e) {
        print('Error starting recorder: $e');
        _isCalibrating = false;
      }
    }
  }

  double _normalizeAmplitude(double decibels) {
    // Get raw amplitude value
    double rawAmplitude = decibels + 160;

    // Dynamically adjust maximum amplitude if we see higher values
    if (rawAmplitude > _maxAmplitude) {
      _maxAmplitude = rawAmplitude;
    }

    // Calculate normalized amplitude relative to ambient and max observed
    double normalizedAmplitude = 0;
    if (_maxAmplitude > _ambientNoiseLevel) {
      normalizedAmplitude = (rawAmplitude - _ambientNoiseLevel) /
          (_maxAmplitude - _ambientNoiseLevel);

      // Clamp between 0 and 1
      normalizedAmplitude = normalizedAmplitude.clamp(0.0, 1.0);
    }

    return normalizedAmplitude;
  }

  void _calibrateThreshold(double decibels) {
    if (!_isCalibrating || _calibrationCompleted) return;

    // Raw amplitude for calibration
    double rawAmplitude = decibels + 160;

    // Add to recent amplitudes
    _recentAmplitudes.add(rawAmplitude);

    // Once we have enough samples, calculate the threshold
    if (_recentAmplitudes.length >= _calibrationSamples) {
      // Sort amplitudes to find median for ambient noise
      _recentAmplitudes.sort();

      // Use median as ambient noise level (robust against outliers)
      int medianIndex = (_recentAmplitudes.length / 2).round();
      _ambientNoiseLevel = _recentAmplitudes[medianIndex];

      // Set initial max amplitude higher than ambient to detect breath spikes
      _maxAmplitude = _ambientNoiseLevel + 20; // 20dB above ambient as initial guess

      // Set initial threshold
      _breathThreshold = 0.15;

      print('Calibration complete:');
      print('Ambient noise level: $_ambientNoiseLevel');
      print('Initial max amplitude: $_maxAmplitude');
      print('Initial breath threshold: $_breathThreshold');

      // Mark calibration as complete and stop calibrating
      _calibrationCompleted = true;
      _isCalibrating = false;

      // Notify that calibration is complete
      onCalibrationComplete();
    }
  }

  void startBreathDetection() {
    if (!_isRecording || !_calibrationCompleted) {
      print('Cannot start breath detection: recording=$_isRecording, calibrated=$_calibrationCompleted');
      return;
    }

    _isDetectingBreaths = true;
    resetState();
    print('Started breath detection');
  }

  void stopBreathDetection() {
    _isDetectingBreaths = false;
    print('Stopped breath detection');
  }

  bool _canCountBreath(DateTime now) {
    // Only count a breath if all these conditions are met:
    // 1. We've detected both inhale and exhale phases
    // 2. Inhale lasted long enough
    // 3. Exhale lasted long enough
    // 4. Total breath cycle lasted long enough
    // 5. It's been long enough since we last counted a breath

    if (_inhaleStartTime == null || _exhaleStartTime == null) {
      return false;
    }

    // Calculate durations
    final inhaleDuration = _exhaleStartTime!.difference(_inhaleStartTime!);
    final exhaleDuration = now.difference(_exhaleStartTime!);
    final cycleDuration = now.difference(_inhaleStartTime!);

    bool longEnoughInhale = inhaleDuration >= _minInhaleDuration;
    bool longEnoughExhale = exhaleDuration >= _minExhaleDuration;
    bool longEnoughCycle = cycleDuration >= _minBreathCycleDuration;

    bool debouncePassed = _lastBreathCountedTime == null ||
        now.difference(_lastBreathCountedTime!) >= _breathCountDebounce;

    bool validBreathCycle = longEnoughInhale && longEnoughExhale && longEnoughCycle && debouncePassed;

    if (validBreathCycle) {
      print('Valid breath cycle detected:');
      print('- Inhale duration: ${inhaleDuration.inMilliseconds}ms');
      print('- Exhale duration: ${exhaleDuration.inMilliseconds}ms');
      print('- Total cycle: ${cycleDuration.inMilliseconds}ms');
    } else if (inhaleDuration.inMilliseconds > 0 && exhaleDuration.inMilliseconds > 0) {
      // Log why a cycle wasn't counted for debugging
      if (!longEnoughInhale) print('Inhale too short: ${inhaleDuration.inMilliseconds}ms');
      if (!longEnoughExhale) print('Exhale too short: ${exhaleDuration.inMilliseconds}ms');
      if (!longEnoughCycle) print('Cycle too short: ${cycleDuration.inMilliseconds}ms');
      if (!debouncePassed && _lastBreathCountedTime != null) {
        print('Debounce not passed: ${now.difference(_lastBreathCountedTime!).inMilliseconds}ms since last breath');
      }
    }

    return validBreathCycle;
  }

  void _processAmplitude(double decibels) {
    if (!_isDetectingBreaths) return;

    // Get normalized amplitude
    double normalizedAmplitude = _normalizeAmplitude(decibels);

    // Get current time for debouncing
    final now = DateTime.now();

    // Using a more sensitive approach with dynamic thresholds for fast breathing
    if (normalizedAmplitude > _breathThreshold) {
      // Check if we're within the debounce period for peak detection
      bool canDetectNewPeak = _lastPeakTime == null ||
          now.difference(_lastPeakTime!).inMilliseconds > _peakDebounceDuration.inMilliseconds;

      // Loud sound detected - likely an inhale
      if (!_isInhaling && !_isExhaling && canDetectNewPeak) {
        // Start of inhale
        _isInhaling = true;
        _inhaleStartTime = now;
        _lastPeakTime = now;
        onStateChange(BreathState.inhaling);
        print('Inhale started: $normalizedAmplitude > $_breathThreshold');
      } else if (_isExhaling && canDetectNewPeak) {
        // This could be the start of a new inhale (beginning a new breath cycle)

        // Check if we should count the previous breath cycle
        if (_canCountBreath(now)) {
          onBreathDetected();
          _lastBreathCountedTime = now;
          print('Complete breath cycle counted');
        }

        // Start a new breath cycle
        _isInhaling = true;
        _isExhaling = false;
        _inhaleStartTime = now;
        _lastPeakTime = now;
        onStateChange(BreathState.inhaling);
        print('New inhale after exhale: $normalizedAmplitude');
      }
    } else if (normalizedAmplitude < _breathThreshold * 0.5) { // More sensitive exhale detection
      // Quiet phase detected - potential exhale
      if (_isInhaling && !_isExhaling) {
        // Transition from inhale to exhale
        _isExhaling = true;
        _isInhaling = false;
        _exhaleStartTime = now;
        _lastPeakTime = now;
        onStateChange(BreathState.exhaling);
        print('Exhale started: $normalizedAmplitude < ${_breathThreshold * 0.5}');
      }
    }

    // Reset breath state if we've been in the same state too long
    // This helps recover from missed transitions
    if (_lastPeakTime != null && now.difference(_lastPeakTime!).inMilliseconds > 2000) {
      if (_isInhaling || _isExhaling) {
        // If we were in an exhale state for a long time, check if we should count a breath
        if (_isExhaling && _canCountBreath(now)) {
          onBreathDetected();
          _lastBreathCountedTime = now;
          print('Complete breath cycle counted on timeout');
        }

        // Reset state
        _isInhaling = false;
        _isExhaling = false;
        _inhaleStartTime = null;
        _exhaleStartTime = null;
        onStateChange(BreathState.idle);
        print('Reset breath state due to timeout');
      }
    }
  }

  void resetState() {
    _isInhaling = false;
    _isExhaling = false;
    _lastPeakTime = null;
    _lastBreathTime = null;
    _inhaleStartTime = null;
    _exhaleStartTime = null;
    _lastBreathCountedTime = null;
    onStateChange(BreathState.idle);
  }

  void setBreathThreshold(double threshold) {
    _breathThreshold = threshold;
  }

  void resetMaxAmplitude() {
    _maxAmplitude = _ambientNoiseLevel + 20;
    print('Reset max amplitude to: $_maxAmplitude');
  }

  void dispose() {
    stopBreathDetection();
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    if (_isRecording) {
      _recorder.stopRecorder();
      _isRecording = false;
    }
    _recorder.closeRecorder();
  }
}