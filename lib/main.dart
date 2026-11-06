import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/shortlist_model.dart';
import 'router.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // фабрика, а не экземпляр: Provider создаёт лениво и сам вызывает dispose
        ChangeNotifierProvider(create: (_) => ShortlistModel()),
      ],
      child: const BizMatchApp(), // MaterialApp.router — нетронут с L3
    ),
  );
}

class BizMatchApp extends StatelessWidget {
  const BizMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    // L3: навигацию принимает router; home: исчезает
    return MaterialApp.router(
      title: 'BizMatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Глубокий «деловой» сине-бирюзовый: доверие + энергия знакомств
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F6E8C)),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      routerConfig: router,
    );
  }
}
