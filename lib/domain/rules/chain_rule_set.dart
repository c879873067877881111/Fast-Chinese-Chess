// 連吃規則：繼承 StandardRuleSet，吃子後若仍有可吃目標則進入連吃狀態
import '../../core/position.dart';
import '../entities/board.dart';
import 'standard_rule_set.dart';

class ChainRuleSet extends StandardRuleSet {
  @override
  bool get supportsChainCapture => true;

  @override
  bool hasChainCapture(Board board, Position position) {
    return getCaptureMoves(board, position).isNotEmpty;
  }
}
