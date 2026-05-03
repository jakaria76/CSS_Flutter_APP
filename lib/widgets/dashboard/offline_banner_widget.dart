import 'package:flutter/material.dart';
import 'package:css/pages/SettingsPage/settings_constants.dart';

class OfflineBannerWidget extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onRetry;

  const OfflineBannerWidget({
    super.key,
    required this.controller,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        if (controller.value == 0) return const SizedBox.shrink();
        return SizeTransition(
          sizeFactor: controller,
          axisAlignment: -1,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      SC.tr('noInternet'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onRetry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        SC.tr('retryBtn'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}