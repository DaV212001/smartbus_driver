class TripModel {
  final String id;
  final String routeId;
  final String driverId;
  final String busIdentifier;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime scheduledFor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final RouteModel route;
  
  // Additional fields for analytics
  final int passengerCount;
  final bool isPeakLoad;

  TripModel({
    required this.id,
    required this.routeId,
    required this.driverId,
    required this.busIdentifier,
    required this.status,
    this.startedAt,
    this.endedAt,
    required this.scheduledFor,
    required this.createdAt,
    required this.updatedAt,
    required this.route,
    this.passengerCount = 0,
    this.isPeakLoad = false,
  });

  TripModel copyWith({
    String? id,
    String? routeId,
    String? driverId,
    String? busIdentifier,
    String? status,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? scheduledFor,
    DateTime? createdAt,
    DateTime? updatedAt,
    RouteModel? route,
    int? passengerCount,
    bool? isPeakLoad,
  }) {
    return TripModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      driverId: driverId ?? this.driverId,
      busIdentifier: busIdentifier ?? this.busIdentifier,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      route: route ?? this.route,
      passengerCount: passengerCount ?? this.passengerCount,
      isPeakLoad: isPeakLoad ?? this.isPeakLoad,
    );
  }

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'],
      routeId: json['routeId'],
      driverId: json['driverId'],
      busIdentifier: json['busIdentifier'],
      status: json['status'],
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      scheduledFor: DateTime.parse(json['scheduledFor']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      route: RouteModel.fromJson(json['route']),
      passengerCount: json['passengerCount'] ?? 0,
      isPeakLoad: json['isPeakLoad'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeId': routeId,
      'driverId': driverId,
      'busIdentifier': busIdentifier,
      'status': status,
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'scheduledFor': scheduledFor.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'route': route.toJson(),
      'passengerCount': passengerCount,
      'isPeakLoad': isPeakLoad,
    };
  }

  // Dynamic helper to group trips by date, determine peak load, and sort chronologically
  static List<TripModel> getProcessedTrips(List<TripModel> trips) {
    // 1. Group trips by calendar date (YYYY-MM-DD)
    final Map<String, List<TripModel>> tripsByDate = {};
    for (var trip in trips) {
      final date = trip.scheduledFor;
      final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      tripsByDate.putIfAbsent(dateKey, () => []).add(trip);
    }

    // 2. For each day, find the maximum passenger count and set isPeakLoad
    final List<TripModel> processed = [];
    for (var entry in tripsByDate.entries) {
      final dayTrips = entry.value;
      if (dayTrips.isEmpty) continue;

      int maxPassengers = 0;
      for (var t in dayTrips) {
        if (t.passengerCount > maxPassengers) {
          maxPassengers = t.passengerCount;
        }
      }

      for (var t in dayTrips) {
        // A trip is Peak Load if it has the max passenger count on that day (and max > 0)
        final isPeak = maxPassengers > 0 && t.passengerCount == maxPassengers;
        processed.add(t.copyWith(isPeakLoad: isPeak));
      }
    }

    // Sort chronologically (oldest to newest)
    processed.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return processed;
  }

  // Static list of multi-day mock trips
  static List<TripModel> mockTrips = [
    // Today
    TripModel(
      id: 'today-1',
      routeId: 'r1',
      driverId: 'd1',
      busIdentifier: 'BUS-104',
      status: 'COMPLETED',
      scheduledFor: DateTime.now().subtract(const Duration(hours: 2)),
      startedAt: DateTime.now().subtract(const Duration(hours: 2)),
      endedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      route: RouteModel(id: 'r1', routeNumber: '12', name: 'Piazza ↔ Bole'),
      passengerCount: 18,
    ),
    TripModel(
      id: 'today-2',
      routeId: 'r1',
      driverId: 'd1',
      busIdentifier: 'BUS-104',
      status: 'COMPLETED',
      scheduledFor: DateTime.now().subtract(const Duration(hours: 4)),
      startedAt: DateTime.now().subtract(const Duration(hours: 4)),
      endedAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 15)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      route: RouteModel(id: 'r1', routeNumber: '12', name: 'Bole ↔ Piazza'),
      passengerCount: 22,
    ),
    TripModel(
      id: 'today-3',
      routeId: 'r2',
      driverId: 'd1',
      busIdentifier: 'BUS-104',
      status: 'COMPLETED',
      scheduledFor: DateTime.now().subtract(const Duration(hours: 6)),
      startedAt: DateTime.now().subtract(const Duration(hours: 6)),
      endedAt: DateTime.now().subtract(const Duration(hours: 5, minutes: 15)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      route: RouteModel(id: 'r2', routeNumber: '34', name: 'Mexico ↔ Megenagna'),
      passengerCount: 26, // Dynamic Peak Load for today
    ),
    TripModel(
      id: 'today-4',
      routeId: 'r2',
      driverId: 'd1',
      busIdentifier: 'BUS-104',
      status: 'COMPLETED',
      scheduledFor: DateTime.now().subtract(const Duration(hours: 8)),
      startedAt: DateTime.now().subtract(const Duration(hours: 8)),
      endedAt: DateTime.now().subtract(const Duration(hours: 7, minutes: 15)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      route: RouteModel(id: 'r2', routeNumber: '34', name: 'Megenagna ↔ Mexico'),
      passengerCount: 15,
    ),

    // Yesterday
    TripModel(
      id: 'yest-1',
      routeId: 'r1',
      driverId: 'd1',
      busIdentifier: 'BUS-104',
      status: 'COMPLETED',
      scheduledFor: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      startedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      endedAt: DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 10)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      route: RouteModel(id: 'r1', routeNumber: '12', name: 'Piazza ↔ Bole'),
      passengerCount: 12,
    ),
    TripModel(
      id: 'yest-2',
      routeId: 'r1',
      driverId: 'd1',
      busIdentifier: 'BUS-104',
      status: 'COMPLETED',
      scheduledFor: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      startedAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      endedAt: DateTime.now().subtract(const Duration(days: 1, hours: 3, minutes: 15)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      route: RouteModel(id: 'r1', routeNumber: '12', name: 'Bole ↔ Piazza'),
      passengerCount: 30, // Dynamic Peak Load for yesterday
    ),
    TripModel(
      id: 'yest-3',
      routeId: 'r2',
      driverId: 'd1',
      busIdentifier: 'BUS-104',
      status: 'COMPLETED',
      scheduledFor: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      startedAt: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      endedAt: DateTime.now().subtract(const Duration(days: 1, hours: 5, minutes: 15)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      route: RouteModel(id: 'r2', routeNumber: '34', name: 'Mexico ↔ Megenagna'),
      passengerCount: 20,
    ),

    // Day Before Yesterday
    TripModel(
      id: 'dbefore-1',
      routeId: 'r1',
      driverId: 'd1',
      busIdentifier: 'BUS-104',
      status: 'COMPLETED',
      scheduledFor: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      startedAt: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      endedAt: DateTime.now().subtract(const Duration(days: 2, hours: 1, minutes: 10)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      route: RouteModel(id: 'r1', routeNumber: '12', name: 'Piazza ↔ Bole'),
      passengerCount: 25, // Dynamic Peak Load for day before
    ),
    TripModel(
      id: 'dbefore-2',
      routeId: 'r1',
      driverId: 'd1',
      busIdentifier: 'BUS-104',
      status: 'COMPLETED',
      scheduledFor: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      startedAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      endedAt: DateTime.now().subtract(const Duration(days: 2, hours: 3, minutes: 15)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      route: RouteModel(id: 'r1', routeNumber: '12', name: 'Bole ↔ Piazza'),
      passengerCount: 14,
    ),
    TripModel(
      id: 'dbefore-3',
      routeId: 'r2',
      driverId: 'd1',
      busIdentifier: 'BUS-104',
      status: 'COMPLETED',
      scheduledFor: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
      startedAt: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
      endedAt: DateTime.now().subtract(const Duration(days: 2, hours: 5, minutes: 15)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      route: RouteModel(id: 'r2', routeNumber: '34', name: 'Mexico ↔ Megenagna'),
      passengerCount: 18,
    ),
  ];
}

class RouteModel {
  final String id;
  final String routeNumber;
  final String name;

  RouteModel({
    required this.id,
    required this.routeNumber,
    required this.name,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'],
      routeNumber: json['routeNumber'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeNumber': routeNumber,
      'name': name,
    };
  }
}
