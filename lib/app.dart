// MaterialApp 根 Widget：深色棕色主題、Material 3、首頁為 LobbyScreen
import 'package:flutter/material.dart';
import 'screens/lobby_screen.dart';

class DarkChessApp extends StatelessWidget {
  const DarkChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '暗棋',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B4513),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LobbyScreen(),
    );
  }
}
