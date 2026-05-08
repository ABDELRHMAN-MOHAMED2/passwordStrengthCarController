import 'package:flutter/material.dart';

import '../services/car_controller.dart';
import 'futuristic_panel.dart';

class PasswordInputCard extends StatelessWidget {
  const PasswordInputCard({super.key, required this.controller});

  final CarController controller;

  @override
  Widget build(BuildContext context) {
    return FuturisticPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Input',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            obscureText: controller.obscurePassword,
            onChanged: controller.updatePassword,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.key_rounded),
              suffixIcon: IconButton(
                tooltip: controller.obscurePassword
                    ? 'Show password'
                    : 'Hide password',
                onPressed: controller.togglePasswordVisibility,
                icon: Icon(
                  controller.obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
