// 棋子資料模型：階級、顏色、狀態、位置
// - canCaptureByRank: 階級吃子判定（兵吃將、將不能吃兵、大吃小）
// - displayName: 紅黑雙方的中文名稱映射（帥/將、仕/士...）
import '../../core/enums.dart';
import '../../core/position.dart';

class Piece {
  final PieceRank rank;
  final PieceColor color;
  final PieceState state;
  final Position position;

  const Piece({
    required this.rank,
    required this.color,
    required this.state,
    required this.position,
  });

  bool get isFaceUp => state == PieceState.faceUp;
  bool get isFaceDown => state == PieceState.faceDown;
  bool get isCaptured => state == PieceState.captured;

  /// 是否能以普通方式（階級）吃掉 target
  bool canCaptureByRank(Piece target) {
    if (color == target.color) return false;
    // 兵吃將
    if (rank == PieceRank.soldier && target.rank == PieceRank.general) return true;
    // 將不能吃兵
    if (rank == PieceRank.general && target.rank == PieceRank.soldier) return false;
    // 大吃小或同級互吃
    return rank.index >= target.rank.index;
  }

  Piece copyWith({
    PieceRank? rank,
    PieceColor? color,
    PieceState? state,
    Position? position,
  }) {
    return Piece(
      rank: rank ?? this.rank,
      color: color ?? this.color,
      state: state ?? this.state,
      position: position ?? this.position,
    );
  }

  static const redNames = {
    PieceRank.general: '帥',
    PieceRank.advisor: '仕',
    PieceRank.elephant: '相',
    PieceRank.chariot: '俥',
    PieceRank.horse: '傌',
    PieceRank.cannon: '炮',
    PieceRank.soldier: '兵',
  };

  static const blackNames = {
    PieceRank.general: '將',
    PieceRank.advisor: '士',
    PieceRank.elephant: '象',
    PieceRank.chariot: '車',
    PieceRank.horse: '馬',
    PieceRank.cannon: '包',
    PieceRank.soldier: '卒',
  };

  /// 顯示用的中文名稱
  String get displayName {
    return color == PieceColor.red ? redNames[rank]! : blackNames[rank]!;
  }

  @override
  String toString() => 'Piece($displayName, $state, $position)';
}
