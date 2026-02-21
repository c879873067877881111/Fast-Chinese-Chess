import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums.dart';
import '../../data/repositories/firebase_matchmaking_repository.dart';
import '../../domain/repositories/matchmaking_repository.dart';
import 'auth_provider.dart';

final matchmakingRepositoryProvider = Provider<MatchmakingRepository>((ref) {
  return FirebaseMatchmakingRepository();
});

// ---------------------------------------------------------------------------

enum MatchmakingStatus { idle, searching, found, error }

class MatchmakingState {
  final MatchmakingStatus status;
  final String? roomId;
  final String? errorMessage;

  const MatchmakingState({
    this.status = MatchmakingStatus.idle,
    this.roomId,
    this.errorMessage,
  });

  MatchmakingState copyWith({
    MatchmakingStatus? status,
    String? roomId,
    String? errorMessage,
  }) {
    return MatchmakingState(
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------

class MatchmakingNotifier extends Notifier<MatchmakingState> {
  StreamSubscription<String>? _sub;

  @override
  MatchmakingState build() {
    ref.onDispose(() => _sub?.cancel());
    return const MatchmakingState();
  }

  void search(GameMode mode) {
    _sub?.cancel(); // 防止重複呼叫時舊 stream 繼續跑
    _sub = null;

    final userId = ref.read(authRepositoryProvider).userId;
    if (userId == null) {
      state = const MatchmakingState(
        status: MatchmakingStatus.error,
        errorMessage: '尚未登入',
      );
      return;
    }

    state = const MatchmakingState(status: MatchmakingStatus.searching);

    _sub = ref
        .read(matchmakingRepositoryProvider)
        .joinQueue(mode, userId)
        .listen(
          (roomId) => state = MatchmakingState(
            status: MatchmakingStatus.found,
            roomId: roomId,
          ),
          onError: (e) => state = MatchmakingState(
            status: MatchmakingStatus.error,
            errorMessage: e.toString(),
          ),
        );
  }

  Future<void> cancel() async {
    await _sub?.cancel();
    _sub = null;

    final userId = ref.read(authRepositoryProvider).userId;
    if (userId != null) {
      await ref.read(matchmakingRepositoryProvider).leaveQueue(userId);
    }

    state = const MatchmakingState();
  }

}

final matchmakingProvider =
    NotifierProvider<MatchmakingNotifier, MatchmakingState>(
  MatchmakingNotifier.new,
);
