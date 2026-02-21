/// Firebase 服務空殼 — 未來接 Firebase 時實作
abstract class FirebaseService {
  Future<void> createRoom(String roomId);
  Future<void> joinRoom(String roomId);
  Stream<Map<String, dynamic>> watchRoom(String roomId);
  Future<void> sendMove(String roomId, Map<String, dynamic> move);
}
