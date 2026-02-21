import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dark_chess/core/position.dart';
import 'package:dark_chess/domain/entities/move.dart';

void main() {
  final now = DateTime(2026, 1, 1, 12, 0, 0);

  Map<String, dynamic> baseMap({
    String type = 'move',
    Map<String, dynamic>? to,
  }) =>
      {
        'type': type,
        'from': {'row': 1, 'col': 2},
        'to': to ?? {'row': 1, 'col': 3},
        'playerId': 'user-abc',
        'moveIndex': 3,
        'timestamp': Timestamp.fromDate(now),
      };

  group('Move.fromMap', () {
    test('move 型態正確解析', () {
      final move = Move.fromMap(baseMap());
      expect(move.type, MoveType.move);
      expect(move.from, const Position(1, 2));
      expect(move.to, const Position(1, 3));
      expect(move.playerId, 'user-abc');
      expect(move.moveIndex, 3);
      expect(move.timestamp, now);
    });

    test('capture 型態正確解析', () {
      final move = Move.fromMap(baseMap(type: 'capture'));
      expect(move.type, MoveType.capture);
    });

    test('flip 型態：to 欄位缺失時 fallback 為 from', () {
      final data = baseMap(type: 'flip')..remove('to');
      final move = Move.fromMap(data);
      expect(move.type, MoveType.flip);
      expect(move.to, move.from);
    });

    test('flip 型態：to 欄位存在時正常解析', () {
      final move = Move.fromMap(baseMap(type: 'flip', to: {'row': 1, 'col': 2}));
      expect(move.to, const Position(1, 2));
    });

    test('moveIndex / row / col 為 double 時正確轉換', () {
      final data = baseMap()
        ..['moveIndex'] = 3.0
        ..['from'] = {'row': 1.0, 'col': 2.0}
        ..['to'] = {'row': 1.0, 'col': 3.0};
      final move = Move.fromMap(data);
      expect(move.moveIndex, 3);
      expect(move.from, const Position(1, 2));
    });
  });

  group('Move.toMap', () {
    test('來回序列化結果一致', () {
      final original = Move.fromMap(baseMap());
      final restored = Move.fromMap(original.toMap());

      expect(restored.type, original.type);
      expect(restored.from, original.from);
      expect(restored.to, original.to);
      expect(restored.playerId, original.playerId);
      expect(restored.moveIndex, original.moveIndex);
      expect(restored.timestamp, original.timestamp);
    });
  });
}
