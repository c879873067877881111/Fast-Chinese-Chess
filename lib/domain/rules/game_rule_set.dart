// 規則引擎抽象介面：定義移動、吃子、合法目標、連吃判定
// 繼承鏈：StandardRuleSet → ChainRuleSet → RookRushRuleSet
import '../../core/position.dart';
import '../entities/board.dart';

/// 規則引擎抽象類別
abstract class GameRuleSet {
  /// 能否移動到空格
  bool canMove(Board board, Position from, Position to);

  /// 能否吃子
  bool canCapture(Board board, Position from, Position to);

  /// 取得所有合法目標（移動 + 吃子）
  List<Position> getAvailableMoves(Board board, Position from);

  /// 取得所有合法吃子目標
  List<Position> getCaptureMoves(Board board, Position from);

  /// 是否有連吃機會
  bool hasChainCapture(Board board, Position position);

  /// 此規則集是否支援連吃
  bool get supportsChainCapture;
}
