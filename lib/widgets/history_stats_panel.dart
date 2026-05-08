import 'package:flutter/material.dart';

import '../models/password_strength.dart';
import '../services/car_controller.dart';
import '../utils/strength_colors.dart';
import 'futuristic_panel.dart';

class HistoryStatsPanel extends StatelessWidget {
  const HistoryStatsPanel({super.key, required this.controller});

  final CarController controller;

  @override
  Widget build(BuildContext context) {
    final stats = controller.strengthStats;
    final total = controller.history.length;

    return FuturisticPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Password History',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: PasswordStrengthLevel.values.map((level) {
              final color = strengthColor(level);
              final count = stats[level] ?? 0;
              final fraction = total == 0 ? 0.0 : count / total;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 58,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 320),
                            width: double.infinity,
                            height: 8 + (50 * fraction),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$count',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (controller.history.isEmpty)
            Text(
              'No commands sent yet',
              style: TextStyle(color: Colors.white.withAlpha(150)),
            )
          else
            ...controller.history
                .take(5)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: strengthColor(entry.strength),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${entry.strength.label} | ${entry.entropy.toStringAsFixed(1)} bits',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('Command ${entry.command}'),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
