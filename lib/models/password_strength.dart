enum PasswordStrengthLevel {
  veryWeak(1, 'Very Weak', '1'),
  weak(2, 'Weak', '2'),
  strong(3, 'Strong', '3'),
  veryStrong(4, 'Very Strong', '4');

  const PasswordStrengthLevel(this.level, this.label, this.command);

  final int level;
  final String label;
  final String command;

  static PasswordStrengthLevel fromLevel(int level) {
    return PasswordStrengthLevel.values.firstWhere(
      (value) => value.level == level,
      orElse: () => PasswordStrengthLevel.veryWeak,
    );
  }
}

class PasswordStrengthAnalysis {
  const PasswordStrengthAnalysis({
    required this.passwordLength,
    required this.level,
    required this.score,
    required this.entropy,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSymbol,
    required this.hasRepeatedPattern,
    required this.isCommonPassword,
  });

  final int passwordLength;
  final PasswordStrengthLevel level;
  final int score;
  final double entropy;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSymbol;
  final bool hasRepeatedPattern;
  final bool isCommonPassword;

  double get normalizedScore => score.clamp(0, 100) / 100;
  String get command => level.command;
}
