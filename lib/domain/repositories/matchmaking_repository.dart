import '../../core/enums.dart';
import '../entities/room.dart';

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

  /// 即時監聽指定模式目前在快速配對佇列中的人數（roomId==null 的 queue entry）
  Stream<int> watchQueueCount(GameMode mode);

  /// 建立等待中的房間（status=waiting），回傳 roomId
  Future<String> createRoom(GameMode mode, String userId, int boardSeed);

  /// 即時監聽所有 status=waiting 的公開房間
  Stream<List<Room>> watchOpenRooms();

  /// 訪客申請加入（transaction：pendingPlayerId==null 才成功）
  /// 回傳 true 表示申請成功，false 表示該房間已有人申請中
  Future<bool> requestJoin(String roomId, String userId);

  /// 房主接受申請（pendingPlayerId → blackPlayerId，status → playing）
  Future<void> approveJoin(String roomId, String userId);

  /// 房主拒絕申請（pendingPlayerId → null）
  Future<void> rejectJoin(String roomId, String userId);

  /// 訪客取消申請（確認自己是 pendingPlayerId 才清除）
  Future<void> cancelJoinRequest(String roomId, String userId);

  /// 房主關閉房間（status → finished）
  Future<void> closeRoom(String roomId, String userId);
}
