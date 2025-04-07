import 'package:flutter/material.dart';
import '../services/breath_detector.dart';
import '../widgets/breath_visualization.dart';
import '../widgets/breath_counter_display.dart';
import '../widgets/breath_controls.dart';
import '../widgets/status_display.dart';
import '../widgets/breath_hold_timer.dart';
import '../widgets/breath_history_dialog.dart';
import '../models/breath_history_item.dart';

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

  // Breath hold state
  bool _isHoldingBreath = false;
  int _breathHoldDuration = 0;

  // History tracking
  List<BreathHistoryItem> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _initializeDetector();
  }

  Future<void> _initializeDetector() async {
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
            case BreathState.holding:
              _feedbackColor = Colors.amber;
              break;
            case BreathState.idle:
              _feedbackColor = _isCalibrating ? Colors.orange : Colors.grey;
              break;
          }
        });
      },
      onBreathHoldChange: (isHolding, duration) {
        if (mounted) {
          // If we're ending a breath hold, record it in history
          if (_isHoldingBreath && !isHolding && _breathHoldDuration > 0) {
            _saveToHistory();
          }

          setState(() {
            _isHoldingBreath = isHolding;
            _breathHoldDuration = duration;
          });
        }
      },
    );

    await _breathDetector.initialize();

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
      // Save the session to history when stopping
      _saveToHistory();

      setState(() {
        _isCounting = false;
        _isReadyForCounting = true;

        // If we were holding a breath, also reset that state
        if (_isHoldingBreath) {
          _breathDetector.stopBreathHold();
        }
      });
      _breathDetector.stopBreathDetection();
    }
  }

  void _resetCounter() {
    // Save current session to history before resetting if there's data to save
    if (_breathCount > 0 || _breathHoldDuration > 0) {
      _saveToHistory();
    }

    setState(() {
      _breathCount = 0;

      // Reset breath hold information as well
      if (_isHoldingBreath) {
        _breathDetector.stopBreathHold();
      }
      _breathHoldDuration = 0;
    });
    _breathDetector.resetState();
  }

  void _toggleBreathHold() {
    // If we're ending a breath hold with a duration, save to history
    if (_isHoldingBreath && _breathHoldDuration > 0) {
      _saveToHistory();
    }
    _breathDetector.toggleBreathHold();
  }

  void _saveToHistory() {
    // Only save if there are breaths or a hold
    if (_breathCount > 0 || _breathHoldDuration > 0) {
      setState(() {
        _historyItems.add(
          BreathHistoryItem(
            timestamp: DateTime.now(),
            breathCount: _breathCount,
            holdDuration: _breathHoldDuration,
          ),
        );
      });
    }
  }

  void _provideFeedback() {
    Color originalColor = _feedbackColor;

    if (mounted) {
      setState(() {
        _feedbackColor = Colors.orange;
      });

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
    if (_isCounting) {
      _stopCounting();
    }

    // End any active breath hold
    if (_isHoldingBreath) {
      _breathDetector.stopBreathHold();
    }

    setState(() {
      _isReadyForCounting = false;
      _isCounting = false;
    });

    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _breathDetector.startCalibration();
      }
    });
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => BreathHistoryDialog(
        historyItems: _historyItems,
      ),
    );
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
            icon: const Icon(Icons.history),
            onPressed: _showHistoryDialog,
            tooltip: 'View history',
          ),
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
                BreathVisualization(
                  currentAmplitude: _currentAmplitude,
                  feedbackColor: _feedbackColor,
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breath counter
                      const Spacer(),
                      BreathCounterDisplay(breathCount: _breathCount),
                      const SizedBox(width: 40), // Reduced spacing between counters
                      // Breath hold timer
                      BreathHoldTimer(
                        isActive: _isHoldingBreath,
                        durationInSeconds: _breathHoldDuration,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                StatusDisplay(
                  isCalibrating: _isCalibrating,
                  feedbackColor: _feedbackColor,
                ),
                const SizedBox(height: 20),
                BreathControls(
                  isReadyForCounting: _isReadyForCounting,
                  isCounting: _isCounting,
                  isHoldingBreath: _isHoldingBreath,
                  onStart: _startCounting,
                  onStop: _stopCounting,
                  onReset: _resetCounter,
                  onToggleBreathHold: _toggleBreathHold,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Save any unsaved session before disposing
    if (_breathCount > 0 || _breathHoldDuration > 0) {
      _saveToHistory();
    }
    _breathDetector.dispose();
    super.dispose();
  }
}