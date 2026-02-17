// 大廳畫面：三種遊戲模式選擇（標準/連吃/車直衝），點擊後進入 GameScreen
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/enums.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E1A0E),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final shortSide = min(constraints.maxWidth, constraints.maxHeight);
          final scale = (shortSide / 400).clamp(0.6, 1.8);
          final buttonWidth = (shortSide * 0.65).clamp(200.0, 360.0);

          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '暗棋',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 48 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  Text(
                    'Dark Chess',
                    style: TextStyle(color: Colors.white54, fontSize: 16 * scale),
                  ),
                  SizedBox(height: 48 * scale),
                  _buildModeButton(context, ref, '標準模式', '基本暗棋規則', GameMode.standard, scale, buttonWidth),
                  SizedBox(height: 12 * scale),
                  _buildModeButton(context, ref, '連吃模式', '吃子後可繼續吃', GameMode.chainCapture, scale, buttonWidth),
                  SizedBox(height: 12 * scale),
                  _buildModeButton(context, ref, '車直衝模式', '連吃 + 車可直線衝殺', GameMode.chainCaptureWithRookRush, scale, buttonWidth),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    WidgetRef ref,
    String title,
    String subtitle,
    GameMode mode,
    double scale,
    double buttonWidth,
  ) {
    return SizedBox(
      width: buttonWidth,
      child: ElevatedButton(
        onPressed: () {
          ref.read(gameModeProvider.notifier).setMode(mode);
          ref.invalidate(gameStateProvider);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GameScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5C2E00),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16 * scale),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 18 * scale, fontWeight: FontWeight.bold)),
            Text(subtitle, style: TextStyle(fontSize: 12 * scale, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

@Preview()
Widget previewLobbyScreen() {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B4513),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LobbyScreen(),
    ),
  );
}
