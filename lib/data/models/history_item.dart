class HistoryItem {
  final String id;
  final String type; // 'SCAN', 'ALERT', 'ROVER', 'SENSOR'
  final DateTime timestamp;
  final String title;
  final String description;
  final String severity; // 'HIGH', 'MEDIUM', 'LOW', 'INFO'
  final Map<String, dynamic> metadata;

  HistoryItem({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.title,
    required this.description,
    required this.severity,
    this.metadata = const {},
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as String,
      type: json['type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'title': title,
      'description': description,
      'severity': severity,
      'metadata': metadata,
    };
  }
}
