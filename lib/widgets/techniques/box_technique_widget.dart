import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

// Box Breathing specific settings
class BoxBreathingSettings {
  int inhaleDuration;
  int holdAfterInhaleDuration;
  int exhaleDuration;
  int holdAfterExhaleDuration;
  int cycleCount;
  bool enableSounds;

  BoxBreathingSettings({
    this.inhaleDuration = 4,
    this.holdAfterInhaleDuration = 4,
    this.exhaleDuration = 4,
    this.holdAfterExhaleDuration = 4,
    this.cycleCount = 5,
    this.enableSounds = true,
  });
}

class BoxBreathingWidget extends StatefulWidget {
  final BoxBreathingSettings settings;
  final bool isActive;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;

  const BoxBreathingWidget({
    Key? key,
    required this.settings,
    required this.isActive,
    required this.onStart,
    required this.onStop,
    required this.onReset,
  }) : super(key: key);

  @override
  _BoxBreathingWidgetState createState() => _BoxBreathingWidgetState();
}

class _BoxBreathingWidgetState extends State<BoxBreathingWidget> with SingleTickerProviderStateMixin {
  // Animation controller for box animations
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Audio player for transition sounds
  final AudioPlayer _phaseCompletePlayer = AudioPlayer();
  bool _isAudioInitialized = false;

  // Timer and state tracking
  Timer? _breathTimer;
  int _currentPhase = 0; // 0: inhale, 1: hold after inhale, 2: exhale, 3: hold after exhale
  int _secondsRemaining = 0;
  int _completedCycles = 0;
  String _currentInstruction = 'Press Start to begin';

  // Animation properties
  double _topSide = 0.0;
  double _rightSide = 0.0;
  double _bottomSide = 0.0;
  double _leftSide = 0.0;
  double _centerFill = 0.0; // Property for center fill

  @override
  void initState() {
    super.initState();
    _initAudio();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );

    _animation.addListener(() {
      setState(() {
        _updateBoxSides();
      });
    });
  }

  Future<void> _initAudio() async {
    try {
      await _phaseCompletePlayer.setAsset('assets/sounds/soft-ting.mp3');
      _isAudioInitialized = true;
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  void _playPhaseCompleteSound() {
    if (_isAudioInitialized && widget.settings.enableSounds) {
      try {
        _phaseCompletePlayer.stop();
        _phaseCompletePlayer.seek(Duration.zero);
        _phaseCompletePlayer.play();
      } catch (e) {
        print('Error playing sound: $e');
        // Try to reinitialize audio
        _initAudio().then((_) {
          _phaseCompletePlayer.play();
        });
      }
    }
  }

  @override
  void didUpdateWidget(BoxBreathingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle starting/stopping the breathing timer
    if (widget.isActive && !oldWidget.isActive) {
      _startBreathingSession();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopBreathingSession();
    }

    // Check if settings changed significantly
    if (widget.settings.inhaleDuration != oldWidget.settings.inhaleDuration ||
        widget.settings.holdAfterInhaleDuration != oldWidget.settings.holdAfterInhaleDuration ||
        widget.settings.exhaleDuration != oldWidget.settings.exhaleDuration ||
        widget.settings.holdAfterExhaleDuration != oldWidget.settings.holdAfterExhaleDuration) {
      // If we're active and settings changed, restart the current phase
      if (widget.isActive) {
        // Stop current animation and timer
        _animationController.stop();
        _breathTimer?.cancel();

        // Start new phase with updated durations
        _startPhaseTimer();
      }
    }
  }

  void _startBreathingSession() {
    // Ensure proper initialization
    if (_breathTimer != null) {
      _breathTimer!.cancel();
    }
    if (_animationController.isAnimating) {
      _animationController.stop();
    }

    setState(() {
      _currentPhase = 0;
      _completedCycles = 0;
      _resetBoxSides();
      _currentInstruction = 'Inhale';
    });

    _startPhaseTimer();
  }

  void _stopBreathingSession() {
    _breathTimer?.cancel();
    _animationController.reset();
    _resetBoxSides();

    setState(() {
      _currentInstruction = 'Press Start to begin';
    });
  }

  void _startPhaseTimer() {
    // Clean up any existing timer
    _breathTimer?.cancel();

    // Get the duration for current phase
    int phaseDuration;
    switch (_currentPhase) {
      case 0: // Inhale
        phaseDuration = widget.settings.inhaleDuration;
        break;
      case 1: // Hold after inhale
        phaseDuration = widget.settings.holdAfterInhaleDuration;
        break;
      case 2: // Exhale
        phaseDuration = widget.settings.exhaleDuration;
        break;
      case 3: // Hold after exhale
        phaseDuration = widget.settings.holdAfterExhaleDuration;
        break;
      default:
        phaseDuration = widget.settings.inhaleDuration;
    }

    // Initialize seconds remaining
    _secondsRemaining = phaseDuration;

    // Start a new timer that counts down one second at a time
    _breathTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 1) {
            _secondsRemaining--;
          } else {
            // We're at the last second, so prepare to transition
            timer.cancel(); // Cancel current timer
            _moveToNextPhase(); // Move to next phase
          }
        });
      }
    });

    // Start animation for current phase
    _animationController.reset();
    _animationController.duration = Duration(seconds: phaseDuration);
    _animationController.forward();
  }

  void _moveToNextPhase() {
    // Play sound at each phase transition
    _playPhaseCompleteSound();

    // Move to next phase
    int previousPhase = _currentPhase;
    _currentPhase = (_currentPhase + 1) % 4;

    // Check if completed a full cycle
    bool startingNewCycle = _currentPhase == 0;
    if (startingNewCycle) {
      _completedCycles++;

      // Reset the sides when starting a new cycle
      _resetBoxSides();

      if (_completedCycles >= widget.settings.cycleCount) {
        // Session complete
        widget.onStop();
        setState(() {
          _currentInstruction = 'Session Complete';
        });
        return;
      }
    }

    // Set up new phase
    setState(() {
      switch (_currentPhase) {
        case 0: // Inhale
          _currentInstruction = 'Inhale';
          break;
        case 1: // Hold after inhale
          _currentInstruction = 'Hold';
          break;
        case 2: // Exhale
          _currentInstruction = 'Exhale';
          break;
        case 3: // Hold after exhale
          _currentInstruction = 'Hold Empty';
          break;
      }
    });

    // Start new phase timer and animation
    _startPhaseTimer();
  }

  void _updateBoxSides() {
    // Calculate overall progress through the four phases
    double totalPhases = 4.0;
    double currentProgress = ((_currentPhase / totalPhases) + (_animation.value / totalPhases));

    // Update center fill based on total progress (0.0 to 1.0 across all 4 phases)
    _centerFill = currentProgress;

    // Update individual sides
    switch (_currentPhase) {
      case 0: // Inhale - fill left side
      // Clear previous sides when starting a new cycle
        if (_animation.value < 0.1) {
          _topSide = 0.0;
          _rightSide = 0.0;
          _bottomSide = 0.0;
        }
        _leftSide = _animation.value;
        break;
      case 1: // Hold after inhale - fill top side
        _leftSide = 1.0; // Ensure previous side is fully filled
        _topSide = _animation.value;
        break;
      case 2: // Exhale - fill right side
        _leftSide = 1.0;
        _topSide = 1.0; // Ensure previous sides are fully filled
        _rightSide = _animation.value;
        break;
      case 3: // Hold after exhale - fill bottom side
        _leftSide = 1.0;
        _topSide = 1.0;
        _rightSide = 1.0; // Ensure previous sides are fully filled
        _bottomSide = _animation.value;
        break;
    }
  }

  void _resetBoxSides() {
    _topSide = 0.0;
    _rightSide = 0.0;
    _bottomSide = 0.0;
    _leftSide = 0.0;
    _centerFill = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        // Instruction card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: widget.isActive ? Colors.blue : Colors.grey.withOpacity(0.5),
              width: widget.isActive ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Box Breathing',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Inhale ${widget.settings.inhaleDuration}s → Hold ${widget.settings.holdAfterInhaleDuration}s → Exhale ${widget.settings.exhaleDuration}s → Hold ${widget.settings.holdAfterExhaleDuration}s',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                if (widget.isActive) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Cycle: ${_completedCycles + 1} of ${widget.settings.cycleCount}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),

        // Box animation
        Stack(
          alignment: Alignment.center,
          children: [
            // Box
            Container(
              width: 220,
              height: 220,
              child: CustomPaint(
                painter: BoxBreathingPainter(
                  topSide: _topSide,
                  rightSide: _rightSide,
                  bottomSide: _bottomSide,
                  leftSide: _leftSide,
                  centerFill: _centerFill,
                  isActive: widget.isActive,
                ),
              ),
            ),
            // Phase instruction and time
            if (widget.isActive)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentInstruction,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.9),
                      border: Border.all(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$_secondsRemaining',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),

        const SizedBox(height: 40),

        // Simple controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: widget.isActive ? widget.onStop : widget.onStart,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              child: Text(widget.isActive ? 'Stop' : 'Start'),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: widget.onReset,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              child: const Text('Reset'),
            ),
          ],
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  @override
  void dispose() {
    _breathTimer?.cancel();
    _animationController.dispose();
    _phaseCompletePlayer.dispose();
    super.dispose();
  }
}

// Custom painter for box breathing animation
class BoxBreathingPainter extends CustomPainter {
  final double topSide;
  final double rightSide;
  final double bottomSide;
  final double leftSide;
  final double centerFill;
  final bool isActive;

  BoxBreathingPainter({
    required this.topSide,
    required this.rightSide,
    required this.bottomSide,
    required this.leftSide,
    required this.centerFill,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint inactivePaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke;

    final Paint activePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke;

    final Paint fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Define box rectangle
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw inactive box outline
    canvas.drawRect(rect, inactivePaint);

    // Draw center fill that grows from the center
    if (isActive && centerFill > 0) {
      final double centerSize = size.width * centerFill;
      final double offset = (size.width - centerSize) / 2;

      final Rect centerRect = Rect.fromLTWH(
          offset,
          offset,
          centerSize,
          centerSize
      );

      canvas.drawRect(centerRect, fillPaint);
    }

    if (isActive) {
      // Draw active sides with stroke cap to ensure complete corners
      final Paint leftPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.square;

      final Paint topPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.square;

      final Paint rightPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.square;

      final Paint bottomPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.square;

      // Left side (inhale)
      if (leftSide > 0) {
        canvas.drawLine(
          Offset(0, size.height),
          Offset(0, size.height * (1 - leftSide)),
          leftPaint,
        );
      }

      // Top side (hold after inhale)
      if (topSide > 0) {
        canvas.drawLine(
          Offset(0, 0),
          Offset(size.width * topSide, 0),
          topPaint,
        );
      }

      // Right side (exhale)
      if (rightSide > 0) {
        canvas.drawLine(
          Offset(size.width, 0),
          Offset(size.width, size.height * rightSide),
          rightPaint,
        );
      }

      // Bottom side (hold after exhale)
      if (bottomSide > 0) {
        canvas.drawLine(
          Offset(size.width, size.height),
          Offset(size.width * (1 - bottomSide), size.height),
          bottomPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BoxBreathingPainter oldDelegate) {
    return oldDelegate.topSide != topSide ||
        oldDelegate.rightSide != rightSide ||
        oldDelegate.bottomSide != bottomSide ||
        oldDelegate.leftSide != leftSide ||
        oldDelegate.centerFill != centerFill ||
        oldDelegate.isActive != isActive;
  }
}