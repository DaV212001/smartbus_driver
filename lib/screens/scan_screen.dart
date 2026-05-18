import 'dart:ui';

import 'package:flutter/material.dart';

class TicketScannerScreen extends StatefulWidget {
  const TicketScannerScreen({super.key});

  @override
  State<TicketScannerScreen> createState() => _TicketScannerScreenState();
}

class _TicketScannerScreenState extends State<TicketScannerScreen> {
  String _activeMode = 'Standard';
  int _currentIndex = 2; // Default active index set to 'Scan'

  // Application Custom Theme Constants
  static const Color successColor = Color(0xFF10B981);
  static const Color mutedColor = Color(0xFFF3F4F6);
  static const Color mutedForegroundColor = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // 1. Header Section
                _buildHeader(context),

                // Main Scrollable Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      bottom: 90.0,
                    ), // Padding to avoid clipping behind navigation bar
                    child: Column(
                      children: [
                        // 2. Camera Viewport Section
                        _buildScannerViewport(context),

                        // 3. Last Scan Feedback Section
                        _buildScanFeedback(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ticket Scanner',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Bus #104 • Route 42',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tune_outlined, // Fallback for lucide:settings-2
              size: 18,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerViewport(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Simulated Camera Feed Image with Grayscale & Blur filter
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ]),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Image.network(
                  'https://app.banani.co/avatar1.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.grey[900]),
                ),
              ),
            ),
          ),
          // Dark Dim Overlay layer over background
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),

          // Segmentation Switch Pill
          Positioned(
            top: 20,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  _buildModeButton('Standard'),
                  _buildModeButton('Inspection'),
                ],
              ),
            ),
          ),

          // QR Scan Frame Target Overlay
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildCorner(top: -2, left: -2, isTop: true, isLeft: true),
                _buildCorner(top: -2, right: -2, isTop: true, isLeft: false),
                _buildCorner(bottom: -2, left: -2, isTop: false, isLeft: true),
                _buildCorner(
                  bottom: -2,
                  right: -2,
                  isTop: false,
                  isLeft: false,
                ),
              ],
            ),
          ),

          // Instruction Overlay Text Guideline
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Align QR code within frame',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String title) {
    final bool isActive = _activeMode == title;
    return GestureDetector(
      onTap: () => setState(() => _activeMode = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.black : Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
  }) {
    final theme = Theme.of(context);
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? BorderSide(color: theme.colorScheme.primary, width: 4)
                : BorderSide.none,
            bottom: !isTop
                ? BorderSide(color: theme.colorScheme.primary, width: 4)
                : BorderSide.none,
            left: isLeft
                ? BorderSide(color: theme.colorScheme.primary, width: 4)
                : BorderSide.none,
            right: !isLeft
                ? BorderSide(color: theme.colorScheme.primary, width: 4)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(20) : Radius.zero,
            topRight: isTop && !isLeft
                ? const Radius.circular(20)
                : Radius.zero,
            bottomLeft: !isTop && isLeft
                ? const Radius.circular(20)
                : Radius.zero,
            bottomRight: !isTop && !isLeft
                ? const Radius.circular(20)
                : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildScanFeedback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: successColor, size: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valid Ticket',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ticket consumed successfully.',
                      style: TextStyle(
                        color: mutedForegroundColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: mutedColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MetaItem(label: 'Passenger', value: 'Hana Kebede'),
                _MetaItem(label: 'Type', value: 'Standard'),
                _MetaItem(label: 'Scan Time', value: '08:42 AM'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: const Border(top: BorderSide(color: Color(0x14000000))),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, 'Home'),
              _buildNavItem(1, Icons.people_outline, 'List'),
              const SizedBox(
                width: 56,
              ), // Placeholder spatial gap structural support for the FAB
              _buildNavItem(3, Icons.notifications_none, 'Alerts'),
              _buildNavItem(4, Icons.bar_chart_outlined, 'Stats'),
            ],
          ),
          Positioned(
            top: -24,
            left: MediaQuery.of(context).size.width / 2 - 28,
            child: GestureDetector(
              onTap: () => setState(() => _currentIndex = 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.qr_code_scanner,
                      color: theme.colorScheme.onPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scan',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _currentIndex == 2
                          ? theme.colorScheme.primary
                          : mutedForegroundColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : mutedForegroundColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : mutedForegroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _TicketScannerScreenState.mutedForegroundColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
