import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Breath Counter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const BreathCounterScreen(),
    );
  }
}

class BreathCounterScreen extends StatefulWidget {
  const BreathCounterScreen({Key? key}) : super(key: key);

  @override
  _BreathCounterScreenState createState() => _BreathCounterScreenState();
}

class _BreathCounterScreenState extends State<BreathCounterScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  int _breathCount = 0;
  StreamSubscription? _amplitudeSubscription;

  // Adaptive threshold for breath detection
  double _breathThreshold = 0.15; // Lower initial threshold for better sensitivity
  double _ambientNoiseLevel = 0.0; // Store the ambient noise level
  double _maxAmplitude = 1.0; // Will store maximum observed amplitude

  // Variables to track breath state
  bool _isInhaling = false;
  bool _isExhaling = false;
  DateTime? _lastPeakTime;
  DateTime? _lastBreathTime;

  // Debounce times for different stages of breath detection
  final Duration _peakDebounceDuration = const Duration(milliseconds: 300); // Shorter for faster breaths
  final Duration _cycleDebounceDuration = const Duration(milliseconds: 500); // Min time between breaths

  // For ambient noise calibration
  List<double> _recentAmplitudes = [];
  int _calibrationSamples = 30; // Increased samples for better calibration
  bool _isCalibrating = false;

  @override
  void initState() {
    super.initState();
    _initRecorder().then((_) {
      // Start calibration immediately when app loads
      _startCalibration();
    });
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(const Duration(milliseconds: 50)); // Faster sampling
  }

  // Separate function for calibration
  void _startCalibration() async {
    try {
      // Reset calibration data
      _recentAmplitudes = [];
      _isCalibrating = true;

      await _recorder.startRecorder(
        toFile: 'calibration_recording.aac',
        codec: Codec.aacADTS,
      );

      _amplitudeSubscription = _recorder.onProgress!.listen((event) {
        if (event.decibels != null) {
          _calibrateThreshold(event.decibels!);
        }
      });

      // Show calibration message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calibrating to ambient noise...'),
          duration: Duration(seconds: 2),
        ),
      );

    } catch (e) {
      print('Error during calibration: $e');
    }
  }

  void _startRecording() async {
    try {
      // If we're already recording from calibration, just switch modes
      if (_isRecording) {
        _isCalibrating = false;
        return;
      }

      // Otherwise start recording fresh
      await _recorder.startRecorder(
        toFile: 'breath_recording.aac',
        codec: Codec.aacADTS,
      );

      _amplitudeSubscription = _recorder.onProgress!.listen((event) {
        if (event.decibels != null) {
          _processAmplitude(event.decibels!);
        }
      });

      setState(() {
        _isRecording = true;
        _isCalibrating = false;
      });

    } catch (e) {
      print('Error starting recorder: $e');
    }
  }

  void _calibrateThreshold(double decibels) {
    // Normalize the decibels more effectively
    // Raw amplitude (non-normalized) for calibration
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

      // Calculate a threshold that's a percentage above ambient noise
      _breathThreshold = 0.15; // Start with a more sensitive threshold

      print('Calibration complete:');
      print('Ambient noise level: $_ambientNoiseLevel');
      print('Initial max amplitude: $_maxAmplitude');
      print('Initial breath threshold: $_breathThreshold');

      // End calibration but keep recording in standby mode
      _isCalibrating = false;
      _isRecording = true; // Keep recording but don't count breaths until Start is pressed

      // Notify user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calibration complete. Press Start to begin counting breaths.'),
          duration: Duration(seconds: 2),
        ),
      );

      // Update state to reflect calibration is complete
      setState(() {});
    }
  }

  void _stopRecording() async {
    try {
      if (_isRecording) {
        setState(() {
          _isRecording = false;
          _isCalibrating = false;
        });
      }
    } catch (e) {
      print('Error stopping recorder: $e');
    }
  }

  void _resetCounter() {
    setState(() {
      _breathCount = 0;
      _isInhaling = false;
      _isExhaling = false;
      _lastPeakTime = null;
      _lastBreathTime = null;
    });
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
    // This ensures the scale adapts to the user's breath intensity
    double normalizedAmplitude = 0;
    if (_maxAmplitude > _ambientNoiseLevel) {
      normalizedAmplitude = (rawAmplitude - _ambientNoiseLevel) /
          (_maxAmplitude - _ambientNoiseLevel);

      // Clamp between 0 and 1
      normalizedAmplitude = normalizedAmplitude.clamp(0.0, 1.0);
    }

    // Get current time for debouncing
    final now = DateTime.now();

    // Add visual feedback for debugging
    _updateVisualFeedback(normalizedAmplitude);

    // Debug print (uncomment when testing)
    // print('Raw: $rawAmplitude, Norm: $normalizedAmplitude, Threshold: $_breathThreshold');

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
        print('Inhale started: $normalizedAmplitude > $_breathThreshold');
      } else if (_isExhaling && canDetectNewPeak) {
        // This could be the start of a new inhale (beginning a new breath cycle)
        _isInhaling = true;
        _isExhaling = false;
        _lastPeakTime = now;
        print('New inhale after exhale: $normalizedAmplitude');
      }
    } else if (normalizedAmplitude < _breathThreshold * 0.5) { // More sensitive exhale detection
      // Quiet phase detected - potential exhale
      if (_isInhaling && !_isExhaling) {
        // Transition from inhale to exhale
        _isExhaling = true;
        _isInhaling = false;
        _lastPeakTime = now;
        print('Exhale started: $normalizedAmplitude < ${_breathThreshold * 0.5}');

        // For fast breathing, count the breath as soon as we detect the start of exhale
        // This helps with Wim Hof and other fast breathing techniques
        bool canCountNewBreath = _lastBreathTime == null ||
            now.difference(_lastBreathTime!).inMilliseconds > _cycleDebounceDuration.inMilliseconds;

        if (canCountNewBreath) {
          setState(() {
            _breathCount++;
          });
          _lastBreathTime = now;
          _provideFeedback();
          print('Fast breath counted: $_breathCount');
        }
      } else if (_isExhaling) {
        // Continue exhaling - for slow breathing we might count here
        // But we already counted at the start of exhale for fast breathing
      }
    }

    // Reset breath state if we've been in the same state too long
    // This helps recover from missed transitions
    if (_lastPeakTime != null && now.difference(_lastPeakTime!).inMilliseconds > 2000) {
      if (_isInhaling || _isExhaling) {
        _isInhaling = false;
        _isExhaling = false;
        print('Reset breath state due to timeout');
      }
    }
  }

// Visual feedback variables
double _currentAmplitude = 0;
Color _feedbackColor = Colors.grey;

void _updateVisualFeedback(double amplitude) {
  setState(() {
    _currentAmplitude = amplitude;
    if (_isInhaling) {
      _feedbackColor = Colors.blue;
    } else if (_isExhaling) {
      _feedbackColor = Colors.green;
    } else {
      _feedbackColor = Colors.grey;
    }
  });
}

void _provideFeedback() {
  // Temporary visual feedback when breath is counted
  setState(() {
    _feedbackColor = Colors.orange;
  });

  // Reset feedback color after short delay
  Future.delayed(const Duration(milliseconds: 300), () {
    if (mounted) {
      setState(() {
        _feedbackColor = _isInhaling ? Colors.blue : (_isExhaling ? Colors.green : Colors.grey);
      });
    }
  });
}

@override
void dispose() {
  _stopRecording();
  _recorder.closeRecorder();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Breath Counter'),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _showSettingsDialog,
          tooltip: 'Adjust sensitivity',
        ),
      ],
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Breath visualization indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _feedbackColor.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: _feedbackColor,
                width: 3,
              ),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 100 * _currentAmplitude,
                height: 100 * _currentAmplitude,
                decoration: BoxDecoration(
                  color: _feedbackColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Breaths Taken:',
            style: TextStyle(fontSize: 24),
          ),
          Text(
            '$_breathCount',
            style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Status text showing the current breathing state
          Text(
            _isCalibrating
                ? 'Calibrating...'
                : (_isInhaling
                ? 'Inhaling'
                : (_isExhaling
                ? 'Exhaling'
                : 'Ready')),
            style: TextStyle(
              fontSize: 18,
              color: _isCalibrating
                  ? Colors.orange
                  : _feedbackColor,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(_isRecording ? 'Stop' : 'Start'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: _resetCounter,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Threshold: '),
                      Text(
                        _breathThreshold.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current level: '),
                      Text(
                        _currentAmplitude.toStringAsFixed(2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

void _showSettingsDialog() {
  double tempThreshold = _breathThreshold;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Adjust Sensitivity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Move slider to adjust breath detection sensitivity:'),
          const SizedBox(height: 20),
          StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                Slider(
                  value: tempThreshold,
                  min: 0.1,
                  max: 0.7,
                  divisions: 30,
                  label: tempThreshold.toStringAsFixed(2),
                  onChanged: (value) {
                    setState(() {
                      tempThreshold = value;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('More sensitive', style: TextStyle(fontSize: 12)),
                    Text('Less sensitive', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                child: const Text('Reset Max'),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    // Reset the max amplitude to encourage recalibration
                    _maxAmplitude = _ambientNoiseLevel + 20;
                  });
                },
              ),
              ElevatedButton(
                child: const Text('Recalibrate'),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (_isRecording) {
                    _stopRecording();
                  }
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _startRecording();
                  });
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _breathThreshold = tempThreshold;
            });
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    ),
  );
}
}