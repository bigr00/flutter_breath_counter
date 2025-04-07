import 'package:flutter/material.dart';
import '../services/breath_detector.dart';
import '../widgets/breath_visualization.dart';
import '../widgets/breath_counter_display.dart';
import '../widgets/breath_controls.dart';
import '../widgets/status_display.dart';

class BreathCounterScreen extends StatefulWidget {
  const BreathCounterScreen({Key? key}) : super(key: key);

  @override
  _BreathCounterScreenState createState() => _BreathCounterScreenState();
}

class _BreathCounterScreenState extends State<BreathCounterScreen> {
  late BreathDetector _breathDetector;
  int _breathCount = 0;
  double _currentAmplitude = 0;
  bool _isCalibrating = false;
  bool _isReadyForCounting = false;
  bool _isCounting = false;
  Color _feedbackColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _initializeDetector();
  }

  Future<void> _initializeDetector() async {
    // Create the detector with callbacks
    _breathDetector = BreathDetector(
      onCalibrationStart: () {
        if (mounted) {
          setState(() {
            _isCalibrating = true;
            _isReadyForCounting = false;
            _feedbackColor = Colors.orange;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Calibrating to ambient noise...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      onCalibrationComplete: () {
        if (mounted) {
          setState(() {
            _isCalibrating = false;
            _isReadyForCounting = true;
            _feedbackColor = Colors.grey;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Calibration complete. Press Start to begin counting.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      onBreathDetected: () {
        if (_isCounting && mounted) {
          setState(() {
            _breathCount++;
          });
          _provideFeedback();
        }
      },
      onAmplitudeChange: (amplitude) {
        if (mounted) {
          setState(() {
            _currentAmplitude = amplitude;
          });
        }
      },
      onStateChange: (state) {
        if (!mounted) return;

        setState(() {
          switch (state) {
            case BreathState.inhaling:
              _feedbackColor = Colors.blue;
              break;
            case BreathState.exhaling:
              _feedbackColor = Colors.green;
              break;
            case BreathState.idle:
              _feedbackColor = _isCalibrating ? Colors.orange : Colors.grey;
              break;
          }
        });
      },
    );

    // Initialize and start calibration
    await _breathDetector.initialize();

    // Small delay to ensure initialization is complete
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _breathDetector.startCalibration();
      }
    });
  }

  void _toggleCounting() {
    if (_isCounting) {
      _stopCounting();
    } else {
      _startCounting();
    }
  }

  void _startCounting() {
    if (!_isCounting && _isReadyForCounting) {
      setState(() {
        _isCounting = true;
      });
      _breathDetector.startBreathDetection();
    }
  }

  void _stopCounting() {
    if (_isCounting) {
      setState(() {
        _isCounting = false;
      });
      _breathDetector.stopBreathDetection();
    }
  }

  void _resetCounter() {
    setState(() {
      _breathCount = 0;
    });
    _breathDetector.resetState();
  }

  void _provideFeedback() {
    // Store the original color
    Color originalColor = _feedbackColor;

    // Show feedback color
    if (mounted) {
      setState(() {
        _feedbackColor = Colors.orange;
      });

      // Reset after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _feedbackColor = originalColor;
          });
        }
      });
    }
  }

  void _recalibrate() {
    // Stop counting if active
    if (_isCounting) {
      _stopCounting();
    }

    // Reset flags
    setState(() {
      _isReadyForCounting = false;
      _isCounting = false;
    });

    // Start calibration
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _breathDetector.startCalibration();
      }
    });
  }

  void _showSettingsDialog() {
    double tempThreshold = _breathDetector.breathThreshold;

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
                    _breathDetector.resetMaxAmplitude();
                  },
                ),
                ElevatedButton(
                  child: const Text('Recalibrate'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _recalibrate();
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
              _breathDetector.setBreathThreshold(tempThreshold);
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 30),
                // Breath visualization indicator
                BreathVisualization(
                  currentAmplitude: _currentAmplitude,
                  feedbackColor: _feedbackColor,
                ),
                const SizedBox(height: 30),
                // Breath counter display
                BreathCounterDisplay(breathCount: _breathCount),
                const SizedBox(height: 20),
                // Status display (only shows during calibration)
                StatusDisplay(
                  isCalibrating: _isCalibrating,
                  feedbackColor: _feedbackColor,
                ),
                const SizedBox(height: 40),
                // Control buttons - combined start/stop button
                BreathControls(
                  isReadyForCounting: _isReadyForCounting,
                  isCounting: _isCounting,
                  onStart: _startCounting,
                  onStop: _stopCounting,
                  onReset: _resetCounter,
                ),
                const SizedBox(height: 20),
                // Debug information
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Threshold: '),
                          Text(
                            _breathDetector.breathThreshold.toStringAsFixed(2),
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
                      const SizedBox(height: 10),
                      Text(
                        _isCalibrating
                            ? 'App is calibrating...'
                            : (_isCounting
                            ? 'Counting breaths'
                            : 'Press Start to begin counting'),
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: _isCalibrating
                              ? Colors.orange
                              : (_isCounting ? Colors.green : Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _breathDetector.dispose();
    super.dispose();
  }
}