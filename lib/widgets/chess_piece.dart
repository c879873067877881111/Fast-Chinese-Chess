// 單顆棋子 Widget：四種視覺狀態
// - 蓋棋（faceDown）：棕色底 + "?"
// - 翻開（faceUp）：奶油底 + 紅/黑中文名稱
// - 選中（isSelected）：黃色高亮邊框
// - 盲吃展示（isBlindReveal）：橙色發光邊框
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../core/enums.dart';
import '../core/position.dart';
import '../models/piece.dart';

class ChessPieceWidget extends StatelessWidget {
  final Piece piece;
  final double cellSize;
  final bool isSelected;
  final bool isLegalTarget;
  final bool isBlindReveal;

  const ChessPieceWidget({
    super.key,
    required this.piece,
    required this.cellSize,
    this.isSelected = false,
    this.isLegalTarget = false,
    this.isBlindReveal = false,
  });

  double get _fontSize => (cellSize * 0.48).clamp(12, 40);
  double get _borderWidth => (cellSize * 0.04).clamp(1.5, 4);
  double get _radius => (cellSize * 0.1).clamp(3, 8);

  @override
  Widget build(BuildContext context) {
    if (piece.isFaceDown) return _buildFaceDown();
    return _buildFaceUp();
  }

  Widget _buildFaceDown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF8B4513),
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: const Color(0xFF5C2E00), width: _borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '?',
          style: TextStyle(
            color: Colors.white70,
            fontSize: _fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFaceUp() {
    final color = piece.color == PieceColor.red
        ? const Color(0xFFCC0000)
        : const Color(0xFF1A1A1A);

    final bgColor = isBlindReveal
        ? const Color(0xFFFFE0B2)
        : isSelected
            ? const Color(0xFFFFE082)
            : isLegalTarget
                ? const Color(0xFFA5D6A7)
                : const Color(0xFFFFF8E1);

    final borderColor = isBlindReveal
        ? const Color(0xFFFF6D00)
        : isSelected
            ? const Color(0xFFFFA000)
            : const Color(0xFF795548);

    final bw = (isBlindReveal || isSelected) ? _borderWidth * 1.3 : _borderWidth;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: borderColor, width: bw),
        boxShadow: [
          if (isBlindReveal)
            BoxShadow(
              color: const Color(0xFFFF6D00).withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 2,
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
        ],
      ),
      child: Center(
        child: Text(
          piece.displayName,
          style: TextStyle(
            color: color,
            fontSize: _fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

@Preview()
Widget previewFaceDown() {
  return Container(
    color: const Color(0xFFDEB887),
    padding: const EdgeInsets.all(8),
    child: SizedBox(
      width: 60,
      height: 60,
      child: ChessPieceWidget(
        piece: const Piece(
          rank: PieceRank.general,
          color: PieceColor.red,
          state: PieceState.faceDown,
          position: Position(0, 0),
        ),
        cellSize: 60,
      ),
    ),
  );
}

@Preview()
Widget previewRedGeneral() {
  return Container(
    color: const Color(0xFFDEB887),
    padding: const EdgeInsets.all(8),
    child: SizedBox(
      width: 60,
      height: 60,
      child: ChessPieceWidget(
        piece: const Piece(
          rank: PieceRank.general,
          color: PieceColor.red,
          state: PieceState.faceUp,
          position: Position(0, 0),
        ),
        cellSize: 60,
      ),
    ),
  );
}

@Preview()
Widget previewBlackGeneral() {
  return Container(
    color: const Color(0xFFDEB887),
    padding: const EdgeInsets.all(8),
    child: SizedBox(
      width: 60,
      height: 60,
      child: ChessPieceWidget(
        piece: const Piece(
          rank: PieceRank.general,
          color: PieceColor.black,
          state: PieceState.faceUp,
          position: Position(0, 0),
        ),
        cellSize: 60,
      ),
    ),
  );
}

@Preview()
Widget previewSelectedPiece() {
  return Container(
    color: const Color(0xFFDEB887),
    padding: const EdgeInsets.all(8),
    child: SizedBox(
      width: 60,
      height: 60,
      child: ChessPieceWidget(
        piece: const Piece(
          rank: PieceRank.chariot,
          color: PieceColor.red,
          state: PieceState.faceUp,
          position: Position(0, 0),
        ),
        cellSize: 60,
        isSelected: true,
      ),
    ),
  );
}

@Preview()
Widget previewBlindReveal() {
  return Container(
    color: const Color(0xFFDEB887),
    padding: const EdgeInsets.all(8),
    child: SizedBox(
      width: 60,
      height: 60,
      child: ChessPieceWidget(
        piece: const Piece(
          rank: PieceRank.cannon,
          color: PieceColor.black,
          state: PieceState.faceUp,
          position: Position(0, 0),
        ),
        cellSize: 60,
        isBlindReveal: true,
      ),
    ),
  );
}
