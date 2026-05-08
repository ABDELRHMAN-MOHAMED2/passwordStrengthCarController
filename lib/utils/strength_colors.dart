import 'package:flutter/material.dart';

import '../models/password_strength.dart';

Color strengthColor(PasswordStrengthLevel level) {
  return switch (level) {
    PasswordStrengthLevel.veryWeak => const Color(0xFFFF3B4F),
    PasswordStrengthLevel.weak => const Color(0xFFFF9D2E),
    PasswordStrengthLevel.strong => const Color(0xFFFFD83D),
    PasswordStrengthLevel.veryStrong => const Color(0xFF32E875),
  };
}
