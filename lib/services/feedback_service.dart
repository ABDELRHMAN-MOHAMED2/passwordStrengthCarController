import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../models/password_strength.dart';

class FeedbackService {
  Future<void> strengthChanged(PasswordStrengthLevel level) async {
    SystemSound.play(SystemSoundType.click);

    final canVibrate = await Vibration.hasVibrator();
    if (canVibrate != true) return;

    final duration = switch (level) {
      PasswordStrengthLevel.veryWeak => 35,
      PasswordStrengthLevel.weak => 45,
      PasswordStrengthLevel.strong => 60,
      PasswordStrengthLevel.veryStrong => 85,
    };

    await Vibration.vibrate(duration: duration);
  }
}
