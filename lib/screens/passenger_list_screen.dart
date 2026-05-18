import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF0B2545);
  static const border = Color(0x14000000);
  static const primary = Color(0xFF0A7DC5);
  static const primaryForeground = Color(0xFFFFFFFF);
  static const secondary = Color(0xFFF0F6FF);
  static const mutedForeground = Color(0xFF65707A);

  static const success = Color(0xFF22C55E);
  static const successBg = Color(0x1A22C55E);

  static const warning = Color(0xFFFF8A00);
  static const warningBg = Color(0x1AFF8A00);

  static const destructive = Color(0xFFE02424);
  static const destructiveBg = Color(0x1AE02424);
}

class PassengerListScreen extends StatefulWidget {
  const PassengerListScreen({super.key});

  @override
  State<PassengerListScreen> createState() => _PassengerListScreenState();
}

class _PassengerListScreenState extends State<PassengerListScreen> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.of(context).padding.top + 60),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 20,
            right: 20,
            bottom: 12,
          ),
          color: AppColors.primary,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Passenger List',
                    style: TextStyle(
                      color: AppColors.primaryForeground,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bus #104 • Route 42',
                    style: TextStyle(
                      color: AppColors.primaryForeground.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryForeground.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.filter_list,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const StatsBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const SectionTitle(title: 'Just Now'),
                const PassengerItem(
                  name: 'Hana Kebede',
                  time: '10:42 AM',
                  status: PassengerStatus.valid,
                  avatarUrl: 'https://app.banani.co/avatar1.jpeg',
                ),
                const PassengerItem(
                  name: 'Abebe Bikila',
                  time: '10:41 AM',
                  status: PassengerStatus.usedBefore,
                  avatarUrl: 'https://app.banani.co/avatar2.jpg',
                ),
                const PassengerItem(
                  name: 'Sara Tadesse',
                  time: '10:40 AM',
                  status: PassengerStatus.valid,
                  avatarUrl: 'https://app.banani.co/avatar4.jpg',
                ),
                const SectionTitle(title: 'Earlier Today'),
                const PassengerItem(
                  name: 'Dawit Tesfaye',
                  time: '10:35 AM',
                  status: PassengerStatus.expired,
                  initials: 'DT',
                ),
                const PassengerItem(
                  name: 'Meron Haile',
                  time: '10:32 AM',
                  status: PassengerStatus.valid,
                  avatarUrl: 'https://app.banani.co/avatar5.jpg',
                ),
                const PassengerItem(
                  name: 'Yonas Alemu',
                  time: '10:30 AM',
                  status: PassengerStatus.valid,
                  avatarUrl: 'https://app.banani.co/avatar6.jpg',
                ),
                const PassengerItem(
                  name: 'Bethel Mulugeta',
                  time: '10:28 AM',
                  status: PassengerStatus.valid,
                  initials: 'BM',
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: SizedBox(
          width: 56,
          height: 56,
          child: FloatingActionButton(
            elevation: 4,
            shape: const CircleBorder(
              side: BorderSide(color: Colors.white, width: 4),
            ),
            backgroundColor: AppColors.primary,
            onPressed: () {},
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomAppBar(
          color: Colors.white,
          elevation: 0,
          height: 64,
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, 'Home'),
              _buildNavItem(1, Icons.people, 'List'),
              const SizedBox(width: 48),
              _buildNavItem(2, Icons.notifications_none, 'Alerts'),
              _buildNavItem(3, Icons.bar_chart, 'Stats'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    final color = isActive ? AppColors.primary : AppColors.mutedForeground;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
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
}

enum PassengerStatus { valid, usedBefore, expired }

class StatsBar extends StatelessWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem('Total', '48', AppColors.mutedForeground),
          _buildStatItem('Valid', '45', AppColors.success),
          _buildStatItem('Issues', '3', AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.foreground,
          ),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedForeground,
        ),
      ),
    );
  }
}

class PassengerItem extends StatelessWidget {
  final String name;
  final String time;
  final PassengerStatus status;
  final String? avatarUrl;
  final String? initials;

  const PassengerItem({
    super.key,
    required this.name,
    required this.time,
    required this.status,
    this.avatarUrl,
    this.initials,
  });

  @override
  Widget build(BuildContext context) {
    BoxDecoration itemDecoration = const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
    );

    if (status == PassengerStatus.usedBefore) {
      itemDecoration = const BoxDecoration(
        color: Color(0xFFFFFBEB),
        border: Border(
          left: BorderSide(color: AppColors.warning, width: 4),
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      );
    } else if (status == PassengerStatus.expired) {
      itemDecoration = const BoxDecoration(
        color: Color(0xFFFEF2F2),
        border: Border(
          left: BorderSide(color: AppColors.destructive, width: 4),
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: (status == PassengerStatus.valid) ? 20 : 16,
        right: 20,
        top: 12,
        bottom: 12,
      ),
      decoration: itemDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              avatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        avatarUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildInitialsAvatar(
                              initials ?? name.substring(0, 2),
                            ),
                      ),
                    )
                  : _buildInitialsAvatar(initials ?? name.substring(0, 2)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(String text) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFE2E8F0),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color labelColor;
    Color bgColor;
    IconData icon;
    String text;

    switch (status) {
      case PassengerStatus.valid:
        labelColor = AppColors.success;
        bgColor = AppColors.successBg;
        icon = Icons.check_circle_outline;
        text = 'Valid';
        break;
      case PassengerStatus.usedBefore:
        labelColor = const Color(0xFFB45309);
        bgColor = const Color(0x26F59E0B);
        icon = Icons.warning_amber_rounded;
        text = 'Used Before';
        break;
      case PassengerStatus.expired:
        labelColor = AppColors.destructive;
        bgColor = AppColors.destructiveBg;
        icon = Icons.cancel_outlined;
        text = 'Expired';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: labelColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
