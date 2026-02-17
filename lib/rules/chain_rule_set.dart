import '../core/position.dart';
import '../models/board.dart';
import 'standard_rule_set.dart';

class ChainRuleSet extends StandardRuleSet {
  @override
  bool get supportsChainCapture => true;

  @override
  bool hasChainCapture(Board board, Position position) {
    return getCaptureMoves(board, position).isNotEmpty;
  }
}
