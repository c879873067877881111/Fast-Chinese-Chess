// 4×8 不可變棋盤：翻棋(flip)、移動(move)、吃子(capture)
// 提供統計方法：capturedCounts（被吃數量）、faceDownCount（未翻開數量）
import '../core/enums.dart';
import '../core/position.dart';
import 'piece.dart';

class Board {
  /// 4 rows x 8 cols，null 表示空格
  final List<List<Piece?>> grid;

  Board(this.grid);

  /// 建立初始棋盤（所有棋子面朝下，隨機排列）
  factory Board.initial() {
    final pieces = <Piece>[];
    // 紅黑各 16 子：1將 2士 2象 2車 2馬 2砲 5兵
    for (final color in PieceColor.values) {
      for (final entry in initialCounts.entries) {
        for (var i = 0; i < entry.value; i++) {
          pieces.add(Piece(
            rank: entry.key,
            color: color,
            state: PieceState.faceDown,
            position: const Position(0, 0), // 暫定，洗牌後設定
          ));
        }
      }
    }

    pieces.shuffle();

    final grid = List.generate(4, (row) {
      return List.generate(8, (col) {
        final index = row * 8 + col;
        return pieces[index].copyWith(position: Position(row, col));
      });
    });

    return Board(grid);
  }

  Piece? at(Position pos) {
    if (!pos.isValid) return null;
    return grid[pos.row][pos.col];
  }

  /// 翻棋
  Board flip(Position pos) {
    final piece = at(pos);
    if (piece == null || !piece.isFaceDown) return this;
    return _set(pos, piece.copyWith(state: PieceState.faceUp));
  }

  /// 移動到空格
  Board move(Position from, Position to) {
    final piece = at(from);
    if (piece == null) return this;
    return _set(from, null)._set(to, piece.copyWith(position: to));
  }

  /// 吃子：from 吃 to
  Board capture(Position from, Position to) {
    final attacker = at(from);
    if (attacker == null) return this;
    return _set(from, null)._set(to, attacker.copyWith(position: to));
  }

  /// 取得某方所有面朝上的棋子
  List<Piece> activePieces(PieceColor color) {
    final result = <Piece>[];
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 8; c++) {
        final p = grid[r][c];
        if (p != null && p.color == color && p.isFaceUp) result.add(p);
      }
    }
    return result;
  }

  /// 棋盤上是否還有面朝下的棋子
  bool get hasFaceDownPieces {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 8; c++) {
        if (grid[r][c]?.isFaceDown == true) return true;
      }
    }
    return false;
  }

  /// 某方是否還有棋子（面朝上或面朝下）
  bool hasAnyPiece(PieceColor color) {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 8; c++) {
        final p = grid[r][c];
        if (p != null && p.color == color) return true;
      }
    }
    return false;
  }

  /// 每種棋子的初始數量
  static const initialCounts = {
    PieceRank.general: 1,
    PieceRank.advisor: 2,
    PieceRank.elephant: 2,
    PieceRank.chariot: 2,
    PieceRank.horse: 2,
    PieceRank.cannon: 2,
    PieceRank.soldier: 5,
  };

  /// 某方各棋種目前在棋盤上的數量
  Map<PieceRank, int> _boardCounts(PieceColor color) {
    final counts = <PieceRank, int>{};
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 8; c++) {
        final p = grid[r][c];
        if (p != null && p.color == color) {
          counts[p.rank] = (counts[p.rank] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  /// 某方被吃掉的棋子（rank → 被吃數量）
  Map<PieceRank, int> capturedCounts(PieceColor color) {
    final onBoard = _boardCounts(color);
    final result = <PieceRank, int>{};
    for (final entry in initialCounts.entries) {
      final diff = entry.value - (onBoard[entry.key] ?? 0);
      if (diff > 0) result[entry.key] = diff;
    }
    return result;
  }

  /// 某方未翻開的棋子數量
  int faceDownCount(PieceColor color) {
    var count = 0;
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 8; c++) {
        final p = grid[r][c];
        if (p != null && p.color == color && p.isFaceDown) count++;
      }
    }
    return count;
  }

  Board _set(Position pos, Piece? piece) {
    final newGrid = List.generate(4, (r) => List<Piece?>.from(grid[r]));
    newGrid[pos.row][pos.col] = piece;
    return Board(newGrid);
  }
}
