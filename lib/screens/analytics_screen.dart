import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/trip_model.dart';
import '../services/analytics_storage.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {

  List<TripModel> _recentTrips = [];
  int _todayTripsCount = 0;
  int _todayPassengersCount = 0;
  
  int _yesterdayTripsCount = 0;
  int _yesterdayPassengersCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndProcessAnalytics();
  }

  Future<void> _loadAndProcessAnalytics() async {
    // 1. Prepopulate storage with yesterday's mock data if empty
    await AnalyticsStorage.prepopulateFirstRun();

    // 2. Load all mock trips and process dynamic peak loads
    final processedTrips = TripModel.getProcessedTrips(TripModel.mockTrips);

    // 3. Calculate today's totals
    final now = DateTime.now();
    final todayTrips = processedTrips.where((t) {
      final s = t.scheduledFor;
      return s.year == now.year && s.month == now.month && s.day == now.day;
    }).toList();

    final todayTripsCount = todayTrips.length;
    final todayPassengers = todayTrips.fold<int>(0, (sum, t) => sum + t.passengerCount);

    // 4. Save today's dynamic stats to local storage
    await AnalyticsStorage.recordStatsForDate(now, todayPassengers, todayTripsCount);

    // 5. Load yesterday's stats to compute trends
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdaySummary = await AnalyticsStorage.getSummaryForDate(yesterday);

    if (mounted) {
      setState(() {
        // Reverse recent trips list for the trip log list (newest first)
        _recentTrips = processedTrips.reversed.toList();
        _todayTripsCount = todayTripsCount;
        _todayPassengersCount = todayPassengers;
        _yesterdayTripsCount = yesterdaySummary?.totalTrips ?? 0;
        _yesterdayPassengersCount = yesterdaySummary?.totalPassengers ?? 0;
        _isLoading = false;
      });
    }
  }

  String _formatHeaderDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FB),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B66B2)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(),
                    const SizedBox(height: 16),
                    _buildVolumePanel(),
                    const SizedBox(height: 16),
                    _buildTripLogPanel(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Driver dashboard',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6C7680),
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Today's Stats",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0B1220),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0x14000000)),
            ),
            child: Text(
              _formatHeaderDate(DateTime.now()),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0B1220),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final tripsDiff = _todayTripsCount - _yesterdayTripsCount;
    final tripsTrend = tripsDiff > 0
        ? '+$tripsDiff vs yesterday'
        : tripsDiff < 0
            ? '$tripsDiff vs yesterday'
            : 'Same as yesterday';
    final tripsTrendColor = tripsDiff >= 0 ? const Color(0xFF12A75E) : const Color(0xFFDC2626);

    final passDiff = _todayPassengersCount - _yesterdayPassengersCount;
    final passTrend = passDiff > 0
        ? '+$passDiff vs yesterday'
        : passDiff < 0
            ? '$passDiff vs yesterday'
            : 'Same as yesterday';
    final passTrendColor = passDiff >= 0 ? const Color(0xFF12A75E) : const Color(0xFFDC2626);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: LucideIcons.bus,
            label: 'Trips completed today',
            value: _todayTripsCount.toString(),
            trend: tripsTrend,
            trendColor: tripsTrendColor,
            iconColor: const Color(0xFF0B66B2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: LucideIcons.users,
            label: 'Passengers transported',
            value: _todayPassengersCount.toString(),
            trend: passTrend,
            trendColor: passTrendColor,
            iconColor: const Color(0xFF0B66B2),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String trend,
    required Color trendColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: trendColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6C7680),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0B1220),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumePanel() {
    // Show chart for chronologically sorted recent trips (up to last 7)
    // We reverse _recentTrips (which was reversed for UI listing) to restore chronological order
    final chronologicalTrips = _recentTrips.reversed.toList();
    final chartTrips = chronologicalTrips.length > 7
        ? chronologicalTrips.sublist(chronologicalTrips.length - 7)
        : chronologicalTrips;

    int maxPass = 0;
    for (var t in chartTrips) {
      if (t.passengerCount > maxPass) {
        maxPass = t.passengerCount;
      }
    }
    final double computedMaxY = maxPass > 25 ? (maxPass + 5).toDouble() : 30.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Passenger volume',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B1220),
                ),
              ),
              Text(
                'Last ${chartTrips.length} trips',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6C7680),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: chartTrips.isEmpty
                ? const Center(
                    child: Text(
                      'No trip data available',
                      style: TextStyle(color: Color(0xFF6C7680)),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: computedMaxY,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= chartTrips.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Trip ${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6C7680),
                                  ),
                                ),
                              );
                            },
                            reservedSize: 28,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value % 10 != 0) return const SizedBox.shrink();
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6C7680),
                                ),
                              );
                            },
                            reservedSize: 28,
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return const FlLine(
                            color: Color(0xFFE9EEF2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(chartTrips.length, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: chartTrips[index].passengerCount.toDouble(),
                              color: chartTrips[index].isPeakLoad
                                  ? const Color(0xFFFFB400)
                                  : const Color(0xFF0B66B2),
                              width: 26,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLegendItem(const Color(0xFF0B66B2), 'Regular load'),
              const SizedBox(width: 12),
              _buildLegendItem(const Color(0xFFFFB400), 'Peak load'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6C7680),
          ),
        ),
      ],
    );
  }

  Widget _buildTripLogPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trip log',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B1220),
                ),
              ),
              Text(
                'Showing last ${_recentTrips.length} runs',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6C7680),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _recentTrips.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      'No completed trips recorded',
                      style: TextStyle(color: Color(0xFF6C7680)),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentTrips.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildTripLogCard(_recentTrips[index]);
                  },
                ),
        ],
      ),
    );
  }

  String _formatTripTime(TripModel trip) {
    if (trip.startedAt == null || trip.endedAt == null) {
      return 'Scheduled: ${_formatTimeOnly(trip.scheduledFor)}';
    }
    return '${_formatTimeOnly(trip.startedAt!)} to ${_formatTimeOnly(trip.endedAt!)}';
  }

  String _formatTimeOnly(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$min $ampm';
  }

  Widget _buildTripLogCard(TripModel trip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route ${trip.route.routeNumber} · ${trip.route.name}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B1220),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTripTime(trip),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6C7680),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6F2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B1220),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('Passengers', trip.passengerCount.toString()),
              _buildMetric(
                'Load Type',
                trip.isPeakLoad ? 'Peak Load' : 'Regular',
                valueColor: trip.isPeakLoad ? const Color(0xFFFFB400) : const Color(0xFF0B66B2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6C7680),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF0B1220),
          ),
        ),
      ],
    );
  }
}
