import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/enums.dart';
import '../core/position.dart';
import '../logic/move_engine.dart';
import '../models/board.dart';
import '../models/game_state.dart';

class GameStateNotifier extends Notifier<GameState> {
  late MoveEngine _engine;

  @override
  GameState build() {
    final mode = ref.watch(gameModeProvider);
    _engine = MoveEngine.forMode(mode);
    return GameState(board: Board.initial(), mode: mode);
  }

  void tap(Position pos) {
    final newState = _engine.handleTap(state, pos);
    state = newState;

    // 進入盲吃展示 → 延遲後自動結算
    if (newState.turnState == TurnState.blindReveal) {
      _scheduleBlindResolve();
    }
  }

  void _scheduleBlindResolve() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (state.turnState == TurnState.blindReveal) {
        state = _engine.resolveBlindCapture(state);
      }
    });
  }

  void endChain() {
    state = _engine.endChainCapture(state);
  }

  List<Position> getLegalMoves(Position from) {
    return _engine.getLegalMoves(state, from);
  }

  void restart() {
    _engine = MoveEngine.forMode(state.mode);
    state = GameState(board: Board.initial(), mode: state.mode);
  }
}

class GameModeNotifier extends Notifier<GameMode> {
  @override
  GameMode build() => GameMode.standard;

  void setMode(GameMode mode) => state = mode;
}

final gameModeProvider =
    NotifierProvider<GameModeNotifier, GameMode>(GameModeNotifier.new);

final gameStateProvider =
    NotifierProvider<GameStateNotifier, GameState>(GameStateNotifier.new);
