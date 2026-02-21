import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dark_chess/core/enums.dart';
import 'package:dark_chess/domain/entities/room.dart';

void main() {
  final now = DateTime(2026, 1, 1, 12, 0, 0);

  Map<String, dynamic> baseData() => {
        'status': 'waiting',
        'mode': 'standard',
        'redPlayerId': 'user-red',
        'blackPlayerId': null,
        'boardSeed': 42,
        'currentTurn': null,
        'moves': [],
        'winner': null,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

  group('Room.fromFirestore', () {
    test('基本欄位正確解析', () {
      final room = Room.fromFirestore('room-1', baseData());

      expect(room.id, 'room-1');
      expect(room.status, RoomStatus.waiting);
      expect(room.mode, GameMode.standard);
      expect(room.redPlayerId, 'user-red');
      expect(room.blackPlayerId, isNull);
      expect(room.boardSeed, 42);
      expect(room.currentTurn, isNull);
      expect(room.moves, isEmpty);
      expect(room.winner, isNull);
      expect(room.createdAt, now);
    });

    test('boardSeed 為 num 型別時正確轉換', () {
      final data = baseData()..['boardSeed'] = 42.0; // Firestore 有時回傳 double
      final room = Room.fromFirestore('room-1', data);
      expect(room.boardSeed, 42);
    });

    test('非 null 欄位正確解析', () {
      final data = baseData()
        ..['status'] = 'playing'
        ..['blackPlayerId'] = 'user-black'
        ..['currentTurn'] = 'red'
        ..['winner'] = 'black';
      final room = Room.fromFirestore('room-1', data);

      expect(room.status, RoomStatus.playing);
      expect(room.blackPlayerId, 'user-black');
      expect(room.currentTurn, PieceColor.red);
      expect(room.winner, PieceColor.black);
    });

    test('所有 GameMode 正確解析', () {
      for (final mode in GameMode.values) {
        final data = baseData()..['mode'] = mode.name;
        expect(Room.fromFirestore('r', data).mode, mode);
      }
    });
  });

  group('Room.toFirestore', () {
    test('來回序列化結果一致', () {
      final original = Room.fromFirestore('room-1', baseData());
      final serialized = original.toFirestore();
      final restored = Room.fromFirestore('room-1', serialized);

      expect(restored.status, original.status);
      expect(restored.mode, original.mode);
      expect(restored.boardSeed, original.boardSeed);
      expect(restored.redPlayerId, original.redPlayerId);
      expect(restored.blackPlayerId, original.blackPlayerId);
      expect(restored.currentTurn, original.currentTurn);
      expect(restored.winner, original.winner);
    });
  });
}
