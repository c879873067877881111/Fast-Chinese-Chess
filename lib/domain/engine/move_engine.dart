// 核心遊戲引擎：處理玩家點擊、翻棋、移動、吃子、盲吃兩階段流程、
// 連吃狀態管理、回合切換、勝負判定
import '../../core/enums.dart';
import '../../core/position.dart';
import '../entities/game_state.dart';
import '../entities/move.dart';
import '../rules/game_rule_set.dart';
import '../rules/standard_rule_set.dart';
import '../rules/chain_rule_set.dart';
import '../rules/rook_rush_rule_set.dart';
import 'turn_state_machine.dart';

class MoveEngine {
  final GameRuleSet ruleSet;

  MoveEngine(this.ruleSet);

  factory MoveEngine.forMode(GameMode mode) {
    switch (mode) {
      case GameMode.standard:
        return MoveEngine(StandardRuleSet());
      case GameMode.chainCapture:
        return MoveEngine(ChainRuleSet());
      case GameMode.chainCaptureWithRookRush:
        return MoveEngine(RookRushRuleSet());
    }
  }

  /// 處理玩家點擊某格
  GameState handleTap(GameState state, Position pos) {
    if (state.gameOver) return state;

    // 盲吃展示中：鎖定操作，等自動結算
    if (state.turnState == TurnState.blindReveal) return state;

    final tappedPiece = state.board.at(pos);

    // 連吃狀態：只能繼續吃或結束
    if (state.turnState == TurnState.chainCapture) {
      return _handleChainCaptureTap(state, pos);
    }

    // 已選中棋子
    if (state.selectedPosition != null) {
      return _handleSelectedTap(state, pos);
    }

    // 未選中：嘗試翻棋或選棋
    if (tappedPiece == null) return state;

    if (tappedPiece.isFaceDown) {
      return _flipPiece(state, pos);
    }

    if (tappedPiece.isFaceUp && _isCurrentPlayerPiece(state, tappedPiece.color)) {
      return state.copyWith(
        selectedPosition: () => pos,
        turnState: TurnState.movePiece,
      );
    }

    return state;
  }

  /// 結束連吃
  GameState endChainCapture(GameState state) {
    if (state.turnState != TurnState.chainCapture) return state;
    return _switchTurn(state.copyWith(
      chainPiece: () => null,
      selectedPosition: () => null,
      turnState: TurnStateMachine.endChain(),
    ));
  }

  /// 取得合法目標
  List<Position> getLegalMoves(GameState state, Position from) {
    if (state.turnState == TurnState.chainCapture) {
      return ruleSet.getCaptureMoves(state.board, from);
    }
    return ruleSet.getAvailableMoves(state.board, from);
  }

  GameState _flipPiece(GameState state, Position pos) {
    final newBoard = state.board.flip(pos);
    final flippedPiece = newBoard.at(pos);
    if (flippedPiece == null) return state;

    // 第一手翻棋決定顏色
    final turn = state.currentTurn ?? flippedPiece.color;

    final newState = state.copyWith(
      board: newBoard,
      currentTurn: () => turn,
      selectedPosition: () => null,
      turnState: TurnStateMachine.afterFlip(),
    );
    return _checkWinCondition(_switchTurn(newState));
  }

  GameState _handleSelectedTap(GameState state, Position pos) {
    final from = state.selectedPosition!;
    final tappedPiece = state.board.at(pos);

    // 點自己 → 取消選擇
    if (pos == from) {
      return state.copyWith(
        selectedPosition: () => null,
        turnState: TurnState.selectPiece,
      );
    }

    // 點自己的棋子 → 換選
    if (tappedPiece != null &&
        tappedPiece.isFaceUp &&
        _isCurrentPlayerPiece(state, tappedPiece.color)) {
      return state.copyWith(selectedPosition: () => pos);
    }

    // 嘗試移動
    if (ruleSet.canMove(state.board, from, pos)) {
      final newBoard = state.board.move(from, pos);
      final newState = state.copyWith(
        board: newBoard,
        selectedPosition: () => null,
        turnState: TurnStateMachine.afterMove(),
      );
      return _checkWinCondition(_switchTurn(newState));
    }

    // 嘗試吃子
    if (ruleSet.canCapture(state.board, from, pos)) {
      return _executeCapture(state, from, pos);
    }

    return state;
  }

  GameState _handleChainCaptureTap(GameState state, Position pos) {
    final chainPos = state.chainPiece!;

    // 嘗試吃子
    if (ruleSet.canCapture(state.board, chainPos, pos)) {
      return _executeCapture(state, chainPos, pos);
    }

    return state;
  }

  GameState _executeCapture(GameState state, Position from, Position to) {
    final target = state.board.at(to);
    if (target == null) return state;

    // 盲吃：目標蓋著 → 先翻開再判定
    if (target.isFaceDown) {
      return _executeBlindCapture(state, from, to);
    }

    // 正常吃（目標已翻開）
    return _executeNormalCapture(state, from, to);
  }

  /// 盲吃第一步：只翻開目標，進入 blindReveal 展示狀態
  GameState _executeBlindCapture(GameState state, Position from, Position to) {
    final flippedBoard = state.board.flip(to);
    return state.copyWith(
      board: flippedBoard,
      selectedPosition: () => from,  // 攻擊者
      blindTarget: () => to,         // 被翻開的目標
      chainPiece: () => state.chainPiece, // 保留連吃資訊
      turnState: TurnState.blindReveal,
    );
  }

  /// 盲吃第二步：自動結算（由 provider 延遲呼叫）
  GameState resolveBlindCapture(GameState state) {
    final from = state.selectedPosition;
    final to = state.blindTarget;
    if (from == null || to == null) return state;
    final attacker = state.board.at(from);
    final revealed = state.board.at(to);
    if (attacker == null || revealed == null) return state;

    // 翻到自己人 → 回合結束
    if (revealed.color == attacker.color) {
      final newState = state.copyWith(
        selectedPosition: () => null,
        blindTarget: () => null,
        chainPiece: () => null,
        turnState: TurnState.selectPiece,
      );
      return _checkWinCondition(_switchTurn(newState));
    }

    // 翻到敵方 → 判定能否吃
    if (ruleSet.canCapture(state.board, from, to)) {
      // 判定通過，執行吃子
      return _executeNormalCapture(
        state.copyWith(blindTarget: () => null),
        from,
        to,
      );
    }

    // 判定失敗（階級不夠）→ 回合結束
    final newState = state.copyWith(
      selectedPosition: () => null,
      blindTarget: () => null,
      chainPiece: () => null,
      turnState: TurnState.selectPiece,
    );
    return _checkWinCondition(_switchTurn(newState));
  }

  /// 正常吃子（目標已翻開，已通過判定）
  GameState _executeNormalCapture(GameState state, Position from, Position to) {
    final newBoard = state.board.capture(from, to);

    if (ruleSet.supportsChainCapture && ruleSet.hasChainCapture(newBoard, to)) {
      return _checkWinCondition(state.copyWith(
        board: newBoard,
        selectedPosition: () => to,
        chainPiece: () => to,
        turnState: TurnStateMachine.afterCapture(hasChain: true),
      ));
    }

    final newState = state.copyWith(
      board: newBoard,
      selectedPosition: () => null,
      chainPiece: () => null,
      turnState: TurnStateMachine.afterCapture(hasChain: false),
    );
    return _checkWinCondition(_switchTurn(newState));
  }

  GameState _switchTurn(GameState state) {
    if (state.currentTurn == null) return state;
    return state.copyWith(
      currentTurn: () => state.opponentColor,
    );
  }

  GameState _checkWinCondition(GameState state) {
    if (state.currentTurn == null) return state;

    final current = state.currentTurn!;
    final opponent = current == PieceColor.red ? PieceColor.black : PieceColor.red;

    // 對方無棋子
    if (!state.board.hasAnyPiece(opponent)) {
      return state.copyWith(
        winner: () => current,
        gameOver: true,
      );
    }

    // 如果對方沒有面朝下的棋子且面朝上的棋子全無合法行動
    if (!state.board.hasFaceDownPieces) {
      final opponentPieces = state.board.activePieces(opponent);
      final hasLegalMove = opponentPieces.any((p) =>
          ruleSet.getAvailableMoves(state.board, p.position).isNotEmpty);
      if (!hasLegalMove && opponentPieces.isNotEmpty) {
        return state.copyWith(
          winner: () => current,
          gameOver: true,
        );
      }
    }

    // 己方同理
    if (!state.board.hasFaceDownPieces) {
      final currentPieces = state.board.activePieces(current);
      final hasLegalMove = currentPieces.any((p) =>
          ruleSet.getAvailableMoves(state.board, p.position).isNotEmpty);
      if (!hasLegalMove && currentPieces.isNotEmpty) {
        return state.copyWith(
          winner: () => opponent,
          gameOver: true,
        );
      }
    }

    return state;
  }

  bool _isCurrentPlayerPiece(GameState state, PieceColor color) {
    return state.currentTurn == null || state.currentTurn == color;
  }

  // ── 線上對戰：重播 Firestore 棋步 ───────────────────────────────────────────

  /// 將 Firestore 記錄的 [move] 套用到 [state]，不維護 UI 狀態（無 blindReveal）。
  /// 用於線上對戰從 boardSeed 重播所有棋步以重建棋盤。
  GameState applyMove(GameState state, Move move) {
    switch (move.type) {
      case MoveType.flip:
        return _replayFlip(state, move.from);
      case MoveType.move:
        return _replayMove(state, move.from, move.to);
      case MoveType.capture:
        return _replayCapture(state, move.from, move.to);
      case MoveType.endChain:
        return _replayEndChain(state);
    }
  }

  GameState _replayFlip(GameState state, Position pos) {
    final newBoard = state.board.flip(pos);
    final flippedPiece = newBoard.at(pos);

    // 資料損毀：翻開後無棋子，仍切換回合避免狀態卡死
    if (flippedPiece == null) {
      return _checkWinCondition(_switchTurn(state.copyWith(
        board: newBoard,
        selectedPosition: () => null,
        turnState: TurnState.selectPiece,
      )));
    }

    final turn = state.currentTurn ?? flippedPiece.color;
    return _checkWinCondition(_switchTurn(state.copyWith(
      board: newBoard,
      currentTurn: () => turn,
      selectedPosition: () => null,
      blindTarget: () => null,
      chainPiece: () => null,
      turnState: TurnStateMachine.afterFlip(),
    )));
  }

  GameState _replayMove(GameState state, Position from, Position to) {
    final newBoard = state.board.move(from, to);
    return _checkWinCondition(_switchTurn(state.copyWith(
      board: newBoard,
      selectedPosition: () => null,
      blindTarget: () => null,
      chainPiece: () => null,
      turnState: TurnStateMachine.afterMove(),
    )));
  }

  /// 重播吃子（含盲吃：目標蓋著時先翻開再判定）
  GameState _replayCapture(GameState state, Position from, Position to) {
    var board = state.board;
    final target = board.at(to);

    // 資料損毀：目標格為空，仍切換回合避免狀態卡死
    if (target == null) {
      return _checkWinCondition(_switchTurn(state.copyWith(
        selectedPosition: () => null,
        blindTarget: () => null,
        chainPiece: () => null,
        turnState: TurnState.selectPiece,
      )));
    }

    // 盲吃：目標蓋著，先翻開
    if (target.isFaceDown) {
      board = board.flip(to);
    }

    final flippedTarget = board.at(to);
    final attacker = board.at(from);

    // 資料損毀：翻開後仍無棋，仍切換回合
    if (attacker == null || flippedTarget == null) {
      return _checkWinCondition(_switchTurn(state.copyWith(
        board: board,
        selectedPosition: () => null,
        blindTarget: () => null,
        chainPiece: () => null,
        turnState: TurnState.selectPiece,
      )));
    }

    // 盲吃失敗（階級不夠）→ 目標留在原位（已翻開），換回合
    if (!attacker.canCaptureByRank(flippedTarget)) {
      return _checkWinCondition(_switchTurn(state.copyWith(
        board: board,
        selectedPosition: () => null,
        blindTarget: () => null,
        chainPiece: () => null,
        turnState: TurnState.selectPiece,
      )));
    }

    // 吃子成功
    final newBoard = board.capture(from, to);
    if (ruleSet.supportsChainCapture && ruleSet.hasChainCapture(newBoard, to)) {
      return _checkWinCondition(state.copyWith(
        board: newBoard,
        selectedPosition: () => to,
        chainPiece: () => to,
        turnState: TurnStateMachine.afterCapture(hasChain: true),
      ));
    }

    return _checkWinCondition(_switchTurn(state.copyWith(
      board: newBoard,
      selectedPosition: () => null,
      blindTarget: () => null,
      chainPiece: () => null,
      turnState: TurnStateMachine.afterCapture(hasChain: false),
    )));
  }

  GameState _replayEndChain(GameState state) {
    return _checkWinCondition(_switchTurn(state.copyWith(
      chainPiece: () => null,
      selectedPosition: () => null,
      turnState: TurnState.selectPiece,
    )));
  }
}
