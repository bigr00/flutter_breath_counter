import 'package:flutter/material.dart';
import '../services/breath_detectors/tummo_breath_detector.dart';
import '../services/breath_detectors/fire_breath_detector.dart';
import '../services/audio_service.dart';
import '../widgets/breath_history_dialog.dart';
import '../models/breath_history_item.dart';
import '../models/breathing_technique.dart';

// Import all technique widgets
import '../widgets/techniques/tummo_technique_widget.dart';
import '../widgets/techniques/box_technique_widget.dart';
import '../widgets/techniques/fire_technique_widget.dart';
import '../widgets/techniques/three_part_technique_widget.dart';

// Import technique-specific settings dialogs
import '../widgets/settings/tummo_settings_dialog.dart';
import '../widgets/settings/box_breathing_settings_dialog.dart';
import '../widgets/settings/fire_breath_settings_dialog.dart';
import '../widgets/settings/three_part_breath_settings_dialog.dart';

class BreathCounterScreen extends StatefulWidget {
  const BreathCounterScreen({Key? key}) : super(key: key);

  @override
  _BreathCounterScreenState createState() => _BreathCounterScreenState();
}

class _BreathCounterScreenState extends State<BreathCounterScreen> {
  // Breath detectors for different techniques
  TummoBreathDetector? _tummoBreathDetector;
  FireBreathDetector? _fireBreathDetector;

  late AudioService _audioService;

  // Common state variables
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

  // Technique-specific settings
  late TummoSettings _tummoSettings;
  late BoxBreathingSettings _boxBreathingSettings;
  late FireBreathSettings _fireBreathSettings;
  late ThreePartBreathSettings _threePartBreathSettings;

  // Selected technique
  BreathingTechnique _selectedTechnique = BreathingTechnique.tummo;

  @override
  void initState() {
    super.initState();

    // Initialize technique-specific settings
    _tummoSettings = TummoSettings();
    _boxBreathingSettings = BoxBreathingSettings();
    _fireBreathSettings = FireBreathSettings();
    _threePartBreathSettings = ThreePartBreathSettings();

    _audioService = AudioService();
    _initializeDetector();
    _audioService.initialize();
  }

  Future<void> _initializeDetector() async {
    // Initialize Tummo breath detector by default
    _initializeTummoDetector();
  }

  void _initializeTummoDetector() {
    _tummoBreathDetector = TummoBreathDetector(
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
        if (_isCounting && mounted && _selectedTechnique.type == BreathingTechniqueType.tummo) {
          setState(() {
            _breathCount++;
          });
          _provideFeedback();

          // Check if target breath count is reached for Tummo
          if (_tummoSettings.enableAutoHold &&
              _breathCount >= _tummoSettings.targetBreathCount &&
              !_isHoldingBreath) {
            // Play sound if enabled
            if (_tummoSettings.enableSounds) {
              _audioService.playBreathCountReached();
            }

            // Directly start breath hold
            _tummoBreathDetector?.startBreathHold();

            // Notify user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Target breath count (${_tummoSettings.targetBreathCount}) reached! Starting breath hold.'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
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

          // Check if target hold duration is reached for Tummo
          if (isHolding &&
              duration >= _tummoSettings.targetHoldDuration &&
              _tummoSettings.enableAutoHold) {
            // Play sound if enabled
            if (_tummoSettings.enableSounds) {
              _audioService.playHoldTimerReached();
            }

            // Directly stop the breath hold
            _tummoBreathDetector?.stopBreathHold();

            // Also stop counting - put in same state as Stop button
            _stopCounting();

            // Notify user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Target hold duration (${_tummoSettings.targetHoldDuration} seconds) reached!'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
    );

    _tummoBreathDetector?.initialize().then((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _tummoBreathDetector?.startCalibration();
          }
        });
      }
    });
  }

  void _initializeFireBreathDetector() {
    _fireBreathDetector = FireBreathDetector(
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
              content: Text('Calibration complete. Press Start to begin.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      onBreathDetected: () {
        if (_isCounting && mounted && _selectedTechnique.type == BreathingTechniqueType.fireBreath) {
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
            case FireBreathState.exhaling:
              _feedbackColor = Colors.orange;
              break;
            case FireBreathState.idle:
              _feedbackColor = _isCalibrating ? Colors.orange : Colors.grey;
              break;
          }
        });
      },
    );

    _fireBreathDetector?.initialize().then((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _fireBreathDetector?.startCalibration();
          }
        });
      }
    });
  }

  void _onTechniqueSelected(BreathingTechnique technique) {
    // Stop current session if active
    if (_isCounting) {
      _stopCounting();
    }

    // Clean up current detector if needed
    _disposeCurrentDetector();

    setState(() {
      _selectedTechnique = technique;
      // Reset counters when changing techniques
      _breathCount = 0;
      _breathHoldDuration = 0;
      _isHoldingBreath = false;
    });

    // Initialize the appropriate detector for the selected technique
    _initializeDetectorForTechnique(technique.type);

    // Notify the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${technique.name} breathing'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _initializeDetectorForTechnique(BreathingTechniqueType type) {
    switch (type) {
      case BreathingTechniqueType.tummo:
        _initializeTummoDetector();
        break;
      case BreathingTechniqueType.fireBreath:
        _initializeFireBreathDetector();
        break;
      case BreathingTechniqueType.boxBreathing:
      case BreathingTechniqueType.threePartBreath:
      // These techniques don't use microphone detection
        break;
    }
  }

  void _disposeCurrentDetector() {
    // Dispose the current detector if any
    if (_tummoBreathDetector != null) {
      _tummoBreathDetector?.dispose();
      _tummoBreathDetector = null;
    }
    if (_fireBreathDetector != null) {
      _fireBreathDetector?.dispose();
      _fireBreathDetector = null;
    }
  }

  void _startCounting() {
    if (!_isCounting && _isReadyForCounting) {
      setState(() {
        _isCounting = true;
      });

      // Start detection based on technique
      switch (_selectedTechnique.type) {
        case BreathingTechniqueType.tummo:
          _tummoBreathDetector?.startBreathDetection();
          break;
        case BreathingTechniqueType.fireBreath:
          _fireBreathDetector?.startBreathDetection();
          break;
        default:
        // Other techniques don't use microphone detection
          break;
      }

    }
  }

  void _stopCounting() {
    if (_isCounting) {
      // Save the session to history when stopping
      if (_selectedTechnique.type == BreathingTechniqueType.tummo ||
          _selectedTechnique.type == BreathingTechniqueType.fireBreath) {
        _saveToHistory();
      }

      setState(() {
        _isCounting = false;
        _isReadyForCounting = true;

        // If we were holding a breath, also reset that state
        if (_isHoldingBreath) {
          _tummoBreathDetector?.stopBreathHold();
        }
      });

      // Stop detection based on technique
      switch (_selectedTechnique.type) {
        case BreathingTechniqueType.tummo:
          _tummoBreathDetector?.stopBreathDetection();
          break;
        case BreathingTechniqueType.fireBreath:
          _fireBreathDetector?.stopBreathDetection();
          break;
        default:
        // Other techniques don't use microphone detection
          break;
      }

    }
  }

  void _resetCounter() {
    // Save current session to history before resetting if there's data to save
    if ((_selectedTechnique.type == BreathingTechniqueType.tummo && (_breathCount > 0 || _breathHoldDuration > 0)) ||
        (_selectedTechnique.type == BreathingTechniqueType.fireBreath && _breathCount > 0)) {
      _saveToHistory();
    }

    setState(() {
      _breathCount = 0;

      // Reset breath hold information as well
      if (_isHoldingBreath) {
        _tummoBreathDetector?.stopBreathHold();
      }
      _breathHoldDuration = 0;
    });

    // Reset state based on technique
    switch (_selectedTechnique.type) {
      case BreathingTechniqueType.tummo:
        _tummoBreathDetector?.resetState();
        break;
      case BreathingTechniqueType.fireBreath:
        _fireBreathDetector?.resetState();
        break;
      default:
      // Other techniques don't use detector state
        break;
    }

  }

  void _toggleBreathHold() {
    // Only Tummo has breath hold functionality
    if (_selectedTechnique.type != BreathingTechniqueType.tummo) return;

    if (_isHoldingBreath) {
      // If we're ending a breath hold with a duration, save to history
      if (_breathHoldDuration > 0) {
        _saveToHistory();
      }

      // Stop the breath hold
      _tummoBreathDetector?.stopBreathHold();

      // Also stop counting - put in same state as Stop button
      _stopCounting();
    } else {
      _tummoBreathDetector?.startBreathHold();
    }
  }

  void _saveToHistory() {
    // Save based on technique type
    if (_selectedTechnique.type == BreathingTechniqueType.tummo) {
      // For Tummo, we save breaths and hold duration
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
    } else if (_selectedTechnique.type == BreathingTechniqueType.fireBreath) {
      // For Fire Breath, we only save breath count
      if (_breathCount > 0) {
        setState(() {
          _historyItems.add(
            BreathHistoryItem(
              timestamp: DateTime.now(),
              breathCount: _breathCount,
              holdDuration: 0, // No hold for fire breath
            ),
          );
        });
      }
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

    // End any active breath hold for Tummo
    if (_isHoldingBreath && _selectedTechnique.type == BreathingTechniqueType.tummo) {
      _tummoBreathDetector?.stopBreathHold();
    }

    setState(() {
      _isReadyForCounting = false;
      _isCounting = false;
    });

    // Recalibrate based on technique
    switch (_selectedTechnique.type) {
      case BreathingTechniqueType.tummo:
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _tummoBreathDetector?.startCalibration();
          }
        });
        break;
      case BreathingTechniqueType.fireBreath:
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _fireBreathDetector?.startCalibration();
          }
        });
        break;
      default:
      // Other techniques don't use microphone calibration
        break;
    }
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => BreathHistoryDialog(
        historyItems: _historyItems,
      ),
    );
  }

  void _showTechniqueSettings() {
    switch (_selectedTechnique.type) {
      case BreathingTechniqueType.tummo:
        showDialog(
          context: context,
          builder: (context) => TummoSettingsDialog(
            settings: _tummoSettings,
            onSettingsChanged: (newSettings) {
              setState(() {
                _tummoSettings = newSettings;
              });
              _tummoBreathDetector?.setBreathThreshold(newSettings.breathThreshold);
            },
            onRecalibrate: _recalibrate,
            onResetMaxAmplitude: () {
              _tummoBreathDetector?.resetMaxAmplitude();
            },
          ),
        );
        break;

      case BreathingTechniqueType.boxBreathing:
        showDialog(
          context: context,
          builder: (context) => BoxBreathingSettingsDialog(
            settings: _boxBreathingSettings,
            onSettingsChanged: (newSettings) {
              setState(() {
                _boxBreathingSettings = newSettings;
              });
            },
          ),
        );
        break;

      case BreathingTechniqueType.fireBreath:
        showDialog(
          context: context,
          builder: (context) => FireBreathSettingsDialog(
            settings: _fireBreathSettings,
            onSettingsChanged: (newSettings) {
              setState(() {
                _fireBreathSettings = newSettings;
              });
            },
          ),
        );
        break;

      case BreathingTechniqueType.threePartBreath:
        showDialog(
          context: context,
          builder: (context) => ThreePartBreathSettingsDialog(
            settings: _threePartBreathSettings,
            onSettingsChanged: (newSettings) {
              setState(() {
                _threePartBreathSettings = newSettings;
              });
            },
          ),
        );
        break;
    }
  }

// Updates needed in the _buildActiveTechniqueWidget() method in BreathCounterScreen:

  Widget _buildActiveTechniqueWidget() {
    switch (_selectedTechnique.type) {
      case BreathingTechniqueType.tummo:
        return TummoBreathWidget(
          settings: _tummoSettings,
          currentAmplitude: _currentAmplitude,
          feedbackColor: _feedbackColor,
          isCalibrating: _isCalibrating,
          isReadyForCounting: _isReadyForCounting,
          isCounting: _isCounting,
          isHoldingBreath: _isHoldingBreath,
          breathCount: _breathCount,
          breathHoldDuration: _breathHoldDuration,
          onStart: _startCounting,
          onStop: _stopCounting,
          onReset: _resetCounter,
          onToggleBreathHold: _toggleBreathHold,
        );

      case BreathingTechniqueType.boxBreathing:
        return BoxBreathingWidget(
          settings: _boxBreathingSettings,
          isActive: _isCounting,
          onStart: _startCounting,
          onStop: _stopCounting,
          onReset: _resetCounter,
        );

      case BreathingTechniqueType.fireBreath:
        return FireBreathWidget(
          settings: _fireBreathSettings,
          currentAmplitude: _currentAmplitude,
          feedbackColor: _feedbackColor,
          isCalibrating: _isCalibrating,
          isReadyForCounting: _isReadyForCounting,
          isCounting: _isCounting,
          breathCount: _breathCount,
          onStart: _startCounting,
          onStop: _stopCounting,
          onReset: _resetCounter,
        );

      case BreathingTechniqueType.threePartBreath:
        return ThreePartBreathWidget(
          settings: _threePartBreathSettings,
          isActive: _isCounting,
          onStart: _startCounting,
          onStop: _stopCounting,
          onReset: _resetCounter,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_selectedTechnique.name} Breathing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showTechniqueSettings,
            tooltip: 'Technique Settings',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistoryDialog,
            tooltip: 'View history',
          ),
        ],
      ),
      body: Row(
        children: [
          // Main breathing technique area (left side)
          Expanded(
            flex: 3,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildActiveTechniqueWidget(),
                ),
              ),
            ),
          ),

          // Technique selector (right side)
          SizedBox(
            width: 200,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  left: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Technique selector header
                  Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Breathing Techniques',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Technique selector list
                  Expanded(
                    child: ListView.builder(
                      itemCount: BreathingTechnique.allTechniques.length,
                      itemBuilder: (context, index) {
                        final technique = BreathingTechnique.allTechniques[index];
                        final isSelected = _selectedTechnique.type == technique.type;

                        return ListTile(
                          title: Text(
                            technique.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.blue : null,
                            ),
                          ),
                          subtitle: Text(
                            technique.description,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          selected: isSelected,
                          selectedTileColor: Colors.blue.withOpacity(0.1),
                          onTap: () => _onTechniqueSelected(technique),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Save any unsaved session before disposing
    if (_selectedTechnique.type == BreathingTechniqueType.tummo && (_breathCount > 0 || _breathHoldDuration > 0)) {
      _saveToHistory();
    } else if (_selectedTechnique.type == BreathingTechniqueType.fireBreath && _breathCount > 0) {
      _saveToHistory();
    }

    // Clean up detectors
    _disposeCurrentDetector();

    _audioService.dispose();
    super.dispose();
  }
}