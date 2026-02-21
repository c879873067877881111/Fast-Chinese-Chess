import '../entities/move.dart';
import '../entities/room.dart';

/// 棋局 repository 抽象介面
abstract class GameRepository {
  /// 監聽房間狀態，有任何變更立即推送
  Stream<Room> watchRoom(String roomId);

  /// 送出棋步
  /// TODO: 上線前必須改為呼叫 Cloud Function，
  ///       直接寫 Firestore 會讓規則引擎可被客戶端繞過。
  Future<void> sendMove(String roomId, Move move);

  /// 投降/離開房間，將房間狀態改為 finished
  Future<void> resignRoom(String roomId, String playerId);
}
