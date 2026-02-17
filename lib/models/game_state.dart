// 遊戲狀態容器（不可變）：棋盤、回合、選中棋子、連吃/盲吃狀態、勝負
// 使用 Function() 包裝的 copyWith 模式支援 nullable 欄位更新
import '../core/enums.dart';
import '../core/position.dart';
import 'board.dart';

class GameState {
  final Board board;
  final PieceColor? currentTurn; // null = 第一手翻棋前
  final TurnState turnState;
  final GameMode mode;
  final Position? selectedPosition;   // 當前選中的棋子（盲吃時=攻擊者）
  final Position? chainPiece;         // 連吃中的棋子位置
  final Position? blindTarget;        // 盲吃翻開展示中的目標位置
  final PieceColor? winner;           // 非 null 表示遊戲結束
  final bool gameOver;

  const GameState({
    required this.board,
    this.currentTurn,
    this.turnState = TurnState.selectPiece,
    required this.mode,
    this.selectedPosition,
    this.chainPiece,
    this.blindTarget,
    this.winner,
    this.gameOver = false,
  });

  GameState copyWith({
    Board? board,
    PieceColor? Function()? currentTurn,
    TurnState? turnState,
    GameMode? mode,
    Position? Function()? selectedPosition,
    Position? Function()? chainPiece,
    Position? Function()? blindTarget,
    PieceColor? Function()? winner,
    bool? gameOver,
  }) {
    return GameState(
      board: board ?? this.board,
      currentTurn: currentTurn != null ? currentTurn() : this.currentTurn,
      turnState: turnState ?? this.turnState,
      mode: mode ?? this.mode,
      selectedPosition: selectedPosition != null ? selectedPosition() : this.selectedPosition,
      chainPiece: chainPiece != null ? chainPiece() : this.chainPiece,
      blindTarget: blindTarget != null ? blindTarget() : this.blindTarget,
      winner: winner != null ? winner() : this.winner,
      gameOver: gameOver ?? this.gameOver,
    );
  }

  PieceColor get opponentColor =>
      currentTurn == PieceColor.red ? PieceColor.black : PieceColor.red;
}
