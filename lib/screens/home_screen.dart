import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'analytics_screen.dart';
import 'passenger_list_screen.dart';
import 'scan_screen.dart';
import '../models/trip_model.dart';
import '../services/analytics_storage.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Theme setup based on your CSS custom properties
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Driver Home',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0B66B2),
          onPrimary: Colors.white,
          secondary: Color(0xFFE6F3EC),
          onSecondary: Color(0xFF0B6E4F),
          surface: Colors.white,
          onSurface: Color(0xFF0B1A2B),
          error: Color(0xFFDC2626),
        ),
      ),
      home: const DriverHomeScreen(),
    );
  }
}

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      // Bottom Navigation Bar with Floating Action Effect built in
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0x14000000))),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, LucideIcons.home, 'Home'),
                _buildNavItem(1, LucideIcons.users, 'List'),
                _buildScanFab(),
                _buildNavItem(3, LucideIcons.bell, 'Alerts'),
                _buildNavItem(4, LucideIcons.barChart2, 'Stats'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const PassengerListScreen();
      case 2:
        return const TicketScannerScreen();
      case 4:
        return const AnalyticsScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        // Custom Blue Header
        const _DriverHeader(
          driverName: 'Hello, Abebe',
          busInfo: 'Bus #104 • ET-12345',
          status: 'On Duty',
        ),

        // Main Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(title: 'Current Assignment'),
                const _AssignmentCard(
                  routeNumber: 'Route 42',
                  time: '08:30 AM',
                  fromStop: 'Megenagna',
                  toStop: 'Stadium',
                ),

                const _SectionTitle(title: "Today's Activity"),
                const _StatsGrid(),

                const _SectionTitle(title: 'Recent Alerts'),
                _AlertCard(
                  icon: LucideIcons.mapPin,
                  iconColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: const Color(0xFFEFF6FF),
                  borderColor: const Color(0xFFBFDBFE),
                  title: 'Weraj Request',
                  message: 'Passenger requesting drop-off at Bole Bridge Stop.',
                  titleColor: const Color(0xFF1E40AF),
                  messageColor: const Color(0xFF3B82F6),
                ),
                const _AlertCard(
                  icon: LucideIcons.alertTriangle,
                  iconColor: Color(0xFFD97706),
                  backgroundColor: Color(0xFFFFFBEB),
                  borderColor: Color(0xFFFDE68A),
                  title: 'System Update',
                  message: 'Peak hour traffic reported near Meskel Square.',
                  titleColor: Color(0xFFB45309),
                  messageColor: Color(0xFFD97706),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFF6B7280);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Centered Floating Scan Button
  Widget _buildScanFab() {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = 2),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -36, // Forces the button to pop outward smoothly
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.scanLine,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Scan',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Component UI Blocks ---

class _DriverHeader extends StatelessWidget {
  final String driverName;
  final String busInfo;
  final String status;

  const _DriverHeader({
    required this.driverName,
    required this.busInfo,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driverName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                busInfo,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 12),

      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final String routeNumber;
  final String time;
  final String fromStop;
  final String toStop;

  const _AssignmentCard({
    required this.routeNumber,
    required this.time,
    required this.fromStop,
    required this.toStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                routeNumber,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FROM',
                      style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fromStop,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.arrowRight,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TO',
                      style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      toStop,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(
                LucideIcons.playCircle,
                size: 20,
                color: Colors.white,
              ),
              label: const Text(
                'Start Trip',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatefulWidget {
  const _StatsGrid();

  @override
  State<_StatsGrid> createState() => _StatsGridState();
}

class _StatsGridState extends State<_StatsGrid> {
  int _tripsCompleted = 0;
  int _passengersTransported = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayStats();
  }

  Future<void> _loadTodayStats() async {
    // 1. Process mock trips to compute dynamic peak loads
    final processedTrips = TripModel.getProcessedTrips(TripModel.mockTrips);

    // 2. Filter today's trips
    final now = DateTime.now();
    final todayTrips = processedTrips.where((t) {
      final s = t.scheduledFor;
      return s.year == now.year && s.month == now.month && s.day == now.day;
    }).toList();

    final todayTripsCount = todayTrips.length;
    final todayPassengers = todayTrips.fold<int>(0, (sum, t) => sum + t.passengerCount);

    // 3. Update storage so today's numbers are consistently saved
    await AnalyticsStorage.recordStatsForDate(now, todayPassengers, todayTripsCount);

    if (mounted) {
      setState(() {
        _tripsCompleted = todayTripsCount;
        _passengersTransported = todayPassengers;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B66B2)),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: LucideIcons.bus,
              iconColor: const Color(0xFF2563EB),
              iconBg: const Color(0xFFDBEAFE),
              value: _tripsCompleted.toString(),
              label: 'Trips Completed',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: LucideIcons.users,
              iconColor: const Color(0xFF16A34A),
              iconBg: const Color(0xFFDCFCE7),
              value: _passengersTransported.toString(),
              label: 'Passengers',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B1A2B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final String title;
  final String message;
  final Color titleColor;
  final Color messageColor;

  const _AlertCard({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.title,
    required this.message,
    required this.titleColor,
    required this.messageColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: messageColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
