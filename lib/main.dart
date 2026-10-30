import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

void main() => runApp(const BizMatchApp());

class BizMatchApp extends StatelessWidget {
  const BizMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BizMatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Глубокий «деловой» сине-бирюзовый: доверие + энергия знакомств
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F6E8C)),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
