import '../core/enums.dart';

class TurnStateMachine {
  /// 翻棋後：換人
  static TurnState afterFlip() => TurnState.selectPiece;

  /// 移動後：換人
  static TurnState afterMove() => TurnState.selectPiece;

  /// 吃子後：如有連吃機會則進入連吃狀態，否則換人
  static TurnState afterCapture({required bool hasChain}) {
    return hasChain ? TurnState.chainCapture : TurnState.selectPiece;
  }

  /// 結束連吃：換人
  static TurnState endChain() => TurnState.selectPiece;
}
