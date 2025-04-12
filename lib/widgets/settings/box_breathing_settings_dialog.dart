import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/techniques/box_technique_widget.dart';

class BoxBreathingSettingsDialog extends StatefulWidget {
  final BoxBreathingSettings settings;
  final Function(BoxBreathingSettings) onSettingsChanged;

  const BoxBreathingSettingsDialog({
    Key? key,
    required this.settings,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  _BoxBreathingSettingsDialogState createState() => _BoxBreathingSettingsDialogState();
}

class _BoxBreathingSettingsDialogState extends State<BoxBreathingSettingsDialog> {
  late TextEditingController _inhaleDurationController;
  late TextEditingController _holdAfterInhaleController;
  late TextEditingController _exhaleDurationController;
  late TextEditingController _holdAfterExhaleController;
  late TextEditingController _cycleCountController;
  late bool _enableSounds;

  @override
  void initState() {
    super.initState();
    _inhaleDurationController = TextEditingController(text: widget.settings.inhaleDuration.toString());
    _holdAfterInhaleController = TextEditingController(text: widget.settings.holdAfterInhaleDuration.toString());
    _exhaleDurationController = TextEditingController(text: widget.settings.exhaleDuration.toString());
    _holdAfterExhaleController = TextEditingController(text: widget.settings.holdAfterExhaleDuration.toString());
    _cycleCountController = TextEditingController(text: widget.settings.cycleCount.toString());
    _enableSounds = widget.settings.enableSounds;
  }

  @override
  void dispose() {
    _inhaleDurationController.dispose();
    _holdAfterInhaleController.dispose();
    _exhaleDurationController.dispose();
    _holdAfterExhaleController.dispose();
    _cycleCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Box Breathing Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Timing Settings (seconds)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Inhale duration
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: TextFormField(
                controller: _inhaleDurationController,
                decoration: const InputDecoration(
                  labelText: 'Inhale Duration',
                  hintText: 'E.g., 4 seconds',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),

            // Hold after inhale duration
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: TextFormField(
                controller: _holdAfterInhaleController,
                decoration: const InputDecoration(
                  labelText: 'Hold After Inhale',
                  hintText: 'E.g., 4 seconds',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),

            // Exhale duration
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: TextFormField(
                controller: _exhaleDurationController,
                decoration: const InputDecoration(
                  labelText: 'Exhale Duration',
                  hintText: 'E.g., 4 seconds',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),

            // Hold after exhale duration
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: TextFormField(
                controller: _holdAfterExhaleController,
                decoration: const InputDecoration(
                  labelText: 'Hold After Exhale',
                  hintText: 'E.g., 4 seconds',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),

            // Total cycles
            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: TextFormField(
                controller: _cycleCountController,
                decoration: const InputDecoration(
                  labelText: 'Total Cycles',
                  hintText: 'E.g., 5 cycles',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),

            // Option settings
            SwitchListTile(
              title: const Text('Audio Guidance'),
              subtitle: const Text('Play sounds to guide your breathing pattern'),
              value: _enableSounds,
              onChanged: (value) {
                setState(() {
                  _enableSounds = value;
                });
              },
            ),

            // Equal Box timing button
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.balance),
              label: const Text('Set Equal Box Timing'),
              onPressed: () {
                // Prompt user for a single value to use for all timings
                showDialog(
                  context: context,
                  builder: (context) => _buildEqualTimingDialog(),
                );
              },
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
            // Unfocus all text fields before saving
            FocusScope.of(context).unfocus();

            // Small delay to allow unfocus to complete
            Future.delayed(const Duration(milliseconds: 50), () {
              // Parse and validate all values
              int inhale = int.tryParse(_inhaleDurationController.text) ?? 4;
              int holdAfterInhale = int.tryParse(_holdAfterInhaleController.text) ?? 4;
              int exhale = int.tryParse(_exhaleDurationController.text) ?? 4;
              int holdAfterExhale = int.tryParse(_holdAfterExhaleController.text) ?? 4;
              int cycles = int.tryParse(_cycleCountController.text) ?? 5;

              // Ensure values are at least 1
              inhale = inhale > 0 ? inhale : 1;
              holdAfterInhale = holdAfterInhale > 0 ? holdAfterInhale : 1;
              exhale = exhale > 0 ? exhale : 1;
              holdAfterExhale = holdAfterExhale > 0 ? holdAfterExhale : 1;
              cycles = cycles > 0 ? cycles : 1;

              widget.onSettingsChanged(BoxBreathingSettings(
                inhaleDuration: inhale,
                holdAfterInhaleDuration: holdAfterInhale,
                exhaleDuration: exhale,
                holdAfterExhaleDuration: holdAfterExhale,
                cycleCount: cycles,
                enableSounds: _enableSounds,
              ));

              Navigator.of(context).pop();
            });
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildEqualTimingDialog() {
    TextEditingController equalTimeController = TextEditingController(text: "4");

    return AlertDialog(
      title: const Text('Equal Box Timing'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Set all four phases to the same duration:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: equalTimeController,
            decoration: const InputDecoration(
              labelText: 'Duration (seconds)',
              hintText: 'E.g., 4 seconds',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
            int equalTime = int.tryParse(equalTimeController.text) ?? 4;
            equalTime = equalTime > 0 ? equalTime : 4;

            // Set all controllers to the same value
            setState(() {
              _inhaleDurationController.text = equalTime.toString();
              _holdAfterInhaleController.text = equalTime.toString();
              _exhaleDurationController.text = equalTime.toString();
              _holdAfterExhaleController.text = equalTime.toString();
            });

            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}