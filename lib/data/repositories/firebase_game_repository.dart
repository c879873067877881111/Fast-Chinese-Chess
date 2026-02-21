import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/move.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/game_repository.dart';

class FirebaseGameRepository implements GameRepository {
  final _db = FirebaseFirestore.instance;

  @override
  Stream<Room> watchRoom(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .where((snap) => snap.exists)
        .map((snap) => Room.fromFirestore(snap.id, snap.data()!));
  }

  @override
  Future<void> sendMove(String roomId, Move move) async {
    // TODO: 替換為 Cloud Function 呼叫，避免客戶端直接繞過規則引擎。
    //       curl 範例：
    //         functions.httpsCallable('validateAndApplyMove')
    //           .call({'roomId': roomId, 'move': move.toMap()})
    await _db.collection('rooms').doc(roomId).update({
      'moves': FieldValue.arrayUnion([move.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> resignRoom(String roomId, String playerId) async {
    // 讀取 room 以確認投降方是 red 還是 black，對手即為 winner
    final snap = await _db.collection('rooms').doc(roomId).get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final isRed = data['redPlayerId'] == playerId;
    final winner = isRed ? 'black' : 'red';

    await _db.collection('rooms').doc(roomId).update({
      'status': 'finished',
      'winner': winner,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
