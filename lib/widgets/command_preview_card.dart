import 'package:flutter/material.dart';

import '../services/car_controller.dart';
import '../utils/strength_colors.dart';
import 'futuristic_panel.dart';

class CommandPreviewCard extends StatelessWidget {
  const CommandPreviewCard({super.key, required this.controller});

  final CarController controller;

  @override
  Widget build(BuildContext context) {
    final analysis = controller.analysis;
    final color = strengthColor(analysis.level);
    final canSend = controller.bluetooth.isConnected && !controller.isSending;

    return FuturisticPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Command Preview',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _movementForCommand(analysis.command),
                      style: TextStyle(color: Colors.white.withAlpha(190)),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color),
                ),
                child: Text(
                  analysis.command,
                  style: TextStyle(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: canSend ? controller.sendCurrentCommand : null,
            icon: controller.isSending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: const Text('Send to Car'),
          ),
          if (controller.lastSentCommand != null ||
              controller.statusMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (controller.lastSentCommand != null)
                  'Last sent ${controller.lastSentCommand}',
                if (controller.statusMessage != null) controller.statusMessage!,
              ].join('  |  '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String _movementForCommand(String command) {
    return switch (command) {
      '1' => 'Move backward for 1 second',
      '2' => 'Turn left for 1 second',
      '3' => 'Turn right for 1 second',
      '4' => 'Move forward for 3 seconds',
      _ => 'Stop motors',
    };
  }
}
