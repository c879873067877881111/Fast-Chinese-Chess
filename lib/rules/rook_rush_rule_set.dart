import '../core/enums.dart';
import '../core/position.dart';
import '../models/board.dart';
import 'chain_rule_set.dart';

class RookRushRuleSet extends ChainRuleSet {
  @override
  bool canCapture(Board board, Position from, Position to) {
    // 先檢查基本規則
    if (super.canCapture(board, from, to)) return true;

    // 車直衝
    final attacker = board.at(from);
    final target = board.at(to);
    if (attacker == null || !attacker.isFaceUp) return false;
    if (target == null || target.isCaptured) return false;
    if (target.isFaceUp && attacker.color == target.color) return false;
    if (attacker.rank != PieceRank.chariot) return false;

    return _canRookRush(board, from, to);
  }

  /// 車直衝：同行或同列，路徑淨空，至少隔一格，無視階級
  bool _canRookRush(Board board, Position from, Position to) {
    if (from.row != to.row && from.col != to.col) return false;

    final distance = from.manhattanTo(to);
    if (distance <= 1) return false; // 至少隔一格

    // 路徑必須淨空
    if (from.row == to.row) {
      final minC = from.col < to.col ? from.col : to.col;
      final maxC = from.col > to.col ? from.col : to.col;
      for (var c = minC + 1; c < maxC; c++) {
        if (board.at(Position(from.row, c)) != null) return false;
      }
    } else {
      final minR = from.row < to.row ? from.row : to.row;
      final maxR = from.row > to.row ? from.row : to.row;
      for (var r = minR + 1; r < maxR; r++) {
        if (board.at(Position(r, from.col)) != null) return false;
      }
    }
    return true;
  }
}
