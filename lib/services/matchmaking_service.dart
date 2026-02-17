/// 配對服務空殼 — 未來接線上配對時實作
abstract class MatchmakingService {
  Future<String> findMatch();
  Future<void> cancelSearch();
}
