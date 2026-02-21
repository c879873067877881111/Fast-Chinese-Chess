/// 認證 repository 抽象介面
abstract class AuthRepository {
  /// 當前使用者 ID，未登入時為 null
  String? get userId;

  /// 使用者 ID 的 stream，登入/登出時自動推送
  Stream<String?> get userIdStream;

  /// 匿名登入（已登入則直接回傳）
  Future<void> signInAnonymously();

  /// 登出
  Future<void> signOut();
}
