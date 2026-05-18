import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DailySummary {
  final int totalPassengers;
  final int totalTrips;

  DailySummary({required this.totalPassengers, required this.totalTrips});

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      totalPassengers: json['totalPassengers'] ?? 0,
      totalTrips: json['totalTrips'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPassengers': totalPassengers,
      'totalTrips': totalTrips,
    };
  }
}

class AnalyticsStorage {
  static const String _storageKey = 'daily_trip_analytics_summaries';

  static String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  static Future<Map<String, DailySummary>> loadDailySummaries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) {
      return {};
    }
    try {
      final Map<String, dynamic> decoded = json.decode(jsonString);
      return decoded.map((key, value) => MapEntry(key, DailySummary.fromJson(value)));
    } catch (e) {
      return {};
    }
  }

  static Future<void> saveDailySummaries(Map<String, DailySummary> summaries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(summaries.map((key, value) => MapEntry(key, value.toJson())));
    await prefs.setString(_storageKey, jsonString);
  }

  static Future<void> recordStatsForDate(DateTime date, int passengers, int trips) async {
    final summaries = await loadDailySummaries();
    final dateKey = _formatDate(date);
    summaries[dateKey] = DailySummary(totalPassengers: passengers, totalTrips: trips);
    await saveDailySummaries(summaries);
  }

  static Future<DailySummary?> getSummaryForDate(DateTime date) async {
    final summaries = await loadDailySummaries();
    final dateKey = _formatDate(date);
    return summaries[dateKey];
  }

  static Future<void> prepopulateFirstRun() async {
    final summaries = await loadDailySummaries();
    if (summaries.isEmpty) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dayBefore = DateTime.now().subtract(const Duration(days: 2));
      
      summaries[_formatDate(yesterday)] = DailySummary(totalPassengers: 62, totalTrips: 3);
      summaries[_formatDate(dayBefore)] = DailySummary(totalPassengers: 57, totalTrips: 3);
      
      await saveDailySummaries(summaries);
    }
  }
}
