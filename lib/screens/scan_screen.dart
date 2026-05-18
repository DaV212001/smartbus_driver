import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/scan_controller.dart';
import '../controllers/home_controller.dart';
import '../utils/api_call_status.dart';
import '../utils/wrappers/shimmer_wrapper.dart';
import '../widgets/cards/error_card.dart';
import '../utils/error_data.dart';
import '../constants/assets.dart';

class TicketScannerScreen extends StatelessWidget {
  const TicketScannerScreen({super.key});

  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color mutedColor = Color(0xFFF3F4F6);
  static const Color mutedForegroundColor = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScanController());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Header Section
            _buildHeader(context),

            // 2. Camera Viewport Section
            _buildScannerViewport(context, controller),

            // 3. Scan Feedback Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Obx(() {
                  final status = controller.apiCallStatus.value;
                  switch (status) {
                    case ApiCallStatus.holding:
                      return _buildHoldingFeedback(context);
                    case ApiCallStatus.loading:
                      return _buildLoadingFeedback(context);
                    case ApiCallStatus.success:
                      return _buildSuccessFeedback(context, controller);
                    case ApiCallStatus.error:
                      return _buildErrorFeedback(context, controller);
                    default:
                      return _buildHoldingFeedback(context);
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    String busInfo = 'Bus #104 • Route --';
    try {
      final homeController = Get.find<HomeController>();
      final activeTrip = homeController.activeTrip.value;
      if (activeTrip != null) {
        busInfo = 'Bus ${activeTrip.busIdentifier} • Route ${activeTrip.route.routeNumber}';
      }
    } catch (_) {}

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
              const Padding(padding: EdgeInsets.only(top: 2)),
              Text(
                busInfo,
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
              Icons.tune_outlined,
              size: 18,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerViewport(BuildContext context, ScanController controller) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.42,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. MobileScanner Camera View
          Positioned.fill(
            child: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String? code = barcodes.first.rawValue;
                  if (code != null) {
                    controller.processScan(code);
                  }
                }
              },
            ),
          ),
          
          // 2. Translucent dark dim overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),

          // 3. Mode Toggle Switch Pill
          Positioned(
            top: 16,
            child: Obx(() => Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  _buildModeButton(controller, 'Standard'),
                  _buildModeButton(controller, 'Inspection'),
                ],
              ),
            )),
          ),

          // 4. QR Scan Target Frame
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildCorner(context, top: -2, left: -2, isTop: true, isLeft: true),
                _buildCorner(context, top: -2, right: -2, isTop: true, isLeft: false),
                _buildCorner(context, bottom: -2, left: -2, isTop: false, isLeft: true),
                _buildCorner(context, bottom: -2, right: -2, isTop: false, isLeft: false),
              ],
            ),
          ),

          // 5. Connectivity State Pill
          Positioned(
            bottom: 16,
            child: Obx(() {
              final isOffline = controller.isOffline.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isOffline ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOffline ? Icons.cloud_off : Icons.cloud_done,
                      color: Colors.white,
                      size: 14,
                    ),
                    const Padding(padding: EdgeInsets.only(left: 6)),
                    Text(
                      isOffline ? 'Offline Mode' : 'Online Mode',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(ScanController controller, String mode) {
    final bool isActive = controller.activeMode.value == mode;
    return GestureDetector(
      onTap: () => controller.toggleMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          mode,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.black : Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildCorner(
    BuildContext context, {
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
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? BorderSide(color: theme.colorScheme.primary, width: 3)
                : BorderSide.none,
            bottom: !isTop
                ? BorderSide(color: theme.colorScheme.primary, width: 3)
                : BorderSide.none,
            left: isLeft
                ? BorderSide(color: theme.colorScheme.primary, width: 3)
                : BorderSide.none,
            right: !isLeft
                ? BorderSide(color: theme.colorScheme.primary, width: 3)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(16) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(16) : Radius.zero,
            bottomLeft: !isTop && isLeft ? const Radius.circular(16) : Radius.zero,
            bottomRight: !isTop && !isLeft ? const Radius.circular(16) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildHoldingFeedback(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Padding(padding: EdgeInsets.only(top: 20)),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.qr_code_2,
            color: Theme.of(context).colorScheme.primary,
            size: 36,
          ),
        ),
        const Padding(padding: EdgeInsets.only(top: 16)),
        const Text(
          'Ready to Scan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const Padding(padding: EdgeInsets.only(top: 6)),
        const Text(
          'Align a passenger\'s ticket QR code inside the viewport to perform cryptographic validation.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: mutedForegroundColor,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingFeedback(BuildContext context) {
    return ShimmerWrapper(
      isEnabled: true,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const Padding(padding: EdgeInsets.only(left: 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 16, color: Colors.grey),
                    const Padding(padding: EdgeInsets.only(top: 6)),
                    Container(width: 180, height: 12, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.only(top: 16)),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessFeedback(BuildContext context, ScanController controller) {
    final result = controller.lastScanResult.value!;
    final isInspection = result.result == 'INSPECTION_ONLY';
    final ticketId = result.ticketId ?? '----';
    final String passengerName = result.payload?.passengerId != null
        ? 'Passenger #${result.payload!.passengerId.substring(0, 5)}'
        : 'Boarding Passenger';

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: successColor, size: 30),
            ),
            const Padding(padding: EdgeInsets.only(left: 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isInspection ? 'Inspection Verified' : 'Valid Ticket',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(top: 4)),
                  Text(
                    isInspection
                        ? 'Ticket signature is valid but state is kept active.'
                        : 'Ticket validated and boarding approved.',
                    style: const TextStyle(
                      color: mutedForegroundColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Padding(padding: EdgeInsets.only(top: 16)),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: mutedColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MetaItem(label: 'Passenger', value: passengerName),
                  _MetaItem(
                    label: 'Type',
                    value: isInspection ? 'Inspection' : 'Standard',
                  ),
                  _MetaItem(label: 'Scan Time', value: controller.scannedAtString.value),
                ],
              ),
              const Padding(padding: EdgeInsets.only(top: 12)),
              const Divider(color: Color(0x14000000), height: 1),
              const Padding(padding: EdgeInsets.only(top: 12)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TICKET ID',
                        style: TextStyle(fontSize: 10, color: mutedForegroundColor),
                      ),
                      const Padding(padding: EdgeInsets.only(top: 2)),
                      Text(
                        ticketId.length > 18 ? ticketId.substring(0, 18) + '...' : ticketId,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  if (result.payload?.fareAmount != null)
                    Text(
                      '${result.payload!.fareAmount} ETB',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const Padding(padding: EdgeInsets.only(top: 16)),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => controller.reset(),
            icon: const Icon(Icons.qr_code_scanner, size: 20),
            label: const Text(
              'Scan Next Ticket',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorFeedback(BuildContext context, ScanController controller) {
    final error = controller.errorData.value;
    return Column(
      children: [
        ErrorCard(
          errorData: error ??
              ErrorData(
                title: 'Scan Failed',
                body: 'The scanned ticket could not be validated.',
                image: Assets.errorsUnknown,
                buttonText: 'Scan Again',
              ),
          refresh: () => controller.reset(),
        ),
      ],
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
            color: TicketScannerScreen.mutedForegroundColor,
          ),
        ),
        const Padding(padding: EdgeInsets.only(top: 4)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
