import '../../core/enums.dart';

/// 配對 repository 抽象介面
///
/// Firestore schema /queue/{userId}:
///   userId   : string
///   mode     : string
///   joinedAt : timestamp
///   roomId   : string | null  ← 配對成功後由建立方寫入
abstract class MatchmakingRepository {
  /// 加入配對佇列，stream 在配對成功時推送 roomId（只推一次）
  Stream<String> joinQueue(GameMode mode, String userId);

  /// 離開配對佇列
  Future<void> leaveQueue(String userId);
}
