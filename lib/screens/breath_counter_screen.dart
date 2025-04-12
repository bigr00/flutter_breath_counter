import 'package:flutter/material.dart';
import '../services/breath_detector.dart';
import '../services/audio_service.dart';
import '../services/breathing_techniques_service.dart';
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
  late BreathDetector _breathDetector;
  late AudioService _audioService;
  late BreathingTechniquesService _breathingTechniquesService;

  // Common state variables
  int _breathCount = 0;
  double _currentAmplitude = 0;
  bool _isCalibrating = false;
  bool _isReadyForCounting = false;
  bool _isCounting = false;
  Color _feedbackColor = Colors.grey;
  String _currentInstruction = '';

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

    _breathingTechniquesService = BreathingTechniquesService(
      onInstructionChange: (instruction) {
        setState(() {
          _currentInstruction = instruction;
        });
      },
      onBreathHoldInstructionChange: (shouldHold) {
        if (shouldHold && !_isHoldingBreath) {
          _toggleBreathHold();
        } else if (!shouldHold && _isHoldingBreath) {
          _toggleBreathHold();
        }
      },
    );
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

            // Directly start breath hold - don't use toggle in case we're in an unexpected state
            _breathDetector.startBreathHold();

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
            _breathDetector.stopBreathHold();

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

    await _breathDetector.initialize();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _breathDetector.startCalibration();
      }
    });
  }

  void _onTechniqueSelected(BreathingTechnique technique) {
    // Stop current session if active
    if (_isCounting) {
      _stopCounting();
    }

    setState(() {
      _selectedTechnique = technique;
      // Reset counters when changing techniques
      _breathCount = 0;
      _breathHoldDuration = 0;
      if (_isHoldingBreath) {
        _breathDetector.stopBreathHold();
        _isHoldingBreath = false;
      }
    });

    // Notify the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${technique.name} breathing'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _startCounting() {
    if (!_isCounting && _isReadyForCounting) {
      setState(() {
        _isCounting = true;
      });

      // Only start breath detection for Tummo
      if (_selectedTechnique.type == BreathingTechniqueType.tummo) {
        _breathDetector.startBreathDetection();
      }

      _breathingTechniquesService.startTechnique(_selectedTechnique.type);
    }
  }

  void _stopCounting() {
    if (_isCounting) {
      // Save the session to history when stopping
      if (_selectedTechnique.type == BreathingTechniqueType.tummo) {
        _saveToHistory();
      }

      setState(() {
        _isCounting = false;
        _isReadyForCounting = true;

        // If we were holding a breath, also reset that state
        if (_isHoldingBreath) {
          _breathDetector.stopBreathHold();
        }
      });

      if (_selectedTechnique.type == BreathingTechniqueType.tummo) {
        _breathDetector.stopBreathDetection();
      }

      _breathingTechniquesService.stopTechnique();
    }
  }

  void _resetCounter() {
    // Save current session to history before resetting if there's data to save
    if (_selectedTechnique.type == BreathingTechniqueType.tummo &&
        (_breathCount > 0 || _breathHoldDuration > 0)) {
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

    if (_selectedTechnique.type == BreathingTechniqueType.tummo) {
      _breathDetector.resetState();
    }

    // If we're in the middle of a technique, restart it
    if (_isCounting) {
      _breathingTechniquesService.startTechnique(_selectedTechnique.type);
    }
  }

  void _toggleBreathHold() {
    if (_isHoldingBreath) {
      // If we're ending a breath hold with a duration, save to history
      if (_breathHoldDuration > 0 && _selectedTechnique.type == BreathingTechniqueType.tummo) {
        _saveToHistory();
      }

      // Stop the breath hold
      _breathDetector.stopBreathHold();

      // Also stop counting - put in same state as Stop button
      _stopCounting();
    } else {
      _breathDetector.startBreathHold();
    }
  }

  void _saveToHistory() {
    // Only save if there are breaths or a hold for Tummo technique
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

    Future.delayed(const Duration(milliseconds: 500), () {
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
              _breathDetector.setBreathThreshold(newSettings.breathThreshold);
            },
            onRecalibrate: _recalibrate,
            onResetMaxAmplitude: () {
              _breathDetector.resetMaxAmplitude();
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

  // This method renders the appropriate technique widget based on the selected technique
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
          currentInstruction: _currentInstruction,
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
          isActive: _isCounting,
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
    if (_selectedTechnique.type == BreathingTechniqueType.tummo &&
        (_breathCount > 0 || _breathHoldDuration > 0)) {
      _saveToHistory();
    }
    _breathDetector.dispose();
    _audioService.dispose();
    _breathingTechniquesService.dispose();
    super.dispose();
  }
}