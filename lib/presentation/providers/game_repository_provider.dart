import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_game_repository.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/game_repository.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return FirebaseGameRepository();
});

/// 監聽特定房間狀態
final roomProvider = StreamProvider.family<Room, String>((ref, roomId) {
  return ref.watch(gameRepositoryProvider).watchRoom(roomId);
});
