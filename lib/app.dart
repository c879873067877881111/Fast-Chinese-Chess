// MaterialApp 根 Widget：深色棕色主題、Material 3、首頁為 LobbyScreen
// 啟動時觸發 Firebase 匿名登入
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/lobby_screen.dart';

class DarkChessApp extends ConsumerWidget {
  const DarkChessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 啟動自動匿名登入，錯誤靜默忽略（離線時不影響本機對戰）
    ref.watch(authInitProvider);
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
