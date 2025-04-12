import 'dart:async';
import 'package:flutter/foundation.dart' show VoidCallback, kIsWeb;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

enum FireBreathState {
  idle,
  exhaling,
}

class FireBreathDetector {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamSubscription? _amplitudeSubscription;

  // Callback functions
  final VoidCallback onCalibrationStart;
  final VoidCallback onCalibrationComplete;
  final VoidCallback onBreathDetected;
  final Function(double) onAmplitudeChange;
  final Function(FireBreathState) onStateChange;

  // Detection parameters
  double _breathThreshold = 0.18;
  double get breathThreshold => _breathThreshold;

  // Amplitude levels
  double _ambientNoiseLevel = 0.0;
  double _maxAmplitude = 1.0;

  // Fire breath specific parameters
  bool _isExhaling = false;
  DateTime? _lastBreathTime;
  final Duration _breathDebounce = const Duration(milliseconds: 800); // Longer debounce to avoid multiple detections

  // Rising edge detection
  double _previousAmplitude = 0.0;
  bool _risingEdgeDetected = false;

  // Amplitude peak tracking
  double _currentPeak = 0.0;
  Timer? _peakResetTimer;
  final Duration _peakResetDuration = const Duration(milliseconds: 300);

  // Control flags
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isCalibrating = false;
  bool _isDetectingBreaths = false;
  bool _calibrationCompleted = false;

  // Calibration data
  List<double> _recentAmplitudes = [];
  int _calibrationSamples = 30;

  FireBreathDetector({
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
        // Get web-compatible codec
        Codec codec = kIsWeb ? Codec.opusWebM : Codec.aacADTS;
        String fileExtension = kIsWeb ? 'webm' : 'aac';

        await _recorder.startRecorder(
          toFile: 'calibration_recording.$fileExtension',
          codec: codec,
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
                _processAmplitude(normalizedAmplitude);
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
      _maxAmplitude = _ambientNoiseLevel + 20;

      // Set threshold for fire breath detection
      _breathThreshold = 0.18;

      print('Calibration complete:');
      print('Ambient noise level: $_ambientNoiseLevel');
      print('Initial max amplitude: $_maxAmplitude');
      print('Fire breath threshold: $_breathThreshold');

      // Mark calibration as complete and stop calibrating
      _calibrationCompleted = true;
      _isCalibrating = false;

      // Notify that calibration is complete
      onCalibrationComplete();
    }
  }

  void startBreathDetection() {
    if (!_isRecording || !_calibrationCompleted) {
      print('Cannot start fire breath detection: recording=$_isRecording, calibrated=$_calibrationCompleted');
      return;
    }

    _isDetectingBreaths = true;
    resetState();
    print('Started fire breath detection');
  }

  void stopBreathDetection() {
    _isDetectingBreaths = false;
    _cancelPeakResetTimer();
    resetState();
    onStateChange(FireBreathState.idle);
    print('Stopped fire breath detection');
  }

  bool _canCountBreath(DateTime now) {
    // Only count a new breath if:
    // 1. We're not currently exhaling
    // 2. Enough time has passed since the last breath
    return !_isExhaling &&
        (_lastBreathTime == null || now.difference(_lastBreathTime!) >= _breathDebounce);
  }

  void _processAmplitude(double normalizedAmplitude) {
    if (!_isDetectingBreaths) return;

    // Get current time
    final now = DateTime.now();

    // Check if this is a rising edge (amplitude increasing)
    bool isRising = normalizedAmplitude > _previousAmplitude;

    // Store current amplitude for next comparison
    _previousAmplitude = normalizedAmplitude;

    // Track peak amplitude during this window
    if (normalizedAmplitude > _currentPeak) {
      _currentPeak = normalizedAmplitude;

      // Restart the peak reset timer
      _cancelPeakResetTimer();
      _peakResetTimer = Timer(_peakResetDuration, () {
        // Reset peak after the window
        _currentPeak = 0.0;
      });
    }

    // Detect rising edge transition above threshold
    if (isRising && normalizedAmplitude > _breathThreshold && !_risingEdgeDetected) {
      _risingEdgeDetected = true;

      // If we can count a new breath
      if (_canCountBreath(now)) {
        // Mark as exhaling
        _isExhaling = true;
        _lastBreathTime = now;

        // Show visual feedback
        onStateChange(FireBreathState.exhaling);

        // Count this breath
        onBreathDetected();
        print('Fire breath detected: $normalizedAmplitude');

        // Schedule end of exhalation after a short period
        Future.delayed(const Duration(milliseconds: 250), () {
          if (_isDetectingBreaths) {
            _isExhaling = false;
            onStateChange(FireBreathState.idle);
          }
        });
      }
    }

    // Reset rising edge detector when amplitude falls below threshold
    if (normalizedAmplitude < _breathThreshold * 0.7) {
      _risingEdgeDetected = false;
    }
  }

  void _cancelPeakResetTimer() {
    _peakResetTimer?.cancel();
    _peakResetTimer = null;
  }

  void resetState() {
    _isExhaling = false;
    _lastBreathTime = null;
    _risingEdgeDetected = false;
    _currentPeak = 0.0;
    _previousAmplitude = 0.0;
    _cancelPeakResetTimer();
    onStateChange(FireBreathState.idle);
  }

  void setBreathThreshold(double threshold) {
    _breathThreshold = threshold;
    print('Fire breath threshold updated to: $_breathThreshold');
  }

  void resetMaxAmplitude() {
    _maxAmplitude = _ambientNoiseLevel + 20;
    print('Reset max amplitude to: $_maxAmplitude');
  }

  void dispose() {
    stopBreathDetection();
    _cancelPeakResetTimer();
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    if (_isRecording) {
      _recorder.stopRecorder();
      _isRecording = false;
    }
    _recorder.closeRecorder();
  }
}