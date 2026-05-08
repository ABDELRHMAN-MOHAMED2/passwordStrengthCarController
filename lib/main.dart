import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/car_controller.dart';
import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PasswordStrengthCarApp());
}

class PasswordStrengthCarApp extends StatelessWidget {
  const PasswordStrengthCarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CarController()..initialize(),
      child: MaterialApp(
        title: 'Password Strength Car Controller',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: AppTheme.dark(),
        home: const HomeScreen(),
      ),
    );
  }
}
