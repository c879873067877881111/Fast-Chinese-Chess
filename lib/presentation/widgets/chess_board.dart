// 8×4 棋盤 Widget：GridView 渲染、合法移動綠色高亮、盲吃目標橙色高亮、
// 點擊回調轉發至 GameStateNotifier.tap()
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums.dart';
import '../../core/position.dart';
import '../providers/game_provider.dart';
import 'chess_piece.dart';

class ChessBoardWidget extends ConsumerWidget {
  const ChessBoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    final isBlindReveal = state.turnState == TurnState.blindReveal;

    final legalMoves = isBlindReveal
        ? <Position>[]
        : state.selectedPosition != null
            ? notifier.getLegalMoves(state.selectedPosition!)
            : (state.chainPiece != null
                ? notifier.getLegalMoves(state.chainPiece!)
                : <Position>[]);

    return AspectRatio(
      aspectRatio: 8 / 4,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 每格的實際尺寸
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

              final isSelected = state.selectedPosition == pos ||
                  state.chainPiece == pos;
              final isBlindTarget = isBlindReveal && state.blindTarget == pos;
              final isBlindAttacker = isBlindReveal && state.selectedPosition == pos;
              final isLegal = legalMoves.contains(pos);

              return GestureDetector(
                onTap: () => notifier.tap(pos),
                child: Container(
                  decoration: BoxDecoration(
                    color: _cellColor(row, col, isLegal && piece == null, isBlindTarget),
                    border: Border.all(color: const Color(0xFF5C2E00), width: 0.5),
                  ),
                  padding: EdgeInsets.all(cellSize * 0.04),
                  child: piece != null
                      ? ChessPieceWidget(
                          piece: piece,
                          cellSize: cellSize,
                          isSelected: isSelected || isBlindAttacker,
                          isLegalTarget: isLegal,
                          isBlindReveal: isBlindTarget,
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

  Color _cellColor(int row, int col, bool isLegalEmpty, bool isBlindTarget) {
    if (isBlindTarget) return const Color(0xFFFFCC80);
    if (isLegalEmpty) return const Color(0xFFA5D6A7);
    return (row + col) % 2 == 0
        ? const Color(0xFFDEB887)
        : const Color(0xFFC4A265);
  }
}

@Preview()
Widget previewChessBoard() {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF2E1A0E),
        body: Center(
          child: SizedBox(
            width: 480,
            child: const ChessBoardWidget(),
          ),
        ),
      ),
    ),
  );
}
