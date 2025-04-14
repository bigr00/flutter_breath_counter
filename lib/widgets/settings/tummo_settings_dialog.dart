import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/techniques/tummo_technique_widget.dart';

class TummoSettingsDialog extends StatefulWidget {
  final TummoSettings settings;
  final Function(TummoSettings) onSettingsChanged;
  final VoidCallback onRecalibrate;
  final VoidCallback onResetMaxAmplitude;

  const TummoSettingsDialog({
    Key? key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onRecalibrate,
    required this.onResetMaxAmplitude,
  }) : super(key: key);

  @override
  _TummoSettingsDialogState createState() => _TummoSettingsDialogState();
}

class _TummoSettingsDialogState extends State<TummoSettingsDialog> {
  late TextEditingController _breathCountController;
  late TextEditingController _holdDurationController;
  late bool _useAutomaticBreathCounterAndHolder;
  late bool _stopAutomaticBreathHold;
  late bool _enableSounds;
  late double _tempThreshold;

  @override
  void initState() {
    super.initState();
    _breathCountController = TextEditingController(text: widget.settings.targetBreathCount.toString());
    _holdDurationController = TextEditingController(text: widget.settings.targetHoldDuration.toString());
    _useAutomaticBreathCounterAndHolder = widget.settings.useAutomaticBreathCounterAndHolder;
    _stopAutomaticBreathHold = widget.settings.stopAutomaticBreathHold;
    _enableSounds = widget.settings.enableSounds;
    _tempThreshold = widget.settings.breathThreshold;
  }

  @override
  void dispose() {
    _breathCountController.dispose();
    _holdDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tummo Breathing Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Breath Detection Sensitivity', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: _tempThreshold,
                min: 0.1,
                max: 0.7,
                divisions: 30,
                label: _tempThreshold.toStringAsFixed(2),
                onChanged: (value) {
                  setState(() {
                    _tempThreshold = value;
                  });
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('More sensitive', style: TextStyle(fontSize: 12)),
                Text('Less sensitive', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Tummo Automation', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),


            SwitchListTile(
              title: const Text('Use Automatic Counter/Hold'),
              subtitle: const Text('Auto count breaths and start/stop hold based on targets'),
              value: _useAutomaticBreathCounterAndHolder,
              onChanged: (value) {
                setState(() {
                  _useAutomaticBreathCounterAndHolder = value;

                  if (!value) {
                    _stopAutomaticBreathHold = true;
                  }
                });
              },
            ),


            AnimatedOpacity(
              opacity: _useAutomaticBreathCounterAndHolder ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 300),
              child: SwitchListTile(
                title: const Text('Stop Automatic Breath Hold'),
                subtitle: const Text('Automatically stop hold when target duration is reached (if OFF, hold continues indefinitely)'),
                value: _stopAutomaticBreathHold,

                onChanged: _useAutomaticBreathCounterAndHolder ? (value) {
                  setState(() {
                    _stopAutomaticBreathHold = value;
                  });
                } : null,
              ),
            ),

            const SizedBox(height: 10),
            const Text('Targets (Used for Automation)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),


            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: TextFormField(
                controller: _breathCountController,
                decoration: const InputDecoration(
                  labelText: 'Target Breath Count',
                  hintText: 'E.g., 40 breaths',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: _useAutomaticBreathCounterAndHolder,
              ),
            ),


            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: TextFormField(
                controller: _holdDurationController,
                decoration: const InputDecoration(
                  labelText: 'Target Hold Duration (seconds)',
                  hintText: 'E.g., 90 seconds',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: _useAutomaticBreathCounterAndHolder,
              ),
            ),

            const SizedBox(height: 10),
            const Text('Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),


            SwitchListTile(
              title: const Text('Audio Alerts'),
              subtitle: const Text('Play sounds when targets are reached'),
              value: _enableSounds,
              onChanged: (value) {
                setState(() {
                  _enableSounds = value;
                });
              },
            ),

            const SizedBox(height: 10),
            const Text('Maintenance', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  child: const Text('Reset Max'),
                  onPressed: () {
                    widget.onResetMaxAmplitude();
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Recalibrate'),
                  onPressed: () {
                    widget.onRecalibrate();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {

            FocusScope.of(context).unfocus();


            Future.delayed(const Duration(milliseconds: 50), () {

              int? breathCount = int.tryParse(_breathCountController.text);
              int? holdDuration = int.tryParse(_holdDurationController.text);


              breathCount = breathCount != null && breathCount > 0 ? breathCount : 40;
              holdDuration = holdDuration != null && holdDuration > 0 ? holdDuration : 90;

              widget.onSettingsChanged(TummoSettings(
                targetBreathCount: breathCount,
                targetHoldDuration: holdDuration,
                useAutomaticBreathCounterAndHolder: _useAutomaticBreathCounterAndHolder,
                stopAutomaticBreathHold: _stopAutomaticBreathHold,
                enableSounds: _enableSounds,
                breathThreshold: _tempThreshold,
              ));

              Navigator.of(context).pop();
            });
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}