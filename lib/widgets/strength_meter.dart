import 'package:flutter/material.dart';

import '../models/password_strength.dart';
import '../utils/strength_colors.dart';
import 'futuristic_panel.dart';

class StrengthMeter extends StatelessWidget {
  const StrengthMeter({super.key, required this.analysis});

  final PasswordStrengthAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final color = strengthColor(analysis.level);
    final theme = Theme.of(context);

    return FuturisticPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  analysis.level.label,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'Level ${analysis.level.level}',
                style: theme.textTheme.labelLarge?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: analysis.normalizedScore),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 12,
                  color: color,
                  backgroundColor: Colors.white.withAlpha(22),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(label: 'Score', value: '${analysis.score}/100'),
              _MetricChip(
                label: 'Entropy',
                value: '${analysis.entropy.toStringAsFixed(1)} bits',
              ),
              _SignalChip(label: 'A-Z', active: analysis.hasUppercase),
              _SignalChip(label: 'a-z', active: analysis.hasLowercase),
              _SignalChip(label: '0-9', active: analysis.hasNumber),
              _SignalChip(label: '#@!', active: analysis.hasSymbol),
              _SignalChip(
                label: 'Repeat',
                active: analysis.hasRepeatedPattern,
                warning: true,
              ),
              _SignalChip(
                label: 'Common',
                active: analysis.isCommonPassword,
                warning: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label $value'),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: Colors.white.withAlpha(28)),
      backgroundColor: Colors.white.withAlpha(18),
    );
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({
    required this.label,
    required this.active,
    this.warning = false,
  });

  final String label;
  final bool active;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning
        ? (active ? Colors.redAccent : Colors.white54)
        : (active ? const Color(0xFF32E875) : Colors.white54);

    return Chip(
      avatar: Icon(
        active ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
        size: 16,
        color: color,
      ),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withAlpha(90)),
      backgroundColor: color.withAlpha(18),
    );
  }
}
