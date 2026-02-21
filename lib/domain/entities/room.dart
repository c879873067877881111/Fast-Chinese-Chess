// 線上對戰房間 entity，對應 Firestore /rooms/{roomId}
//
// Firestore schema:
//   status       : "waiting" | "playing" | "finished"
//   mode         : "standard" | "chainCapture" | "chainCaptureWithRookRush"
//   redPlayerId  : string
//   blackPlayerId: string | null
//   boardSeed    : int      ← 雙端用同一種子初始化棋盤
//   currentTurn  : "red" | "black" | null
//   moves        : List<Map> ← Cloud Function 寫入的棋步歷史
//   createdAt    : timestamp
//   updatedAt    : timestamp
import '../../core/enums.dart';

enum RoomStatus { waiting, playing, finished }

class Room {
  final String id;
  final RoomStatus status;
  final GameMode mode;
  final String redPlayerId;
  final String? blackPlayerId;
  final int boardSeed;
  final PieceColor? currentTurn;
  final List<Map<String, dynamic>> moves;
  final PieceColor? winner;

  const Room({
    required this.id,
    required this.status,
    required this.mode,
    required this.redPlayerId,
    this.blackPlayerId,
    required this.boardSeed,
    this.currentTurn,
    this.moves = const [],
    this.winner,
  });

  factory Room.fromFirestore(String id, Map<String, dynamic> data) {
    return Room(
      id: id,
      status: _parseStatus(data['status'] as String),
      mode: _parseMode(data['mode'] as String),
      redPlayerId: data['redPlayerId'] as String,
      blackPlayerId: data['blackPlayerId'] as String?,
      boardSeed: data['boardSeed'] as int,
      currentTurn: _parseColor(data['currentTurn'] as String?),
      moves: (data['moves'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>(),
      winner: _parseColor(data['winner'] as String?),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'status': status.name,
      'mode': mode.name,
      'redPlayerId': redPlayerId,
      'blackPlayerId': blackPlayerId,
      'boardSeed': boardSeed,
      'currentTurn': currentTurn?.name,
      'moves': moves,
      'winner': winner?.name,
    };
  }

  static RoomStatus _parseStatus(String s) =>
      RoomStatus.values.firstWhere((e) => e.name == s);

  static GameMode _parseMode(String s) =>
      GameMode.values.firstWhere((e) => e.name == s);

  static PieceColor? _parseColor(String? s) =>
      s == null ? null : PieceColor.values.firstWhere((e) => e.name == s);
}
