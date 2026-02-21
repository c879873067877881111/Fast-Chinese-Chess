import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums.dart';
import '../../domain/repositories/matchmaking_repository.dart';

class FirebaseMatchmakingRepository implements MatchmakingRepository {
  final _db = FirebaseFirestore.instance;

  @override
  Stream<String> joinQueue(GameMode mode, String userId) {
    final controller = StreamController<String>();
    _startMatchmaking(mode, userId, controller);
    return controller.stream;
  }

  Future<void> _startMatchmaking(
    GameMode mode,
    String userId,
    StreamController<String> controller,
  ) async {
    try {
      final myQueueRef = _db.collection('queue').doc(userId);

      // 1. 先把自己寫入 queue
      await myQueueRef.set({
        'userId': userId,
        'mode': mode.name,
        'joinedAt': FieldValue.serverTimestamp(),
        'roomId': null,
      });

      // 2. 查詢是否有人已在等同一個 mode
      // 注意：此 query 需要 Firestore composite index：
      //   collection: queue  fields: mode ASC, userId ASC, roomId ASC
      // 未建 index 時 Firestore 會在 error message 提供建立連結。
      final snapshot = await _db
          .collection('queue')
          .where('mode', isEqualTo: mode.name)
          .where('userId', isNotEqualTo: userId)
          .where('roomId', isNull: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // 3. 找到對手，嘗試用 transaction 搶先建立房間
        final opponentId = snapshot.docs.first.id;
        final roomId = await _claimMatch(mode, userId, opponentId);
        if (roomId != null) {
          controller.add(roomId);
          controller.close();
          return;
        }
        // transaction 失敗（被別人搶走）→ 繼續等待
      }

      // 4. 監聽自己的 queue entry，等 roomId 出現
      StreamSubscription? sub;
      sub = myQueueRef.snapshots().listen((snap) {
        final roomId = snap.data()?['roomId'] as String?;
        if (roomId != null && !controller.isClosed) {
          controller.add(roomId);
          controller.close();
          sub?.cancel();
        }
      }, onError: (e) {
        if (!controller.isClosed) {
          controller.addError(e);
          controller.close();
        }
      });

      controller.onCancel = () => sub?.cancel();
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
        controller.close();
      }
    }
  }

  /// 用 transaction 原子性地建立房間並通知雙方
  /// 若對手已被搶走則回傳 null
  Future<String?> _claimMatch(
    GameMode mode,
    String myId,
    String opponentId,
  ) async {
    try {
      String? roomId;
      await _db.runTransaction((tx) async {
        final opponentRef = _db.collection('queue').doc(opponentId);
        final opponentDoc = await tx.get(opponentRef);

        // 對手已被其他人搶走，放棄
        if (!opponentDoc.exists || opponentDoc.data()!['roomId'] != null) {
          return;
        }

        final seed = Random().nextInt(0x7FFFFFFF);
        final now = Timestamp.now();
        final roomRef = _db.collection('rooms').doc();
        roomId = roomRef.id;

        tx.set(roomRef, {
          'status': 'playing',
          'mode': mode.name,
          'redPlayerId': myId,
          'blackPlayerId': opponentId,
          'boardSeed': seed,
          'currentTurn': null,
          'moves': [],
          'winner': null,
          'createdAt': now,
          'updatedAt': now,
        });
        tx.update(opponentRef, {'roomId': roomId});
        tx.update(_db.collection('queue').doc(myId), {'roomId': roomId});
      });
      return roomId;
    } on FirebaseException catch (_) {
      // transaction 被搶走或 Firestore 衝突 → 讓呼叫方繼續等待
      return null;
    }
  }

  @override
  Future<void> leaveQueue(String userId) async {
    await _db.collection('queue').doc(userId).delete();
  }
}
