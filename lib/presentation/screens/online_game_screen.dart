// 線上對戰畫面：狀態列、對手/我方棋子清單、棋盤、結束連吃 / 投降按鈕、結局橫幅
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums.dart';
import '../../core/position.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/piece.dart';
import '../providers/online_game_provider.dart';
import '../widgets/chess_piece.dart';

class OnlineGameScreen extends ConsumerWidget {
  const OnlineGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineState = ref.watch(onlineGameProvider);
    final notifier = ref.read(onlineGameProvider.notifier);
    final state = onlineState.gameState;

    final opponentColor = onlineState.myColor == PieceColor.red
        ? PieceColor.black
        : PieceColor.red;

    return PopScope(
      // 遊戲結束後可直接返回；進行中攔截並詢問投降
      canPop: onlineState.gameOver,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showResignDialog(context, ref, onlineState);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2E1A0E),
        appBar: AppBar(
          title: Text(onlineState.room?.mode.displayName ?? '線上對局'),
          backgroundColor: const Color(0xFF5C2E00),
          foregroundColor: Colors.white,
          actions: [
            if (!onlineState.gameOver)
              IconButton(
                icon: const Icon(Icons.flag_outlined),
                tooltip: '投降',
                onPressed: () => _showResignDialog(context, ref, onlineState),
              ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final shortSide = min(constraints.maxWidth, constraints.maxHeight);
            final scale = (shortSide / 480).clamp(0.6, 1.5);

            return Column(
              children: [
                SizedBox(height: 8 * scale),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                  child: _buildStatusBar(onlineState, scale),
                ),
                SizedBox(height: 6 * scale),
                _buildPieceInventory(state.board, opponentColor, scale),
                SizedBox(height: 4 * scale),
                Expanded(
                  child: Center(
                    child: const _OnlineChessBoardWidget(),
                  ),
                ),
                SizedBox(height: 4 * scale),
                _buildPieceInventory(state.board, onlineState.myColor, scale),
                SizedBox(height: 8 * scale),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                  child: _buildActionButton(onlineState, notifier, scale),
                ),
                if (onlineState.gameOver)
                  _buildGameOverBanner(context, onlineState, scale),
                SizedBox(height: 8 * scale),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── 狀態列 ──────────────────────────────────────────────────────────────────

  Widget _buildStatusBar(OnlineGameState s, double scale) {
    final String label;
    final Color bg;

    if (s.gameOver) {
      label = '遊戲結束';
      bg = const Color(0xFF3E2414);
    } else if (s.gameState.currentTurn == null) {
      label = '請翻棋開始';
      bg = const Color(0xFF3E2414);
    } else if (s.gameState.turnState == TurnState.chainCapture) {
      label = s.isMyTurn ? '連吃中 — 繼續或結束' : '對手連吃中...';
      bg = const Color(0xFF4E342E);
    } else if (s.isMyTurn) {
      label = '你的回合';
      bg = const Color(0xFF1B4332);
    } else {
      label = '等待對手...';
      bg = const Color(0xFF3E2414);
    }

    final myColorLabel = s.myColor == PieceColor.red ? '你是紅方' : '你是黑方';
    final myColorVal =
        s.myColor == PieceColor.red ? const Color(0xFFCC0000) : Colors.white60;

    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            myColorLabel,
            style: TextStyle(
              color: myColorVal,
              fontSize: 13 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── 操作按鈕（結束連吃 / 投降佔位） ─────────────────────────────────────────

  Widget _buildActionButton(
    OnlineGameState s,
    OnlineGameStateNotifier notifier,
    double scale,
  ) {
    final isChaining =
        s.gameState.turnState == TurnState.chainCapture && s.isMyTurn;

    return SizedBox(
      width: double.infinity,
      height: 52 * scale,
      child: ElevatedButton(
        onPressed: isChaining ? () => notifier.endChain() : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isChaining ? const Color(0xFFD84315) : const Color(0xFF3E2414),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF3E2414),
          disabledForegroundColor: Colors.white24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * scale),
            side: BorderSide(
              color: isChaining
                  ? const Color(0xFFFF6E40)
                  : const Color(0xFF5C2E00),
              width: 2,
            ),
          ),
          elevation: isChaining ? 8 : 2,
        ),
        child: Text(
          isChaining ? '停止連吃' : (s.isMyTurn ? '選棋或翻棋' : '等待對手'),
          style: TextStyle(
            fontSize: (isChaining ? 20 : 15) * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ── 棋子清單 ─────────────────────────────────────────────────────────────────

  Widget _buildPieceInventory(Board board, PieceColor color, double scale) {
    final captured = board.capturedCounts(color);
    final faceDown = board.faceDownCount(color);
    final isRed = color == PieceColor.red;
    const ranks = [
      PieceRank.general, PieceRank.advisor, PieceRank.elephant,
      PieceRank.chariot, PieceRank.horse, PieceRank.cannon, PieceRank.soldier,
    ];
    final names = isRed ? Piece.redNames : Piece.blackNames;
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
      padding: EdgeInsets.symmetric(horizontal: 12 * scale),
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFF3E2414),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Text(
              isRed ? '紅' : '黑',
              style: TextStyle(
                color: isRed
                    ? const Color(0xFFFF6659)
                    : Colors.white70,
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
                          ? (isRed
                              ? const Color(0xFFFF8A80)
                              : Colors.white60)
                          : Colors.white24,
                      fontSize: fs,
                      fontWeight: FontWeight.bold,
                      decoration:
                          p.alive ? null : TextDecoration.lineThrough,
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

  // ── 遊戲結束橫幅 ──────────────────────────────────────────────────────────────

  Widget _buildGameOverBanner(
    BuildContext context,
    OnlineGameState s,
    double scale,
  ) {
    final String resultText;
    final Color resultColor;

    if (s.winner == null) {
      resultText = '平局';
      resultColor = Colors.white70;
    } else if (s.winner == s.myColor) {
      resultText = '你贏了！';
      resultColor = Colors.amber;
    } else {
      resultText = '對手獲勝';
      resultColor = Colors.redAccent;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF4E342E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            resultText,
            style: TextStyle(
              color: resultColor,
              fontSize: 26 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 14 * scale),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C2E00),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 32 * scale,
                vertical: 12 * scale,
              ),
            ),
            child: Text('回到大廳', style: TextStyle(fontSize: 16 * scale)),
          ),
        ],
      ),
    );
  }

  // ── 投降確認 ──────────────────────────────────────────────────────────────────

  void _showResignDialog(
    BuildContext context,
    WidgetRef ref,
    OnlineGameState s,
  ) {
    if (s.gameOver) return;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF3E2414),
        title: const Text('確定投降？',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('投降後對手獲勝，無法悔棋。',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD84315),
              foregroundColor: Colors.white,
            ),
            child: const Text('投降'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        ref.read(onlineGameProvider.notifier).resign();
      }
    });
  }
}

// ── 線上棋盤 Widget ─────────────────────────────────────────────────────────────

class _OnlineChessBoardWidget extends ConsumerWidget {
  const _OnlineChessBoardWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineState = ref.watch(onlineGameProvider);
    final state = onlineState.gameState;
    final notifier = ref.read(onlineGameProvider.notifier);

    // 非我方回合不顯示合法移動
    final showLegal = onlineState.isMyTurn;

    final legalMoves = showLegal
        ? (state.selectedPosition != null
            ? notifier.getLegalMoves(state.selectedPosition!)
            : (state.chainPiece != null
                ? notifier.getLegalMoves(state.chainPiece!)
                : <Position>[]))
        : <Position>[];

    return AspectRatio(
      aspectRatio: 8 / 4,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = constraints.maxWidth / 8;

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
            ),
            itemCount: 32,
            itemBuilder: (context, index) {
              final row = index ~/ 8;
              final col = index % 8;
              final pos = Position(row, col);
              final piece = state.board.at(pos);

              final isSelected =
                  state.selectedPosition == pos || state.chainPiece == pos;
              final isLegal = legalMoves.contains(pos);

              return GestureDetector(
                onTap: () => notifier.tap(pos),
                child: Container(
                  decoration: BoxDecoration(
                    color: _cellColor(row, col, isLegal && piece == null),
                    border: Border.all(
                        color: const Color(0xFF5C2E00), width: 0.5),
                  ),
                  padding: EdgeInsets.all(cellSize * 0.04),
                  child: piece != null
                      ? ChessPieceWidget(
                          piece: piece,
                          cellSize: cellSize,
                          isSelected: isSelected,
                          isLegalTarget: isLegal,
                          isBlindReveal: false,
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _cellColor(int row, int col, bool isLegalEmpty) {
    if (isLegalEmpty) return const Color(0xFFA5D6A7);
    return (row + col) % 2 == 0
        ? const Color(0xFFDEB887)
        : const Color(0xFFC4A265);
  }
}
