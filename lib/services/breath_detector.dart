import 'dart:async';
import 'dart:ui';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

enum BreathState {
  idle,
  inhaling,
  exhaling,
  holding,
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
  final Function(bool, int) onBreathHoldChange;

  // Detection parameters
  double _breathThreshold = 0.15;
  double get breathThreshold => _breathThreshold;

  // Amplitude levels
  double _ambientNoiseLevel = 0.0;
  double _maxAmplitude = 1.0;

  // New frequency characteristics for inhale/exhale differentiation
  List<double> _inhaleFrequencyProfile = [];
  List<double> _exhaleFrequencyProfile = [];
  List<double> _currentFrequencyProfile = [];
  bool _profilesCalibrated = false;

  // Breath state
  bool _isInhaling = false;
  bool _isExhaling = false;
  bool get isInhaling => _isInhaling;
  bool get isExhaling => _isExhaling;

  // Breath hold state
  bool _isHoldingBreath = false;
  bool get isHoldingBreath => _isHoldingBreath;
  DateTime? _breathHoldStartTime;
  int _breathHoldDuration = 0;
  int _lastBreathHoldDuration = 0;
  Timer? _breathHoldTimer;

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
  final Duration _minInhaleDuration = const Duration(milliseconds: 200);
  final Duration _minExhaleDuration = const Duration(milliseconds: 150);
  final Duration _minBreathCycleDuration = const Duration(milliseconds: 500);
  final Duration _breathCountDebounce = const Duration(milliseconds: 1500);

  // Calibration data
  List<double> _recentAmplitudes = [];
  int _calibrationSamples = 30;

  // Spectral characteristics buffer
  List<double> _spectralBuffer = [];
  int _spectralBufferSize = 10;

  BreathDetector({
    required this.onCalibrationStart,
    required this.onCalibrationComplete,
    required this.onBreathDetected,
    required this.onAmplitudeChange,
    required this.onStateChange,
    required this.onBreathHoldChange,
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
    _profilesCalibrated = false;
    _inhaleFrequencyProfile = [];
    _exhaleFrequencyProfile = [];

    // Stop breath hold tracking if active
    if (_isHoldingBreath) {
      stopBreathHold();
    }

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
              } else if (_isDetectingBreaths && !_isHoldingBreath) {
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

  // Manual breath hold control methods
  void toggleBreathHold() {
    if (_isHoldingBreath) {
      stopBreathHold();
    } else {
      startBreathHold();
    }
  }

  void startBreathHold() {
    if (!_isHoldingBreath && _isDetectingBreaths) {
      _isHoldingBreath = true;
      _breathHoldStartTime = DateTime.now();
      _breathHoldDuration = 0;

      // Update UI
      onBreathHoldChange(_isHoldingBreath, _breathHoldDuration);
      onStateChange(BreathState.holding);

      // Start timer to update the breath hold duration
      _breathHoldTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_breathHoldStartTime != null) {
          _breathHoldDuration = DateTime.now().difference(_breathHoldStartTime!).inSeconds;
          onBreathHoldChange(_isHoldingBreath, _breathHoldDuration);
        }
      });

      print('Breath hold started manually');
    }
  }

  void stopBreathHold() {
    if (_isHoldingBreath) {
      _isHoldingBreath = false;
      _lastBreathHoldDuration = _breathHoldDuration;

      // Update UI with final duration before stopping
      onBreathHoldChange(false, _lastBreathHoldDuration);

      // Stop timer
      _stopBreathHoldTimer();

      // Return to normal breath detection state
      onStateChange(BreathState.idle);

      print('Breath hold stopped, duration: $_lastBreathHoldDuration seconds');
    }
  }

  void _stopBreathHoldTimer() {
    _breathHoldTimer?.cancel();
    _breathHoldTimer = null;
    _breathHoldStartTime = null;
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

    // Update spectral buffer for frequency characteristics
    _updateSpectralBuffer(rawAmplitude);

    return normalizedAmplitude;
  }

  void _updateSpectralBuffer(double rawAmplitude) {
    // Add to spectral buffer
    _spectralBuffer.add(rawAmplitude);

    // Keep buffer at fixed size
    if (_spectralBuffer.length > _spectralBufferSize) {
      _spectralBuffer.removeAt(0);
    }

    // If we have a full buffer, update current frequency profile
    if (_spectralBuffer.length == _spectralBufferSize) {
      _currentFrequencyProfile = List.from(_spectralBuffer);
    }
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

  // New method to calibrate breath profiles
  void calibrateBreathProfiles() {
    if (!_profilesCalibrated && _currentFrequencyProfile.isNotEmpty) {
      // If we're in inhale phase, store the profile
      if (_isInhaling && _inhaleFrequencyProfile.isEmpty) {
        _inhaleFrequencyProfile = List.from(_currentFrequencyProfile);
        print('Inhale frequency profile captured');
      }

      // If we're in exhale phase, store the profile
      if (_isExhaling && _exhaleFrequencyProfile.isEmpty) {
        _exhaleFrequencyProfile = List.from(_currentFrequencyProfile);
        print('Exhale frequency profile captured');
      }

      // If we have both profiles, mark as calibrated
      if (_inhaleFrequencyProfile.isNotEmpty && _exhaleFrequencyProfile.isNotEmpty) {
        _profilesCalibrated = true;
        print('Both breath profiles calibrated');
      }
    }
  }

  // Calculate similarity between current profile and stored profiles
  double _calculateProfileSimilarity(List<double> profile1, List<double> profile2) {
    if (profile1.isEmpty || profile2.isEmpty || profile1.length != profile2.length) {
      return 0.0;
    }

    double sumSquaredDiff = 0.0;
    for (int i = 0; i < profile1.length; i++) {
      sumSquaredDiff += (profile1[i] - profile2[i]) * (profile1[i] - profile2[i]);
    }

    // Return similarity score (0-1, where 1 is perfect match)
    return 1.0 / (1.0 + sumSquaredDiff);
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

    // Stop breath hold tracking if active
    if (_isHoldingBreath) {
      stopBreathHold();
    }

    // Make sure to reset the state and notify listeners
    _resetState();
    onStateChange(BreathState.idle);

    print('Stopped breath detection');
  }

  bool _canCountBreath(DateTime now) {
    // Only count a breath if all these conditions are met:
    // 1. We've detected both inhale and exhale phases
    // 2. Inhale lasted long enough
    // 3. Exhale lasted long enough
    // 4. Total breath cycle lasted long enough
    // 5. It's been long enough since we last counted a breath
    // 6. We're not in the middle of detecting another breath phase

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

    // Stronger debounce condition - require a significant time between breath counts
    bool debouncePassed = _lastBreathCountedTime == null ||
        now.difference(_lastBreathCountedTime!) >= _breathCountDebounce;

    // Ensure we've completed a full inhale+exhale cycle before counting
    bool fullCycleCompleted = _isExhaling && !_isInhaling;

    bool validBreathCycle = longEnoughInhale && longEnoughExhale && longEnoughCycle &&
        debouncePassed && fullCycleCompleted;

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

  // Track the last state change time to prevent rapid state toggling
  DateTime? _lastStateChangeTime;

  void _processAmplitude(double decibels) {
    if (!_isDetectingBreaths || _isHoldingBreath) return;

    // Get normalized amplitude
    double normalizedAmplitude = _normalizeAmplitude(decibels);

    // Get current time for debouncing
    final now = DateTime.now();

    // Prevent too rapid state changes (add minimum time between state transitions)
    bool canChangeState = _lastStateChangeTime == null ||
        now.difference(_lastStateChangeTime!).inMilliseconds > 300;

    if (!canChangeState) {
      return;
    }

    // Calibrate profiles if needed
    calibrateBreathProfiles();

    // Calculate similarity scores if profiles are calibrated
    double inhaleScore = 0.0;
    double exhaleScore = 0.0;

    if (_profilesCalibrated && _currentFrequencyProfile.isNotEmpty) {
      inhaleScore = _calculateProfileSimilarity(_currentFrequencyProfile, _inhaleFrequencyProfile);
      exhaleScore = _calculateProfileSimilarity(_currentFrequencyProfile, _exhaleFrequencyProfile);
    }

    // Using amplitude and frequency characteristics for breath detection
    if (normalizedAmplitude > _breathThreshold) {
      // Check if we're within the debounce period for peak detection
      bool canDetectNewPeak = _lastPeakTime == null ||
          now.difference(_lastPeakTime!).inMilliseconds > _peakDebounceDuration.inMilliseconds;

      // Determine if this is more likely an inhale or exhale based on profiles
      bool likelyInhale = inhaleScore > exhaleScore || !_profilesCalibrated;

      // Loud sound detected - analyze if it's an inhale or exhale
      if (!_isInhaling && !_isExhaling && canDetectNewPeak && likelyInhale) {
        // Start of inhale
        _isInhaling = true;
        _inhaleStartTime = now;
        _lastPeakTime = now;
        _lastStateChangeTime = now;
        onStateChange(BreathState.inhaling);
        print('Inhale started: $normalizedAmplitude > $_breathThreshold (inhale score: $inhaleScore)');
      } else if (_isExhaling && canDetectNewPeak && likelyInhale) {
        // This could be the start of a new inhale (beginning a new breath cycle)

        // Check if we should count the previous breath cycle
        if (_canCountBreath(now)) {
          onBreathDetected();
          _lastBreathCountedTime = now;
          print('Complete breath cycle counted');

          // Clear previous cycle data
          _inhaleStartTime = null;
          _exhaleStartTime = null;
        }

        // Start a new breath cycle
        _isInhaling = true;
        _isExhaling = false;
        _inhaleStartTime = now;
        _lastPeakTime = now;
        onStateChange(BreathState.inhaling);
        print('New inhale after exhale: $normalizedAmplitude (inhale score: $inhaleScore)');
      } else if (_isInhaling && !_isExhaling && canDetectNewPeak && !likelyInhale) {
        // Transition from inhale to exhale based on frequency characteristics
        _isExhaling = true;
        _isInhaling = false;
        _exhaleStartTime = now;
        _lastPeakTime = now;
        onStateChange(BreathState.exhaling);
        print('Exhale started (from inhale): $normalizedAmplitude (exhale score: $exhaleScore)');
      }
    } else if (normalizedAmplitude < _breathThreshold * 0.6) {
      // Quiet phase detected - potential exhale transition

      // Determine if this is more likely an exhale based on profiles
      bool likelyExhale = exhaleScore > inhaleScore || !_profilesCalibrated;

      if (_isInhaling && !_isExhaling && likelyExhale) {
        // Transition from inhale to exhale
        _isExhaling = true;
        _isInhaling = false;
        _exhaleStartTime = now;
        _lastPeakTime = now;
        _lastStateChangeTime = now;
        onStateChange(BreathState.exhaling);
        print('Exhale started: $normalizedAmplitude < ${_breathThreshold * 0.6} (exhale score: $exhaleScore)');
      } else if (_isExhaling && !_isInhaling && normalizedAmplitude < _breathThreshold * 0.3) {
        // End of exhale, complete breath cycle
        if (_canCountBreath(now)) {
          onBreathDetected();
          _lastBreathCountedTime = now;
          print('Complete breath cycle counted at end of exhale');

          // Reset breath state
          _isInhaling = false;
          _isExhaling = false;
          _inhaleStartTime = null;
          _exhaleStartTime = null;
          onStateChange(BreathState.idle);
        }
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
        _lastStateChangeTime = now;
        onStateChange(BreathState.idle);
        print('Reset breath state due to timeout');
      }
    }
  }

  void _resetState() {
    _isInhaling = false;
    _isExhaling = false;
    _lastPeakTime = null;
    _lastBreathTime = null;
    _inhaleStartTime = null;
    _exhaleStartTime = null;
    _lastBreathCountedTime = null;
    onStateChange(BreathState.idle);
  }

  void resetState() {
    _resetState();

    // We no longer reset breath hold state here to allow manual control
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
    _stopBreathHoldTimer();
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    if (_isRecording) {
      _recorder.stopRecorder();
      _isRecording = false;
    }
    _recorder.closeRecorder();
  }
}