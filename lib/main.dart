import 'package:flutter/material.dart';

import 'home_page.dart';

void main() {
  runApp(const AntiScammerDemoApp());
}

class AntiScammerDemoApp extends StatelessWidget {
  const AntiScammerDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anti-Scammer AI Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B1F3B)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
