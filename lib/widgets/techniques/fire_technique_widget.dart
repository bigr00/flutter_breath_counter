import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

// Fire Breath specific settings
class FireBreathSettings {
  int targetBreathCount;
  int roundCount;
  bool enableSounds;

  FireBreathSettings({
    this.targetBreathCount = 30,
    this.roundCount = 3,
    this.enableSounds = true,
  });
}

class FireBreathWidget extends StatefulWidget {
  final FireBreathSettings settings;
  final double currentAmplitude;
  final Color feedbackColor;
  final bool isCalibrating;
  final bool isReadyForCounting;
  final bool isCounting;
  final int breathCount;
  final String currentInstruction;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;

  const FireBreathWidget({
    Key? key,
    required this.settings,
    required this.currentAmplitude,
    required this.feedbackColor,
    required this.isCalibrating,
    required this.isReadyForCounting,
    required this.isCounting,
    required this.breathCount,
    required this.currentInstruction,
    required this.onStart,
    required this.onStop,
    required this.onReset,
  }) : super(key: key);

  @override
  _FireBreathWidgetState createState() => _FireBreathWidgetState();
}

class _FireBreathWidgetState extends State<FireBreathWidget> {
  // Audio player for transition sounds
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioInitialized = false;

  // Track current round based on breath count
  int _getCurrentRound() {
    if (widget.breathCount < widget.settings.targetBreathCount) {
      return 1;
    } else {
      // Calculate current round based on breath count and target
      int completedRounds = widget.breathCount ~/ widget.settings.targetBreathCount;
      // If we've completed all rounds, cap at the max round
      return completedRounds < widget.settings.roundCount ?
      completedRounds + 1 :
      widget.settings.roundCount;
    }
  }

  // Get breaths in current round
  int _getBreathsInCurrentRound() {
    return widget.breathCount % widget.settings.targetBreathCount;
  }

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setAsset('assets/sounds/soft-ting.m4a');
      _isAudioInitialized = true;
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate current round and progress
    final int currentRound = _getCurrentRound();
    final int breathsInCurrentRound = _getBreathsInCurrentRound();

    // Calculate progress percentage for current round
    double progressPercentage = widget.settings.targetBreathCount > 0
        ? breathsInCurrentRound / widget.settings.targetBreathCount
        : 0.0;

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
              color: widget.isCounting ? Colors.orange : Colors.grey.withOpacity(0.5),
              width: widget.isCounting ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Fire Breath',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Rapid breathing detected via microphone',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rapid exhale through nose, automatic inhale into the next exhale',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Display status when calibrating
        if (widget.isCalibrating)
          Text(
            'Calibrating...',
            style: TextStyle(
              fontSize: 18,
              color: widget.feedbackColor,
            ),
          ),

        // Current instruction from breathing technique service
        if (widget.currentInstruction.isNotEmpty && widget.isCounting)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              widget.currentInstruction,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.feedbackColor,
              ),
            ),
          ),

        const SizedBox(height: 20),

        // Breath Visualization - connected to amplitude from detector
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.feedbackColor,
              width: 3,
            ),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 160 * widget.currentAmplitude,
              height: 160 * widget.currentAmplitude,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    widget.feedbackColor,
                    Colors.deepOrange.withOpacity(0.7),
                  ],
                  stops: const [0.5, 1.0],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.feedbackColor.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Breath counter
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange),
            color: Colors.orange.withOpacity(0.1),
          ),
          child: Column(
            children: [
              const Text(
                  'Breaths Taken:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    // Connected to the actual breath count from the detector
                    '${widget.breathCount}',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '/ ${widget.settings.targetBreathCount * widget.settings.roundCount}',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Round progress
              if (widget.isCounting)
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Round: ', style: TextStyle(fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Text(
                            '$currentRound / ${widget.settings.roundCount}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Progress bar for current round
                    SizedBox(
                      width: 180,
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: progressPercentage,
                            backgroundColor: Colors.orange.withOpacity(0.2),
                            color: Colors.orange,
                            minHeight: 8,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$breathsInCurrentRound / ${widget.settings.targetBreathCount} in this round',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: widget.isReadyForCounting ?
              (widget.isCounting ? widget.onStop : widget.onStart) : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                backgroundColor: Colors.orange,
              ),
              child: Text(widget.isCounting ? 'Stop' : 'Start'),
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
    _audioPlayer.dispose();
    super.dispose();
  }
}