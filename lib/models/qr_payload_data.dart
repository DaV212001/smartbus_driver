class QrPayloadData {
  final String ticketId;
  final String passengerId;
  final String routeId;
  final String boardingStopId;
  final String dropoffStopId;
  final double fareAmount;
  final DateTime expiresAt;
  final DateTime issuedAt;

  QrPayloadData({
    required this.ticketId,
    required this.passengerId,
    required this.routeId,
    required this.boardingStopId,
    required this.dropoffStopId,
    required this.fareAmount,
    required this.expiresAt,
    required this.issuedAt,
  });

  factory QrPayloadData.fromJson(Map<String, dynamic> json) {
    return QrPayloadData(
      ticketId: json['ticketId'] as String,
      passengerId: json['passengerId'] as String,
      routeId: json['routeId'] as String,
      boardingStopId: json['boardingStopId'] as String,
      dropoffStopId: json['dropoffStopId'] as String,
      fareAmount: (json['fareAmount'] as num).toDouble(),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      issuedAt: DateTime.parse(json['issuedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'passengerId': passengerId,
      'routeId': routeId,
      'boardingStopId': boardingStopId,
      'dropoffStopId': dropoffStopId,
      'fareAmount': fareAmount,
      'expiresAt': expiresAt.toIso8601String(),
      'issuedAt': issuedAt.toIso8601String(),
    };
  }
}
