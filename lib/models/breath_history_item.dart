class BreathHistoryItem {
  final DateTime timestamp;
  final int breathCount;
  final int holdDuration;

  BreathHistoryItem({
    required this.timestamp,
    required this.breathCount,
    required this.holdDuration,
  });
}