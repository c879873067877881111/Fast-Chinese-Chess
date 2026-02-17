import 'package:flutter_test/flutter_test.dart';
import 'package:dark_chess/core/enums.dart';
import 'package:dark_chess/core/position.dart';
import 'package:dark_chess/models/board.dart';
import 'package:dark_chess/models/piece.dart';
import 'package:dark_chess/rules/standard_rule_set.dart';

/// 建立空棋盤
Board _emptyBoard() {
  return Board(List.generate(4, (_) => List<Piece?>.filled(8, null)));
}

extension _BoardTestHelper on Board {
  Board _setPublic(Position pos, Piece? piece) {
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
  final rules = StandardRuleSet();

  group('移動', () {
    test('正交鄰接一步到空格', () {
      final board = _emptyBoard()
          ._setPublic(const Position(1, 3),
              _piece(PieceRank.soldier, PieceColor.red, const Position(1, 3)));
      expect(rules.canMove(board, const Position(1, 3), const Position(1, 4)), isTrue);
      expect(rules.canMove(board, const Position(1, 3), const Position(0, 3)), isTrue);
    });

    test('不能斜走', () {
      final board = _emptyBoard()
          ._setPublic(const Position(1, 3),
              _piece(PieceRank.soldier, PieceColor.red, const Position(1, 3)));
      expect(rules.canMove(board, const Position(1, 3), const Position(2, 4)), isFalse);
    });

    test('不能走超過一步', () {
      final board = _emptyBoard()
          ._setPublic(const Position(1, 3),
              _piece(PieceRank.chariot, PieceColor.red, const Position(1, 3)));
      expect(rules.canMove(board, const Position(1, 3), const Position(1, 5)), isFalse);
    });

    test('目標有棋子不能移動', () {
      final board = _emptyBoard()
          ._setPublic(const Position(1, 3),
              _piece(PieceRank.soldier, PieceColor.red, const Position(1, 3)))
          ._setPublic(const Position(1, 4),
              _piece(PieceRank.soldier, PieceColor.red, const Position(1, 4)));
      expect(rules.canMove(board, const Position(1, 3), const Position(1, 4)), isFalse);
    });
  });

  group('正交鄰接吃子（階級規則）', () {
    test('大吃小', () {
      final board = _emptyBoard()
          ._setPublic(const Position(0, 0),
              _piece(PieceRank.general, PieceColor.red, const Position(0, 0)))
          ._setPublic(const Position(0, 1),
              _piece(PieceRank.advisor, PieceColor.black, const Position(0, 1)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 1)), isTrue);
    });

    test('小不能吃大', () {
      final board = _emptyBoard()
          ._setPublic(const Position(0, 0),
              _piece(PieceRank.soldier, PieceColor.red, const Position(0, 0)))
          ._setPublic(const Position(0, 1),
              _piece(PieceRank.advisor, PieceColor.black, const Position(0, 1)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 1)), isFalse);
    });

    test('兵吃將', () {
      final board = _emptyBoard()
          ._setPublic(const Position(0, 0),
              _piece(PieceRank.soldier, PieceColor.red, const Position(0, 0)))
          ._setPublic(const Position(0, 1),
              _piece(PieceRank.general, PieceColor.black, const Position(0, 1)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 1)), isTrue);
    });

    test('將不能吃兵', () {
      final board = _emptyBoard()
          ._setPublic(const Position(0, 0),
              _piece(PieceRank.general, PieceColor.red, const Position(0, 0)))
          ._setPublic(const Position(0, 1),
              _piece(PieceRank.soldier, PieceColor.black, const Position(0, 1)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 1)), isFalse);
    });

    test('同級互吃', () {
      final board = _emptyBoard()
          ._setPublic(const Position(0, 0),
              _piece(PieceRank.horse, PieceColor.red, const Position(0, 0)))
          ._setPublic(const Position(0, 1),
              _piece(PieceRank.horse, PieceColor.black, const Position(0, 1)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 1)), isTrue);
    });

    test('不能吃同色', () {
      final board = _emptyBoard()
          ._setPublic(const Position(0, 0),
              _piece(PieceRank.general, PieceColor.red, const Position(0, 0)))
          ._setPublic(const Position(0, 1),
              _piece(PieceRank.soldier, PieceColor.red, const Position(0, 1)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 1)), isFalse);
    });
  });

  group('砲跳吃', () {
    test('隔一子可吃', () {
      final board = _emptyBoard()
          ._setPublic(const Position(0, 0),
              _piece(PieceRank.cannon, PieceColor.red, const Position(0, 0)))
          ._setPublic(const Position(0, 2),
              _piece(PieceRank.soldier, PieceColor.red, const Position(0, 2))) // 炮台
          ._setPublic(const Position(0, 4),
              _piece(PieceRank.soldier, PieceColor.black, const Position(0, 4)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 4)), isTrue);
    });

    test('無炮台不能吃', () {
      final board = _emptyBoard()
          ._setPublic(const Position(0, 0),
              _piece(PieceRank.cannon, PieceColor.red, const Position(0, 0)))
          ._setPublic(const Position(0, 4),
              _piece(PieceRank.soldier, PieceColor.black, const Position(0, 4)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 4)), isFalse);
    });

    test('隔兩子不能吃', () {
      final board = _emptyBoard()
          ._setPublic(const Position(0, 0),
              _piece(PieceRank.cannon, PieceColor.red, const Position(0, 0)))
          ._setPublic(const Position(0, 1),
              _piece(PieceRank.soldier, PieceColor.red, const Position(0, 1)))
          ._setPublic(const Position(0, 2),
              _piece(PieceRank.soldier, PieceColor.red, const Position(0, 2)))
          ._setPublic(const Position(0, 4),
              _piece(PieceRank.soldier, PieceColor.black, const Position(0, 4)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 4)), isFalse);
    });

    test('砲鄰接不能吃', () {
      final board = _emptyBoard()
          ._setPublic(const Position(0, 0),
              _piece(PieceRank.cannon, PieceColor.red, const Position(0, 0)))
          ._setPublic(const Position(0, 1),
              _piece(PieceRank.soldier, PieceColor.black, const Position(0, 1)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 1)), isFalse);
    });

    test('砲縱向跳吃', () {
      final board = _emptyBoard()
          ._setPublic(const Position(0, 0),
              _piece(PieceRank.cannon, PieceColor.red, const Position(0, 0)))
          ._setPublic(const Position(1, 0),
              _piece(PieceRank.soldier, PieceColor.red, const Position(1, 0))) // 炮台
          ._setPublic(const Position(3, 0),
              _piece(PieceRank.general, PieceColor.black, const Position(3, 0)));
      expect(rules.canCapture(board, const Position(0, 0), const Position(3, 0)), isTrue);
    });
  });

  group('馬斜吃', () {
    test('對角鄰接可吃（無視階級）', () {
      final board = _emptyBoard()
          ._setPublic(const Position(1, 3),
              _piece(PieceRank.horse, PieceColor.red, const Position(1, 3)))
          ._setPublic(const Position(2, 4),
              _piece(PieceRank.general, PieceColor.black, const Position(2, 4)));
      expect(rules.canCapture(board, const Position(1, 3), const Position(2, 4)), isTrue);
    });

    test('非馬不能斜吃', () {
      final board = _emptyBoard()
          ._setPublic(const Position(1, 3),
              _piece(PieceRank.chariot, PieceColor.red, const Position(1, 3)))
          ._setPublic(const Position(2, 4),
              _piece(PieceRank.soldier, PieceColor.black, const Position(2, 4)));
      expect(rules.canCapture(board, const Position(1, 3), const Position(2, 4)), isFalse);
    });
  });

  group('盲吃', () {
    test('正交鄰接可盲吃蓋棋', () {
      final board = _emptyBoard()
          ._setPublic(const Position(0, 0),
              _piece(PieceRank.soldier, PieceColor.red, const Position(0, 0)))
          ._setPublic(const Position(0, 1),
              _piece(PieceRank.general, PieceColor.black, const Position(0, 1),
                  state: PieceState.faceDown));
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 1)), isTrue);
    });

    test('砲盲吃仍需跳過一子', () {
      final board = _emptyBoard()
          ._setPublic(const Position(0, 0),
              _piece(PieceRank.cannon, PieceColor.red, const Position(0, 0)))
          ._setPublic(const Position(0, 1),
              _piece(PieceRank.soldier, PieceColor.black, const Position(0, 1),
                  state: PieceState.faceDown));
      // 鄰接無炮台，不能盲吃
      expect(rules.canCapture(board, const Position(0, 0), const Position(0, 1)), isFalse);
    });
  });

  group('Board', () {
    test('initial 產生 32 顆棋子', () {
      final board = Board.initial();
      var count = 0;
      for (var r = 0; r < 4; r++) {
        for (var c = 0; c < 8; c++) {
          if (board.at(Position(r, c)) != null) count++;
        }
      }
      expect(count, 32);
    });

    test('initial 全部面朝下', () {
      final board = Board.initial();
      for (var r = 0; r < 4; r++) {
        for (var c = 0; c < 8; c++) {
          expect(board.at(Position(r, c))!.isFaceDown, isTrue);
        }
      }
    });

    test('flip 翻開棋子', () {
      final board = Board.initial();
      final pos = const Position(0, 0);
      final flipped = board.flip(pos);
      expect(flipped.at(pos)!.isFaceUp, isTrue);
      expect(flipped.at(pos)!.rank, board.at(pos)!.rank);
      expect(flipped.at(pos)!.color, board.at(pos)!.color);
    });

    test('capturedCounts 初始為空', () {
      final board = Board.initial();
      expect(board.capturedCounts(PieceColor.red), isEmpty);
      expect(board.capturedCounts(PieceColor.black), isEmpty);
    });

    test('faceDownCount 初始各 16', () {
      final board = Board.initial();
      expect(board.faceDownCount(PieceColor.red), 16);
      expect(board.faceDownCount(PieceColor.black), 16);
    });
  });
}
