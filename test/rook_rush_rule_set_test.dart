import 'package:flutter_test/flutter_test.dart';
import 'package:dark_chess/core/enums.dart';
import 'package:dark_chess/core/position.dart';
import 'package:dark_chess/domain/entities/board.dart';
import 'package:dark_chess/domain/entities/piece.dart';
import 'package:dark_chess/domain/rules/rook_rush_rule_set.dart';

Board _emptyBoard() {
  return Board(List.generate(4, (_) => List<Piece?>.filled(8, null)));
}

extension _BoardTestHelper on Board {
  Board _set(Position pos, Piece? piece) {
    final newGrid = List.generate(4, (r) => List<Piece?>.from(grid[r]));
    newGrid[pos.row][pos.col] = piece;
    return Board(newGrid);
  }
}

Piece _piece(PieceRank rank, PieceColor color, Position pos,
    {PieceState state = PieceState.faceUp}) {
  return Piece(rank: rank, color: color, state: state, position: pos);
}

void main() {
  final rules = RookRushRuleSet();

  // ── 馬移動 ─────────────────────────────────────────────────────────────────

  group('馬移動（車直衝模式：斜走）', () {
    test('馬可斜走到空格', () {
      final board = _emptyBoard()
          ._set(const Position(1, 3),
              _piece(PieceRank.horse, PieceColor.red, const Position(1, 3)));
      expect(rules.canMove(board, const Position(1, 3), const Position(2, 4)), isTrue);
      expect(rules.canMove(board, const Position(1, 3), const Position(0, 2)), isTrue);
    });

    test('馬不能正交走', () {
      final board = _emptyBoard()
          ._set(const Position(1, 3),
              _piece(PieceRank.horse, PieceColor.red, const Position(1, 3)));
      expect(rules.canMove(board, const Position(1, 3), const Position(1, 4)), isFalse);
      expect(rules.canMove(board, const Position(1, 3), const Position(0, 3)), isFalse);
    });

    test('馬不能走到有棋子的格子', () {
      final board = _emptyBoard()
          ._set(const Position(1, 3),
              _piece(PieceRank.horse, PieceColor.red, const Position(1, 3)))
          ._set(const Position(2, 4),
              _piece(PieceRank.soldier, PieceColor.red, const Position(2, 4)));
      expect(rules.canMove(board, const Position(1, 3), const Position(2, 4)), isFalse);
    });
  });

  // ── 馬吃子 ─────────────────────────────────────────────────────────────────

  group('馬吃子（車直衝模式：斜吃、無視階級）', () {
    test('馬斜吃敵方（無視階級）', () {
      final board = _emptyBoard()
          ._set(const Position(1, 3),
              _piece(PieceRank.horse, PieceColor.red, const Position(1, 3)))
          ._set(const Position(2, 4),
              _piece(PieceRank.general, PieceColor.black, const Position(2, 4)));
      expect(rules.canCapture(board, const Position(1, 3), const Position(2, 4)), isTrue);
    });

    test('馬斜吃同級', () {
      final board = _emptyBoard()
          ._set(const Position(1, 3),
              _piece(PieceRank.horse, PieceColor.red, const Position(1, 3)))
          ._set(const Position(2, 4),
              _piece(PieceRank.horse, PieceColor.black, const Position(2, 4)));
      expect(rules.canCapture(board, const Position(1, 3), const Position(2, 4)), isTrue);
    });

    test('馬不能吃同色', () {
      final board = _emptyBoard()
          ._set(const Position(1, 3),
              _piece(PieceRank.horse, PieceColor.red, const Position(1, 3)))
          ._set(const Position(2, 4),
              _piece(PieceRank.soldier, PieceColor.red, const Position(2, 4)));
      expect(rules.canCapture(board, const Position(1, 3), const Position(2, 4)), isFalse);
    });

    test('馬不能正交吃（車直衝模式只能斜吃）', () {
      final board = _emptyBoard()
          ._set(const Position(1, 3),
              _piece(PieceRank.horse, PieceColor.red, const Position(1, 3)))
          ._set(const Position(1, 4),
              _piece(PieceRank.soldier, PieceColor.black, const Position(1, 4)));
      expect(rules.canCapture(board, const Position(1, 3), const Position(1, 4)), isFalse);
    });

    test('馬可斜向盲吃蓋棋', () {
      final board = _emptyBoard()
          ._set(const Position(1, 3),
              _piece(PieceRank.horse, PieceColor.red, const Position(1, 3)))
          ._set(const Position(2, 4),
              _piece(PieceRank.general, PieceColor.black, const Position(2, 4),
                  state: PieceState.faceDown));
      expect(rules.canCapture(board, const Position(1, 3), const Position(2, 4)), isTrue);
    });

    test('未翻開的馬不能吃', () {
      final board = _emptyBoard()
          ._set(const Position(1, 3),
              _piece(PieceRank.horse, PieceColor.red, const Position(1, 3),
                  state: PieceState.faceDown))
          ._set(const Position(2, 4),
              _piece(PieceRank.soldier, PieceColor.black, const Position(2, 4)));
      expect(rules.canCapture(board, const Position(1, 3), const Position(2, 4)), isFalse);
    });
  });

  // ── 車直衝 ─────────────────────────────────────────────────────────────────

  group('車直衝', () {
    test('同行路徑淨空可衝殺（無視階級）', () {
      final board = _emptyBoard()
          ._set(const Position(0, 0),
              _piece(PieceRank.chariot, PieceColor.red, const Position(0, 0)))
          ._set(const Position(0, 3),
              _piece(PieceRank.general, PieceColor.black, const Position(0, 3)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 3)), isTrue);
    });

    test('同列路徑淨空可衝殺', () {
      final board = _emptyBoard()
          ._set(const Position(0, 0),
              _piece(PieceRank.chariot, PieceColor.red, const Position(0, 0)))
          ._set(const Position(3, 0),
              _piece(PieceRank.general, PieceColor.black, const Position(3, 0)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(3, 0)), isTrue);
    });

    test('路徑有棋子擋住不能衝', () {
      final board = _emptyBoard()
          ._set(const Position(0, 0),
              _piece(PieceRank.chariot, PieceColor.red, const Position(0, 0)))
          ._set(const Position(0, 2),
              _piece(PieceRank.soldier, PieceColor.red, const Position(0, 2)))
          ._set(const Position(0, 4),
              _piece(PieceRank.general, PieceColor.black, const Position(0, 4)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 4)), isFalse);
    });

    test('鄰接一格不算車直衝（用一般吃子規則）', () {
      final board = _emptyBoard()
          ._set(const Position(0, 0),
              _piece(PieceRank.chariot, PieceColor.red, const Position(0, 0)))
          ._set(const Position(0, 1),
              _piece(PieceRank.soldier, PieceColor.black, const Position(0, 1)));
      // 鄰接一格走一般吃子（車 > 兵，可吃）
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 1)), isTrue);
    });

    test('非車不能直衝', () {
      final board = _emptyBoard()
          ._set(const Position(0, 0),
              _piece(PieceRank.general, PieceColor.red, const Position(0, 0)))
          ._set(const Position(0, 3),
              _piece(PieceRank.soldier, PieceColor.black, const Position(0, 3)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 3)), isFalse);
    });

    test('車不能斜向衝', () {
      final board = _emptyBoard()
          ._set(const Position(0, 0),
              _piece(PieceRank.chariot, PieceColor.red, const Position(0, 0)))
          ._set(const Position(2, 3),
              _piece(PieceRank.soldier, PieceColor.black, const Position(2, 3)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(2, 3)), isFalse);
    });

    test('車可直衝盲吃蓋棋', () {
      final board = _emptyBoard()
          ._set(const Position(0, 0),
              _piece(PieceRank.chariot, PieceColor.red, const Position(0, 0)))
          ._set(const Position(0, 3),
              _piece(PieceRank.general, PieceColor.black, const Position(0, 3),
                  state: PieceState.faceDown));
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 3)), isTrue);
    });

    test('車不能衝殺同色', () {
      final board = _emptyBoard()
          ._set(const Position(0, 0),
              _piece(PieceRank.chariot, PieceColor.red, const Position(0, 0)))
          ._set(const Position(0, 3),
              _piece(PieceRank.soldier, PieceColor.red, const Position(0, 3)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 3)), isFalse);
    });
  });

  // ── 其他棋子在車直衝模式下仍遵守標準規則 ──────────────────────────────────

  group('非馬非車棋子（繼承標準規則）', () {
    test('一般棋子正交一步吃（遵守階級）', () {
      final board = _emptyBoard()
          ._set(const Position(0, 0),
              _piece(PieceRank.general, PieceColor.red, const Position(0, 0)))
          ._set(const Position(0, 1),
              _piece(PieceRank.advisor, PieceColor.black, const Position(0, 1)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 1)), isTrue);
    });

    test('砲跳吃仍然有效', () {
      final board = _emptyBoard()
          ._set(const Position(0, 0),
              _piece(PieceRank.cannon, PieceColor.red, const Position(0, 0)))
          ._set(const Position(0, 2),
              _piece(PieceRank.soldier, PieceColor.red, const Position(0, 2)))
          ._set(const Position(0, 4),
              _piece(PieceRank.soldier, PieceColor.black, const Position(0, 4)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 4)), isTrue);
    });
  });
}
