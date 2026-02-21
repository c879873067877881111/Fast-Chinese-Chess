// 線上對戰狀態管理
//
// onlineRoomIdProvider  : 進入房間前先寫入 roomId
// OnlineGameStateNotifier: 監聽 Firestore room stream，
//   - 新棋步透過 applyMove() 增量重播
//   - tap() / endChain() / resign() 寫入 Firestore（fire-and-forget）
//   - 本地只維護選棋 UI（_localSelection），不進入 blindReveal 動畫
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums.dart';
import '../../core/position.dart';
import '../../domain/engine/move_engine.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/move.dart';
import '../../domain/entities/room.dart';
import 'auth_provider.dart';
import 'game_repository_provider.dart';

// ── 當前房間 ID（進入對局前設定） ────────────────────────────────────────────────

class _RoomIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String roomId) => state = roomId;
  void clear() => state = null;
}

final onlineRoomIdProvider =
    NotifierProvider<_RoomIdNotifier, String?>(_RoomIdNotifier.new);

// ── 狀態類別 ──────────────────────────────────────────────────────────────────

enum OnlineStatus { loading, playing, finished, error }

class OnlineGameState {
  final GameState gameState;
  final Room? room;
  final PieceColor myColor;
  final OnlineStatus status;
  final String? errorMessage;

  const OnlineGameState({
    required this.gameState,
    required this.room,
    required this.myColor,
    required this.status,
    this.errorMessage,
  });

  /// 是否輪到我走
  bool get isMyTurn {
    if (status != OnlineStatus.playing) return false;
    final turn = gameState.currentTurn;
    if (turn == null) return true; // 第一手，任一方可翻棋
    return turn == myColor;
  }

  bool get isLoading => status == OnlineStatus.loading;
  bool get isFinished => status == OnlineStatus.finished;

  /// 勝者（gameState 判定 或 room 投降欄位）
  PieceColor? get winner => gameState.winner ?? room?.winner;

  /// 遊戲是否已結束（棋盤判定 or 房間狀態 or 投降）
  bool get gameOver => gameState.gameOver || isFinished;

  static OnlineGameState loading() => OnlineGameState(
        gameState: GameState(board: Board.fromSeed(0), mode: GameMode.standard),
        room: null,
        myColor: PieceColor.red,
        status: OnlineStatus.loading,
      );

  static OnlineGameState error(String msg) => OnlineGameState(
        gameState: GameState(board: Board.fromSeed(0), mode: GameMode.standard),
        room: null,
        myColor: PieceColor.red,
        status: OnlineStatus.error,
        errorMessage: msg,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class OnlineGameStateNotifier extends Notifier<OnlineGameState> {
  late MoveEngine _engine;

  /// 從 Firestore moves[] 重播後的純棋盤狀態（無 UI 選取）
  GameState? _baseGameState;

  /// 已套用的棋步數量，用於增量更新
  int _appliedMoveCount = 0;

  /// 本地選棋位置（不寫 Firestore，僅 UI 高亮用）
  Position? _localSelection;

  PieceColor _myColor = PieceColor.red;
  String _playerId = '';
  Room? _currentRoom;
  String? _currentRoomId;

  @override
  OnlineGameState build() {
    final roomId = ref.watch(onlineRoomIdProvider);
    if (roomId == null) return OnlineGameState.loading();

    _playerId = ref.watch(authStateProvider).asData?.value ?? '';

    final roomAsync = ref.watch(roomProvider(roomId));

    return roomAsync.when(
      loading: OnlineGameState.loading,
      error: (e, _) => OnlineGameState.error(e.toString()),
      data: (room) {
        _currentRoom = room;
        _myColor = room.redPlayerId == _playerId
            ? PieceColor.red
            : PieceColor.black;
        _engine = MoveEngine.forMode(room.mode);

        // roomId 切換時重置所有局內狀態
        if (_currentRoomId != roomId) {
          _currentRoomId = roomId;
          _baseGameState = null;
          _appliedMoveCount = 0;
          _localSelection = null;
        }

        // 首次建立基礎棋盤
        _baseGameState ??=
            GameState(board: Board.fromSeed(room.boardSeed), mode: room.mode);

        // 增量套用新棋步
        final newCount = room.moves.length;
        if (newCount > _appliedMoveCount) {
          var gs = _baseGameState!;
          for (var i = _appliedMoveCount; i < newCount; i++) {
            gs = _engine.applyMove(gs, Move.fromMap(room.moves[i]));
          }
          _appliedMoveCount = newCount;
          _baseGameState = gs;
          _localSelection = null; // 收到新棋步，清除選棋
        }

        return _buildState(room);
      },
    );
  }

  // ── 公開操作 ─────────────────────────────────────────────────────────────────

  void tap(Position pos) {
    final gs = _baseGameState;
    final room = _currentRoom;
    if (gs == null || room == null) return;
    if (room.status != RoomStatus.playing) return;
    if (gs.gameOver) return;
    if (!_isMyTurn(gs)) return;

    final piece = gs.board.at(pos);

    // 連吃狀態
    if (gs.turnState == TurnState.chainCapture) {
      final chainPos = gs.chainPiece!;
      if (_engine.ruleSet.canCapture(gs.board, chainPos, pos)) {
        _sendMove(_captureMove(chainPos, pos, room));
      }
      return;
    }

    // 已選棋子
    if (_localSelection != null) {
      final from = _localSelection!;

      // 取消選取
      if (pos == from) {
        _localSelection = null;
        state = _buildState(room);
        return;
      }

      // 換選自己的棋子
      if (piece != null &&
          piece.isFaceUp &&
          piece.color == _myColor &&
          gs.currentTurn == _myColor) {
        _localSelection = pos;
        state = _buildState(room);
        return;
      }

      // 移動
      if (_engine.ruleSet.canMove(gs.board, from, pos)) {
        _localSelection = null;
        _sendMove(_moveMove(from, pos, room));
        return;
      }

      // 吃子
      if (_engine.ruleSet.canCapture(gs.board, from, pos)) {
        _localSelection = null;
        _sendMove(_captureMove(from, pos, room));
        return;
      }

      return;
    }

    // 無選取狀態
    if (piece == null) return;

    // 翻棋
    if (piece.isFaceDown) {
      _sendMove(_flipMove(pos, room));
      return;
    }

    // 選取自己的翻開棋子
    if (piece.isFaceUp && piece.color == _myColor) {
      _localSelection = pos;
      state = _buildState(room);
    }
  }

  /// 結束連吃（不繼續吃子，換回合）
  void endChain() {
    final gs = _baseGameState;
    final room = _currentRoom;
    if (gs == null || room == null) return;
    if (gs.turnState != TurnState.chainCapture) return;
    if (!_isMyTurn(gs)) return;
    _sendMove(Move(
      type: MoveType.endChain,
      from: gs.chainPiece!,
      to: gs.chainPiece!,
      playerId: _playerId,
      moveIndex: room.moves.length,
      timestamp: DateTime.now(),
    ));
  }

  /// 投降
  void resign() {
    final room = _currentRoom;
    if (room == null) return;
    if (room.status != RoomStatus.playing) return;
    if (_playerId.isEmpty) return;
    ref.read(gameRepositoryProvider).resignRoom(room.id, _playerId);
  }

  /// 取得合法移動目標（供棋盤 widget 高亮使用）
  List<Position> getLegalMoves(Position from) {
    final gs = _baseGameState;
    if (gs == null) return [];
    return _engine.getLegalMoves(gs, from);
  }

  // ── 私有工具 ─────────────────────────────────────────────────────────────────

  bool _isMyTurn(GameState gs) {
    if (gs.currentTurn == null) return true;
    return gs.currentTurn == _myColor;
  }

  OnlineGameState _buildState(Room room) {
    final gs = _baseGameState!;

    // 連吃中：chainPiece 已在 gs 內，直接展示
    // 否則合併本地選棋
    final displayGs = (gs.turnState != TurnState.chainCapture &&
            _localSelection != null &&
            !gs.gameOver &&
            _isMyTurn(gs))
        ? gs.copyWith(
            selectedPosition: () => _localSelection,
            turnState: TurnState.movePiece,
          )
        : gs;

    return OnlineGameState(
      gameState: displayGs,
      room: room,
      myColor: _myColor,
      status: _toStatus(room),
    );
  }

  OnlineStatus _toStatus(Room room) => switch (room.status) {
        RoomStatus.waiting => OnlineStatus.loading,
        RoomStatus.playing => OnlineStatus.playing,
        RoomStatus.finished => OnlineStatus.finished,
      };

  void _sendMove(Move move) {
    final room = _currentRoom;
    if (room == null) return;
    if (_playerId.isEmpty) return;
    ref
        .read(gameRepositoryProvider)
        .sendMove(room.id, move)
        .catchError((e) => debugPrint('sendMove failed: $e'));
  }

  Move _flipMove(Position pos, Room room) => Move(
        type: MoveType.flip,
        from: pos,
        to: pos,
        playerId: _playerId,
        moveIndex: room.moves.length,
        timestamp: DateTime.now(),
      );

  Move _moveMove(Position from, Position to, Room room) => Move(
        type: MoveType.move,
        from: from,
        to: to,
        playerId: _playerId,
        moveIndex: room.moves.length,
        timestamp: DateTime.now(),
      );

  Move _captureMove(Position from, Position to, Room room) => Move(
        type: MoveType.capture,
        from: from,
        to: to,
        playerId: _playerId,
        moveIndex: room.moves.length,
        timestamp: DateTime.now(),
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

final onlineGameProvider =
    NotifierProvider<OnlineGameStateNotifier, OnlineGameState>(
  OnlineGameStateNotifier.new,
);
