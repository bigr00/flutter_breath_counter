import 'package:flutter/material.dart';
import '../models/breath_history_item.dart';

class BreathHistoryDialog extends StatelessWidget {
  final List<BreathHistoryItem> historyItems;

  const BreathHistoryDialog({
    Key? key,
    required this.historyItems,
  }) : super(key: key);

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Breath Session History'),
      content: SizedBox(
        width: double.maxFinite,
        child: historyItems.isEmpty
            ? const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'No history recorded yet.\nComplete a session to see your results.',
              textAlign: TextAlign.center,
            ),
          ),
        )
            : ListView.builder(
          shrinkWrap: true,
          itemCount: historyItems.length,
          itemBuilder: (context, index) {
            // Reverse the list to show newest entries at the top
            final item = historyItems[historyItems.length - 1 - index];
            return ListTile(
              title: Text('Session at ${_formatTime(item.timestamp)}'),
              subtitle: Text(
                'Breaths: ${item.breathCount} | Hold: ${_formatDuration(item.holdDuration)}',
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text('${index + 1}'),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}