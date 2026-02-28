import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/matchmaking_repository.dart';

class FirebaseMatchmakingRepository implements MatchmakingRepository {
  final _db = FirebaseFirestore.instance;

  // ── 快速配對（現有邏輯不動） ────────────────────────────────────────────────

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
        final data = snap.data();
        final roomId = data?['roomId'] as String?;
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
        final opponentData = opponentDoc.data();
        if (!opponentDoc.exists || opponentData == null || opponentData['roomId'] != null) {
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
          'pendingPlayerId': null,
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

  // ── 大廳申請制加房（新增方法） ───────────────────────────────────────────────

  @override
  Stream<int> watchQueueCount(GameMode mode) {
    return _db
        .collection('queue')
        .where('mode', isEqualTo: mode.name)
        .where('roomId', isNull: true)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  @override
  Future<String> createRoom(GameMode mode, String userId, int boardSeed) async {
    final now = Timestamp.now();
    final roomRef = _db.collection('rooms').doc();
    await roomRef.set({
      'status': 'waiting',
      'mode': mode.name,
      'redPlayerId': userId,
      'blackPlayerId': null,
      'pendingPlayerId': null,
      'boardSeed': boardSeed,
      'currentTurn': null,
      'moves': [],
      'winner': null,
      'createdAt': now,
      'updatedAt': now,
    }).timeout(const Duration(seconds: 10));
    return roomRef.id;
  }

  @override
  Stream<List<Room>> watchOpenRooms() {
    // 單欄位查詢（不需 composite index），排序在客戶端完成
    return _db
        .collection('rooms')
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .map((snap) {
          final rooms = snap.docs
              .map((doc) => Room.fromFirestore(doc.id, doc.data()))
              .toList();
          rooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return rooms;
        });
  }

  @override
  Future<bool> requestJoin(String roomId, String userId) async {
    bool success = false;
    await _db.runTransaction((tx) async {
      final roomRef = _db.collection('rooms').doc(roomId);
      final roomDoc = await tx.get(roomRef);
      if (!roomDoc.exists) return;
      final data = roomDoc.data();
      if (data == null) return;
      // 只有 status=waiting 且 pendingPlayerId==null 才允許申請
      if (data['status'] != 'waiting') return;
      if (data['pendingPlayerId'] != null) return;
      tx.update(roomRef, {
        'pendingPlayerId': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      success = true;
    });
    return success;
  }

  @override
  Future<void> approveJoin(String roomId) async {
    await _db.runTransaction((tx) async {
      final roomRef = _db.collection('rooms').doc(roomId);
      final roomDoc = await tx.get(roomRef);
      if (!roomDoc.exists) return;
      final data = roomDoc.data();
      if (data == null) return;
      // 只有 status=waiting 才允許接受，防止 race condition 把 finished 改回 playing
      if (data['status'] != 'waiting') return;
      final pendingId = data['pendingPlayerId'] as String?;
      if (pendingId == null) return;
      tx.update(roomRef, {
        'blackPlayerId': pendingId,
        'pendingPlayerId': null,
        'status': 'playing',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> rejectJoin(String roomId) async {
    // 用 transaction 確保不會誤清後到的新申請
    await _db.runTransaction((tx) async {
      final roomRef = _db.collection('rooms').doc(roomId);
      final roomDoc = await tx.get(roomRef);
      if (!roomDoc.exists) return;
      final data = roomDoc.data();
      if (data == null) return;
      if (data['status'] != 'waiting') return;
      tx.update(roomRef, {
        'pendingPlayerId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> cancelJoinRequest(String roomId, String userId) async {
    await _db.runTransaction((tx) async {
      final roomRef = _db.collection('rooms').doc(roomId);
      final roomDoc = await tx.get(roomRef);
      if (!roomDoc.exists) return;
      final data = roomDoc.data();
      if (data == null) return;
      // 只有確認自己是 pendingPlayerId 才清除，避免誤清別人的申請
      if (data['pendingPlayerId'] != userId) return;
      tx.update(roomRef, {
        'pendingPlayerId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> closeRoom(String roomId, String userId) async {
    await _db.runTransaction((tx) async {
      final roomRef = _db.collection('rooms').doc(roomId);
      final roomDoc = await tx.get(roomRef);
      if (!roomDoc.exists) return;
      final data = roomDoc.data();
      if (data == null) return;
      if (data['redPlayerId'] != userId) {
        throw StateError('只有房主才能關閉房間');
      }
      if (data['status'] != 'waiting') return;
      tx.update(roomRef, {
        'status': 'finished',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
