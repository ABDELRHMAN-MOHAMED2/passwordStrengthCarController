import 'password_strength.dart';

class PasswordHistoryEntry {
  const PasswordHistoryEntry({
    required this.createdAt,
    required this.length,
    required this.strength,
    required this.entropy,
    required this.command,
  });

  final DateTime createdAt;
  final int length;
  final PasswordStrengthLevel strength;
  final double entropy;
  final String command;

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'length': length,
      'strength': strength.level,
      'entropy': entropy,
      'command': command,
    };
  }

  factory PasswordHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PasswordHistoryEntry(
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      length: json['length'] as int? ?? 0,
      strength: PasswordStrengthLevel.fromLevel(json['strength'] as int? ?? 1),
      entropy: (json['entropy'] as num?)?.toDouble() ?? 0,
      command: json['command'] as String? ?? '1',
    );
  }
}
