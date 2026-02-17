class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  bool get isValid => row >= 0 && row < 4 && col >= 0 && col < 8;

  Position operator +(Position other) => Position(row + other.row, col + other.col);
  Position operator -(Position other) => Position(row - other.row, col - other.col);

  /// 曼哈頓距離
  int manhattanTo(Position other) => (row - other.row).abs() + (col - other.col).abs();

  /// 正交方向（上下左右）
  static const orthogonal = [
    Position(-1, 0), // 上
    Position(1, 0),  // 下
    Position(0, -1), // 左
    Position(0, 1),  // 右
  ];

  /// 對角方向
  static const diagonal = [
    Position(-1, -1),
    Position(-1, 1),
    Position(1, -1),
    Position(1, 1),
  ];

  @override
  bool operator ==(Object other) =>
      other is Position && row == other.row && col == other.col;

  @override
  int get hashCode => row * 8 + col;

  @override
  String toString() => 'Position($row, $col)';
}
