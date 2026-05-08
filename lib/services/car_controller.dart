import 'package:flutter/foundation.dart';

import '../models/password_history_entry.dart';
import '../models/password_strength.dart';
import 'bluetooth_car_service.dart';
import 'feedback_service.dart';
import 'local_storage_service.dart';
import 'password_strength_service.dart';

class CarController extends ChangeNotifier {
  CarController()
    : _storage = LocalStorageService(),
      _passwordStrengthService = PasswordStrengthService(),
      _feedback = FeedbackService() {
    bluetooth = BluetoothCarService(_storage);
    bluetooth.addListener(notifyListeners);
    analysis = _passwordStrengthService.analyze('');
  }

  late final BluetoothCarService bluetooth;
  final LocalStorageService _storage;
  final PasswordStrengthService _passwordStrengthService;
  final FeedbackService _feedback;

  late PasswordStrengthAnalysis analysis;
  String password = '';
  bool obscurePassword = true;
  String? lastSentCommand;
  String? statusMessage;
  bool isSending = false;
  List<PasswordHistoryEntry> history = [];

  Future<void> initialize() async {
    history = await _storage.loadHistory();
    notifyListeners();
    await bluetooth.initialize();
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<void> updatePassword(String value) async {
    password = value;
    final previousLevel = analysis.level;
    analysis = _passwordStrengthService.analyze(value);
    notifyListeners();

    if (value.isNotEmpty && previousLevel != analysis.level) {
      await _feedback.strengthChanged(analysis.level);
    }
  }

  Future<void> scanDevices() => bluetooth.startScan();

  Future<void> sendCurrentCommand() async {
    if (password.isEmpty) {
      statusMessage = 'Enter a password first';
      notifyListeners();
      return;
    }

    isSending = true;
    statusMessage = null;
    notifyListeners();

    try {
      await bluetooth.sendCommand(analysis.command);
      lastSentCommand = analysis.command;
      statusMessage = 'Command ${analysis.command} sent';

      history = [
        PasswordHistoryEntry(
          createdAt: DateTime.now(),
          length: password.length,
          strength: analysis.level,
          entropy: analysis.entropy,
          command: analysis.command,
        ),
        ...history,
      ].take(25).toList();
      await _storage.saveHistory(history);
    } catch (error) {
      statusMessage = error.toString();
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Map<PasswordStrengthLevel, int> get strengthStats {
    final stats = {for (final level in PasswordStrengthLevel.values) level: 0};
    for (final entry in history) {
      stats[entry.strength] = (stats[entry.strength] ?? 0) + 1;
    }
    return stats;
  }

  @override
  void dispose() {
    bluetooth.removeListener(notifyListeners);
    bluetooth.dispose();
    super.dispose();
  }
}
