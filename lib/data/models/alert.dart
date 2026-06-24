class Alert {
  final String id;
  final String title;
  final String message;
  final String type; // WARNING, ERROR, INFO
  final DateTime timestamp;
  final bool isRead;

  Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  Alert copyWith({bool? isRead}) {
    return Alert(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
