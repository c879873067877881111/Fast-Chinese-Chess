// 遊戲主畫面：回合狀態列、紅黑棋子清單（被吃灰掉+未翻開計數）、
// 棋盤、停止連吃按鈕、遊戲結束橫幅
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/piece.dart';
import '../providers/game_provider.dart';
import '../widgets/chess_board.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF2E1A0E),
      appBar: AppBar(
        title: const Text('暗棋'),
        backgroundColor: const Color(0xFF5C2E00),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.restart(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final shortSide = min(constraints.maxWidth, constraints.maxHeight);
          final scale = (shortSide / 480).clamp(0.6, 1.5);

          return Center(
            child: Column(
              children: [
                SizedBox(height: 8 * scale),
                _buildStatusBar(state, scale),
                SizedBox(height: 6 * scale),
                _buildPieceInventory(state.board, PieceColor.black, scale),
                SizedBox(height: 4 * scale),
                Expanded(
                  child: Center(child: const ChessBoardWidget()),
                ),
                SizedBox(height: 4 * scale),
                _buildPieceInventory(state.board, PieceColor.red, scale),
                SizedBox(height: 8 * scale),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                  child: _buildClockButton(state, notifier, scale),
                ),
                if (state.gameOver)
                  _buildGameOverBanner(state, notifier, scale),
                Padding(
                  padding: EdgeInsets.all(8 * scale),
                  child: Text(
                    state.mode.displayName,
                    style: TextStyle(color: Colors.white54, fontSize: 12 * scale),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBar(GameState state, double scale) {
    String turnText;
    Color bgColor = const Color(0xFF3E2414);

    if (state.gameOver) {
      turnText = '遊戲結束';
    } else if (state.turnState == TurnState.blindReveal) {
      turnText = _blindRevealMessage(state);
      bgColor = const Color(0xFF4E342E);
    } else if (state.currentTurn == null) {
      turnText = '請翻棋開始';
    } else if (state.turnState == TurnState.chainCapture) {
      turnText = '${_colorName(state.currentTurn)} 連吃中...';
    } else {
      turnText = '${_colorName(state.currentTurn)} 的回合';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        turnText,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18 * scale,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _blindRevealMessage(GameState state) {
    if (state.blindTarget == null || state.selectedPosition == null) return '判定中...';
    final attacker = state.board.at(state.selectedPosition!);
    final revealed = state.board.at(state.blindTarget!);
    if (attacker == null || revealed == null) return '判定中...';

    final revealedName = revealed.displayName;

    if (attacker.color == revealed.color) {
      return '翻開 $revealedName — 是自己人！';
    }

    return '翻開 $revealedName — 判定中...';
  }

  Widget _buildClockButton(GameState state, GameStateNotifier notifier, double scale) {
    final isChaining = state.turnState == TurnState.chainCapture;

    return SizedBox(
      width: double.infinity,
      height: 56 * scale,
      child: ElevatedButton(
        onPressed: isChaining ? () => notifier.endChain() : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isChaining
              ? const Color(0xFFD84315)
              : const Color(0xFF3E2414),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF3E2414),
          disabledForegroundColor: Colors.white38,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * scale),
            side: BorderSide(
              color: isChaining
                  ? const Color(0xFFFF6E40)
                  : const Color(0xFF5C2E00),
              width: 3,
            ),
          ),
          elevation: isChaining ? 8 : 2,
        ),
        child: Text(
          isChaining ? '停止連吃' : _turnLabel(state),
          style: TextStyle(
            fontSize: (isChaining ? 22 : 16) * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _turnLabel(GameState state) {
    if (state.gameOver) return '遊戲結束';
    if (state.currentTurn == null) return '請翻棋';
    return '${_colorName(state.currentTurn)} 回合';
  }

  Widget _buildGameOverBanner(GameState state, GameStateNotifier notifier, double scale) {
    return Container(
      margin: EdgeInsets.all(16 * scale),
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF4E342E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${_colorName(state.winner)} 獲勝！',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 24 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12 * scale),
          ElevatedButton(
            onPressed: () => notifier.restart(),
            child: Text('再來一局', style: TextStyle(fontSize: 16 * scale)),
          ),
        ],
      ),
    );
  }

  /// 棋子清單：顯示某方所有棋種，被吃的灰掉
  Widget _buildPieceInventory(Board board, PieceColor color, double scale) {
    final captured = board.capturedCounts(color);
    final faceDown = board.faceDownCount(color);
    final isRed = color == PieceColor.red;

    // 按階級排列所有棋子
    const ranks = [
      PieceRank.general,
      PieceRank.advisor,
      PieceRank.elephant,
      PieceRank.chariot,
      PieceRank.horse,
      PieceRank.cannon,
      PieceRank.soldier,
    ];

    final names = isRed ? Piece.redNames : Piece.blackNames;

    // 展開成逐個棋子的列表
    final pieces = <({String name, bool alive})>[];
    for (final rank in ranks) {
      final total = Board.initialCounts[rank]!;
      final dead = captured[rank] ?? 0;
      for (var i = 0; i < total; i++) {
        pieces.add((name: names[rank]!, alive: i < total - dead));
      }
    }

    final fs = (12 * scale).clamp(10.0, 18.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF3E2414),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Text(
              isRed ? '紅' : '黑',
              style: TextStyle(
                color: isRed ? const Color(0xFFFF6659) : Colors.white70,
                fontSize: fs,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (faceDown > 0) ...[
              SizedBox(width: 4 * scale),
              Text(
                '?×$faceDown',
                style: TextStyle(color: Colors.white38, fontSize: fs),
              ),
            ],
            SizedBox(width: 6 * scale),
            Expanded(
              child: Wrap(
                spacing: 3 * scale,
                children: pieces.map((p) {
                  return Text(
                    p.name,
                    style: TextStyle(
                      color: p.alive
                          ? (isRed ? const Color(0xFFFF8A80) : Colors.white60)
                          : Colors.white24,
                      fontSize: fs,
                      fontWeight: FontWeight.bold,
                      decoration: p.alive ? null : TextDecoration.lineThrough,
                      decorationColor: Colors.white24,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _colorName(PieceColor? color) {
    if (color == null) return '';
    return color == PieceColor.red ? '紅方' : '黑方';
  }

}

@Preview()
Widget previewGameScreen() {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B4513),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    ),
  );
}
