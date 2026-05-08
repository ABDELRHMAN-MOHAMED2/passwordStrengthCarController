import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/car_controller.dart';
import '../widgets/bluetooth_panel.dart';
import '../widgets/command_preview_card.dart';
import '../widgets/futuristic_panel.dart';
import '../widgets/history_stats_panel.dart';
import '../widgets/password_input_card.dart';
import '../widgets/strength_meter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CarController>(
      builder: (context, controller, _) {
        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF070A12),
                  Color(0xFF111827),
                  Color(0xFF07141A),
                ],
              ),
            ),
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                      child: _Header(controller: controller),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              PasswordInputCard(controller: controller),
                              const SizedBox(height: 14),
                              StrengthMeter(analysis: controller.analysis),
                              const SizedBox(height: 14),
                              CommandPreviewCard(controller: controller),
                              const SizedBox(height: 14),
                              BluetoothPanel(controller: controller),
                              const SizedBox(height: 14),
                              HistoryStatsPanel(controller: controller),
                            ],
                          ),
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

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final CarController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bluetooth = controller.bluetooth;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.primary),
              ),
              child: const Icon(Icons.directions_car_filled),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Password Strength Car Controller',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FuturisticStatusDot(active: bluetooth.isConnected),
          ],
        ),
      ),
    );
  }
}
