import 'dart:math';

import '../models/password_strength.dart';

class PasswordStrengthService {
  static final RegExp _uppercase = RegExp(r'[A-Z]');
  static final RegExp _lowercase = RegExp(r'[a-z]');
  static final RegExp _number = RegExp(r'\d');
  static final RegExp _symbol = RegExp(r'[^A-Za-z0-9]');
  static final RegExp _repeatedChars = RegExp(r'(.)\1{2,}');

  static const Set<String> _commonWeakPasswords = {
    '123456',
    '12345678',
    '123456789',
    'password',
    'password1',
    'qwerty',
    'abc123',
    '111111',
    'iloveyou',
    'admin',
    'welcome',
    'letmein',
  };

  PasswordStrengthAnalysis analyze(String password) {
    final hasUppercase = _uppercase.hasMatch(password);
    final hasLowercase = _lowercase.hasMatch(password);
    final hasNumber = _number.hasMatch(password);
    final hasSymbol = _symbol.hasMatch(password);
    final hasRepeatedPattern = _hasRepeatedPattern(password);
    final isCommonPassword = _commonWeakPasswords.contains(
      password.trim().toLowerCase(),
    );
    final entropy = _calculateEntropy(password);

    var score = 0;
    score += min(password.length * 6, 36);
    if (hasLowercase) score += 10;
    if (hasUppercase) score += 14;
    if (hasNumber) score += 14;
    if (hasSymbol) score += 18;
    if (password.length >= 10) score += 8;
    if (entropy >= 55) score += 8;
    if (hasRepeatedPattern) score -= 22;
    if (isCommonPassword) score -= 40;
    score = score.clamp(0, 100);

    final level = _classify(
      password: password,
      score: score,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasNumber: hasNumber,
      hasSymbol: hasSymbol,
      hasRepeatedPattern: hasRepeatedPattern,
      isCommonPassword: isCommonPassword,
    );

    return PasswordStrengthAnalysis(
      passwordLength: password.length,
      level: level,
      score: score,
      entropy: entropy,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasNumber: hasNumber,
      hasSymbol: hasSymbol,
      hasRepeatedPattern: hasRepeatedPattern,
      isCommonPassword: isCommonPassword,
    );
  }

  PasswordStrengthLevel _classify({
    required String password,
    required int score,
    required bool hasUppercase,
    required bool hasLowercase,
    required bool hasNumber,
    required bool hasSymbol,
    required bool hasRepeatedPattern,
    required bool isCommonPassword,
  }) {
    if (password.isEmpty || password.length < 6 || isCommonPassword) {
      return PasswordStrengthLevel.veryWeak;
    }

    final hasLettersAndNumbers = (hasUppercase || hasLowercase) && hasNumber;
    final hasMixedCaseNumbers = hasUppercase && hasLowercase && hasNumber;
    final hasFullComplexity = hasMixedCaseNumbers && hasSymbol;

    if (password.length >= 10 &&
        hasFullComplexity &&
        !hasRepeatedPattern &&
        score >= 78) {
      return PasswordStrengthLevel.veryStrong;
    }

    if (password.length >= 8 && hasMixedCaseNumbers && score >= 58) {
      return PasswordStrengthLevel.strong;
    }

    if (password.length >= 6 && password.length <= 8 && hasLettersAndNumbers) {
      return PasswordStrengthLevel.weak;
    }

    if (score >= 42 && hasLettersAndNumbers) {
      return PasswordStrengthLevel.weak;
    }

    return PasswordStrengthLevel.veryWeak;
  }

  bool _hasRepeatedPattern(String password) {
    if (_repeatedChars.hasMatch(password)) return true;

    final lower = password.toLowerCase();
    for (var size = 2; size <= lower.length ~/ 2; size++) {
      for (var start = 0; start + size * 2 <= lower.length; start++) {
        final chunk = lower.substring(start, start + size);
        final next = lower.substring(start + size, start + size * 2);
        if (chunk == next) return true;
      }
    }
    return false;
  }

  double _calculateEntropy(String password) {
    if (password.isEmpty) return 0;

    var poolSize = 0;
    if (_lowercase.hasMatch(password)) poolSize += 26;
    if (_uppercase.hasMatch(password)) poolSize += 26;
    if (_number.hasMatch(password)) poolSize += 10;
    if (_symbol.hasMatch(password)) poolSize += 33;

    if (poolSize == 0) return 0;
    return password.length * (log(poolSize) / ln2);
  }
}
