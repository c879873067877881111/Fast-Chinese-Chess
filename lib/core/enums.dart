// 全域列舉定義：遊戲模式、回合狀態機、棋子階級/顏色/狀態
//
// PieceRank 的 index 順序即為階級大小（soldier=0 最小，general=6 最大）

/// 遊戲模式
enum GameMode {
  standard,            // 標準模式：無連吃
  chainCapture,        // 連吃模式
  chainCaptureWithRookRush, // 連吃 + 車直衝
}

/// 回合狀態
enum TurnState {
  selectPiece,   // 選擇棋子（或翻棋）
  movePiece,     // 已選棋子，等待移動/吃子
  chainCapture,  // 連吃中
  blindReveal,   // 盲吃翻開展示中，點擊任意處繼續結算
}

/// 棋子階級（數值越大越高）
enum PieceRank {
  soldier, // 兵/卒 (0)
  cannon,  // 炮/包 (1)
  horse,   // 馬/傌 (2)
  chariot, // 車/俥 (3)
  elephant,// 象/相 (4)
  advisor, // 士/仕 (5)
  general, // 將/帥 (6)
}

/// 棋子顏色
enum PieceColor {
  red,
  black,
}

/// 棋子狀態
enum PieceState {
  faceDown, // 未翻開
  faceUp,   // 已翻開
  captured, // 已被吃
}
