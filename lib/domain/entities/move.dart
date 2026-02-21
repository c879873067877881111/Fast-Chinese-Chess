// 棋步 entity，對應 Firestore /rooms/{roomId}/moves[] 中的每一筆
//
// type      : "flip" | "move" | "capture"
// from/to   : {"row": int, "col": int}（flip 時 to == from）
// playerId  : string
// moveIndex : int  ← 防重放，Cloud Function 驗證順序
// timestamp : timestamp
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/position.dart';

enum MoveType { flip, move, capture }

class Move {
  final MoveType type;
  final Position from;
  final Position to;
  final String playerId;
  final int moveIndex;
  final DateTime timestamp;

  const Move({
    required this.type,
    required this.from,
    required this.to,
    required this.playerId,
    required this.moveIndex,
    required this.timestamp,
  });

  factory Move.fromMap(Map<String, dynamic> data) {
    final fromMap = data['from'] as Map<String, dynamic>;
    final toMap = data['to'] as Map<String, dynamic>;
    return Move(
      type: MoveType.values.firstWhere((e) => e.name == data['type']),
      from: Position((fromMap['row'] as num).toInt(), (fromMap['col'] as num).toInt()),
      to: Position((toMap['row'] as num).toInt(), (toMap['col'] as num).toInt()),
      playerId: data['playerId'] as String,
      moveIndex: (data['moveIndex'] as num).toInt(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'from': {'row': from.row, 'col': from.col},
      'to': {'row': to.row, 'col': to.col},
      'playerId': playerId,
      'moveIndex': moveIndex,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
