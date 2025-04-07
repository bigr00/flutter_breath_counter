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

  // Control flags
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isCalibrating = false;
  bool _isDetectingBreaths = false;

  // Timing
  DateTime? _lastPeakTime;
  DateTime? _lastBreathTime;
  final Duration _peakDebounceDuration = const Duration(milliseconds: 300);
  final Duration _cycleDebounceDuration = const Duration(milliseconds: 500);

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
    if (_isCalibrating) return;

    try {
      // Reset calibration data
      _recentAmplitudes = [];
      _isCalibrating = true;

      // Notify that calibration has started
      onCalibrationStart();

      // Start the recorder
      await _recorder.startRecorder(
        toFile: 'calibration_recording.aac',
        codec: Codec.aacADTS,
      );

      _isRecording = true;

      // Listen for amplitude changes
      _amplitudeSubscription = _recorder.onProgress!.listen((event) {
        if (event.decibels != null) {
          if (_isCalibrating) {
            _calibrateThreshold(event.decibels!);
          } else if (_isDetectingBreaths) {
            _processAmplitude(event.decibels!);
          }
        }
      });

    } catch (e) {
      print('Error during calibration: $e');
      _isCalibrating = false;
    }
  }

  void _calibrateThreshold(double decibels) {
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

      // End calibration but keep recording in standby mode
      _isCalibrating = false;

      // Notify that calibration is complete
      onCalibrationComplete();
    }
  }

  void startBreathDetection() {
    if (!_isRecording) {
      startCalibration();
      return;
    }

    _isDetectingBreaths = true;
    resetState();
  }

  void stopBreathDetection() {
    _isDetectingBreaths = false;
  }

  void _processAmplitude(double decibels) {
    // Get raw amplitude value (non-normalized)
    double rawAmplitude = decibels + 160;

    // Dynamically adjust maximum amplitude if we see higher values
    if (rawAmplitude > _maxAmplitude) {
      _maxAmplitude = rawAmplitude;
      print('New max amplitude: $_maxAmplitude');
    }

    // Calculate normalized amplitude relative to ambient and max observed
    double normalizedAmplitude = 0;
    if (_maxAmplitude > _ambientNoiseLevel) {
      normalizedAmplitude = (rawAmplitude - _ambientNoiseLevel) /
          (_maxAmplitude - _ambientNoiseLevel);

      // Clamp between 0 and 1
      normalizedAmplitude = normalizedAmplitude.clamp(0.0, 1.0);
    }

    // Get current time for debouncing
    final now = DateTime.now();

    // Update the visualization
    onAmplitudeChange(normalizedAmplitude);

    // Using a more sensitive approach with dynamic thresholds for fast breathing
    if (normalizedAmplitude > _breathThreshold) {
      // Check if we're within the debounce period for peak detection
      bool canDetectNewPeak = _lastPeakTime == null ||
          now.difference(_lastPeakTime!).inMilliseconds > _peakDebounceDuration.inMilliseconds;

      // Loud sound detected - likely an inhale
      if (!_isInhaling && !_isExhaling && canDetectNewPeak) {
        // Start of inhale
        _isInhaling = true;
        _lastPeakTime = now;
        onStateChange(BreathState.inhaling);
        print('Inhale started: $normalizedAmplitude > $_breathThreshold');
      } else if (_isExhaling && canDetectNewPeak) {
        // This could be the start of a new inhale (beginning a new breath cycle)
        _isInhaling = true;
        _isExhaling = false;
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
        _lastPeakTime = now;
        onStateChange(BreathState.exhaling);
        print('Exhale started: $normalizedAmplitude < ${_breathThreshold * 0.5}');

        // For fast breathing, count the breath as soon as we detect the start of exhale
        // This helps with Wim Hof and other fast breathing techniques
        bool canCountNewBreath = _lastBreathTime == null ||
            now.difference(_lastBreathTime!).inMilliseconds > _cycleDebounceDuration.inMilliseconds;

        if (canCountNewBreath) {
          onBreathDetected();
          _lastBreathTime = now;
          print('Fast breath counted');
        }
      } else if (_isExhaling) {
        // Continue exhaling - we already counted at the start of exhale for fast breathing
      }
    }

    // Reset breath state if we've been in the same state too long
    // This helps recover from missed transitions
    if (_lastPeakTime != null && now.difference(_lastPeakTime!).inMilliseconds > 2000) {
      if (_isInhaling || _isExhaling) {
        _isInhaling = false;
        _isExhaling = false;
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
    _recorder.closeRecorder();
  }
}