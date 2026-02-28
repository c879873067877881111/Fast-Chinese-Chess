// 大廳畫面：本機/線上遊戲模式選擇
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';
import 'online_lobby_screen.dart';

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

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                  Text(
                    '本機對戰',
                    style: TextStyle(color: Colors.white38, fontSize: 12 * scale),
                  ),
                  SizedBox(height: 8 * scale),
                  _buildModeButton(context, ref, '標準模式', '基本暗棋規則', GameMode.standard, scale, buttonWidth),
                  SizedBox(height: 12 * scale),
                  _buildModeButton(context, ref, '連吃模式', '吃子後可繼續吃', GameMode.chainCapture, scale, buttonWidth),
                  SizedBox(height: 12 * scale),
                  _buildModeButton(context, ref, '車直衝模式', '連吃 + 車可直線衝殺', GameMode.chainCaptureWithRookRush, scale, buttonWidth),
                  SizedBox(height: 32 * scale),
                  Text(
                    '線上對戰',
                    style: TextStyle(color: Colors.white38, fontSize: 12 * scale),
                  ),
                  SizedBox(height: 8 * scale),
                  _buildOnlineButton(context, '標準模式（線上）', GameMode.standard, scale, buttonWidth),
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
  }

  Widget _buildOnlineButton(
    BuildContext context,
    String title,
    GameMode mode,
    double scale,
    double buttonWidth,
  ) {
    return SizedBox(
      width: buttonWidth,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OnlineLobbyScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A3A5C),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16 * scale),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public, size: 18 * scale),
            SizedBox(width: 8 * scale),
            Text(title, style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.bold)),
          ],
        ),
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
