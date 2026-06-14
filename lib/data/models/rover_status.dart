class RoverStatus {
  final double battery;
  final bool isConnected;
  final String motorStatus;
  final bool cameraActive;
  final double speed; // 0.0 to 100.0
  final bool isAutoMode;
  final double latitude;
  final double longitude;
  final double heading;
  final List<List<double>> path;

  RoverStatus({
    required this.battery,
    required this.isConnected,
    required this.motorStatus,
    required this.cameraActive,
    required this.speed,
    required this.isAutoMode,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.path,
  });

  RoverStatus copyWith({
    double? battery,
    bool? isConnected,
    String? motorStatus,
    bool? cameraActive,
    double? speed,
    bool? isAutoMode,
    double? latitude,
    double? longitude,
    double? heading,
    List<List<double>>? path,
  }) {
    return RoverStatus(
      battery: battery ?? this.battery,
      isConnected: isConnected ?? this.isConnected,
      motorStatus: motorStatus ?? this.motorStatus,
      cameraActive: cameraActive ?? this.cameraActive,
      speed: speed ?? this.speed,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      path: path ?? this.path,
    );
  }

  factory RoverStatus.initial() => RoverStatus(
    battery: 100.0,
    isConnected: false,
    motorStatus: 'IDLE',
    cameraActive: true,
    speed: 50.0,
    isAutoMode: false,
    latitude: 12.9716,
    longitude: 77.5946,
    heading: 0.0,
    path: const [[12.9716, 77.5946]],
  );
}
