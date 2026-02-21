// 標準暗棋規則（無連吃）
// - 移動：正交鄰接一步到空格
// - 吃子：正交鄰接 + 階級規則、砲跳吃（隔一子）、馬斜吃（對角鄰接、無視階級）
// - 盲吃：攻擊未翻開棋子，砲盲吃仍需炮台
import '../../core/enums.dart';
import '../../core/position.dart';
import '../entities/board.dart';
import 'game_rule_set.dart';

class StandardRuleSet extends GameRuleSet {
  @override
  bool get supportsChainCapture => false;

  @override
  bool canMove(Board board, Position from, Position to) {
    if (!to.isValid) return false;
    final piece = board.at(from);
    if (piece == null || !piece.isFaceUp) return false;
    if (board.at(to) != null) return false;
    // 正交鄰接一步
    return from.manhattanTo(to) == 1;
  }

  @override
  bool canCapture(Board board, Position from, Position to) {
    if (!to.isValid) return false;
    final attacker = board.at(from);
    final target = board.at(to);
    if (attacker == null || !attacker.isFaceUp) return false;
    if (target == null || target.isCaptured) return false;
    // 翻開的同色棋不能吃
    if (target.isFaceUp && attacker.color == target.color) return false;

    // 目標蓋著 → 盲吃（不查階級不查顏色）
    if (target.isFaceDown) {
      // 砲盲吃：仍需跳過一子
      if (attacker.rank == PieceRank.cannon) {
        return _canCannonCapture(board, from, to);
      }
      // 馬斜吃蓋棋
      if (attacker.rank == PieceRank.horse && _isDiagonalAdjacent(from, to)) {
        return true;
      }
      // 其餘棋子：正交鄰接一步即可盲吃
      return from.manhattanTo(to) == 1;
    }

    // 以下 target 必為 faceUp

    // 砲跳吃
    if (attacker.rank == PieceRank.cannon) {
      return _canCannonCapture(board, from, to);
    }

    // 馬斜吃（對角鄰接，無視階級）
    if (attacker.rank == PieceRank.horse && _isDiagonalAdjacent(from, to)) {
      return true;
    }

    // 正交鄰接 + 階級規則
    if (from.manhattanTo(to) == 1) {
      return attacker.canCaptureByRank(target);
    }

    return false;
  }

  @override
  List<Position> getAvailableMoves(Board board, Position from) {
    final moves = <Position>[];
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 8; c++) {
        final to = Position(r, c);
        if (canMove(board, from, to) || canCapture(board, from, to)) {
          moves.add(to);
        }
      }
    }
    return moves;
  }

  @override
  List<Position> getCaptureMoves(Board board, Position from) {
    final moves = <Position>[];
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 8; c++) {
        final to = Position(r, c);
        if (canCapture(board, from, to)) {
          moves.add(to);
        }
      }
    }
    return moves;
  }

  @override
  bool hasChainCapture(Board board, Position position) => false;

  /// 砲跳吃：隔一子吃
  bool _canCannonCapture(Board board, Position from, Position to) {
    // 必須同行或同列
    if (from.row != to.row && from.col != to.col) return false;

    int count = 0;
    if (from.row == to.row) {
      final minC = from.col < to.col ? from.col : to.col;
      final maxC = from.col > to.col ? from.col : to.col;
      for (var c = minC + 1; c < maxC; c++) {
        if (board.at(Position(from.row, c)) != null) count++;
      }
    } else {
      final minR = from.row < to.row ? from.row : to.row;
      final maxR = from.row > to.row ? from.row : to.row;
      for (var r = minR + 1; r < maxR; r++) {
        if (board.at(Position(r, from.col)) != null) count++;
      }
    }
    return count == 1; // 恰好一個炮台
  }

  bool _isDiagonalAdjacent(Position a, Position b) {
    return (a.row - b.row).abs() == 1 && (a.col - b.col).abs() == 1;
  }
}
