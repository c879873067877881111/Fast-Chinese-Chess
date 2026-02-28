import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums.dart';
import '../../domain/entities/room.dart';
import 'auth_provider.dart';
import 'matchmaking_provider.dart';

// ── 佇列人數（family，依 mode 分別監聽） ─────────────────────────────────────

final queueCountProvider = StreamProvider.family<int, GameMode>((ref, mode) {
  return ref.watch(matchmakingRepositoryProvider).watchQueueCount(mode);
});

// ── 公開房間列表（StreamProvider，不塞進 Notifier） ────────────────────────────

final openRoomsProvider = StreamProvider<List<Room>>((ref) {
  return ref.watch(matchmakingRepositoryProvider).watchOpenRooms();
});

// ── 大廳動作狀態 ──────────────────────────────────────────────────────────────

enum OnlineLobbyStatus { idle, loading, error }

class OnlineLobbyState {
  final OnlineLobbyStatus status;
  final String? errorMessage;

  const OnlineLobbyState({
    this.status = OnlineLobbyStatus.idle,
    this.errorMessage,
  });

  OnlineLobbyState copyWith({
    OnlineLobbyStatus? status,
    String? errorMessage,
  }) =>
      OnlineLobbyState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class OnlineLobbyNotifier extends Notifier<OnlineLobbyState> {
  @override
  OnlineLobbyState build() => const OnlineLobbyState();

  String? get _userId => ref.read(authRepositoryProvider).userId;

  /// 建立等待中房間，成功回傳 roomId，失敗回傳 null
  Future<String?> createRoom(GameMode mode) async {
    final userId = _userId;
    if (userId == null) {
      state = const OnlineLobbyState(
        status: OnlineLobbyStatus.error,
        errorMessage: '尚未登入',
      );
      return null;
    }
    state = const OnlineLobbyState(status: OnlineLobbyStatus.loading);
    try {
      final seed = Random.secure().nextInt(0x7FFFFFFF);
      final roomId = await ref
          .read(matchmakingRepositoryProvider)
          .createRoom(mode, userId, seed);
      state = const OnlineLobbyState();
      return roomId;
    } catch (e) {
      state = OnlineLobbyState(
        status: OnlineLobbyStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// 訪客申請加入，true=申請成功，false=已有人申請中
  Future<bool> requestJoin(String roomId) async {
    final userId = _userId;
    if (userId == null) {
      state = const OnlineLobbyState(
        status: OnlineLobbyStatus.error,
        errorMessage: '尚未登入',
      );
      return false;
    }
    state = const OnlineLobbyState(status: OnlineLobbyStatus.loading);
    try {
      final ok = await ref
          .read(matchmakingRepositoryProvider)
          .requestJoin(roomId, userId);
      state = const OnlineLobbyState();
      return ok;
    } catch (e) {
      state = OnlineLobbyState(
        status: OnlineLobbyStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> approveJoin(String roomId) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await ref.read(matchmakingRepositoryProvider).approveJoin(roomId, userId);
    } catch (e) {
      state = OnlineLobbyState(
        status: OnlineLobbyStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> rejectJoin(String roomId) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await ref.read(matchmakingRepositoryProvider).rejectJoin(roomId, userId);
    } catch (e) {
      state = OnlineLobbyState(
        status: OnlineLobbyStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> cancelJoin(String roomId) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await ref
          .read(matchmakingRepositoryProvider)
          .cancelJoinRequest(roomId, userId);
    } catch (e) {
      state = OnlineLobbyState(
        status: OnlineLobbyStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> closeRoom(String roomId) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await ref
          .read(matchmakingRepositoryProvider)
          .closeRoom(roomId, userId);
      state = const OnlineLobbyState();
    } catch (e) {
      state = OnlineLobbyState(
        status: OnlineLobbyStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// 重置狀態為 idle（從子畫面返回時呼叫）
  void reset() {
    state = const OnlineLobbyState();
  }
}

final onlineLobbyProvider =
    NotifierProvider<OnlineLobbyNotifier, OnlineLobbyState>(
  OnlineLobbyNotifier.new,
);
