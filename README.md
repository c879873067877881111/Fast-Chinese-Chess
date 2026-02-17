# Fast Dark Chess (快棋、連棋)

台灣暗棋 Flutter 跨平台應用，支援 Android / iOS / macOS / Web。

## 遊戲模式

| 模式 | 說明 |
|------|------|
| 標準模式 | 基本暗棋規則，翻棋、移動、吃子 |
| 連吃模式 | 吃子後若仍有可吃目標，可繼續吃（可隨時停止） |
| 車直衝模式 | 連吃 + 車可沿直線衝殺（路徑淨空、無視階級） |

## 專案架構

```
lib/
├── main.dart                  # 應用入口
├── app.dart                   # MaterialApp 設定（主題、路由）
├── core/
│   ├── enums.dart             # 列舉定義（遊戲模式、回合狀態、棋子階級/顏色/狀態）
│   └── position.dart          # 棋盤座標（4×8）、方向常數、曼哈頓距離
├── models/
│   ├── piece.dart             # 棋子資料模型（階級判定、中文名稱映射）
│   ├── board.dart             # 棋盤（翻棋、移動、吃子、統計被吃/未翻數量）
│   └── game_state.dart        # 遊戲狀態容器（不可變、copyWith 模式）
├── rules/
│   ├── game_rule_set.dart     # 規則引擎抽象介面
│   ├── standard_rule_set.dart # 標準規則（正交移動、階級吃子、砲跳吃、馬斜吃、盲吃）
│   ├── chain_rule_set.dart    # 連吃規則（繼承標準，新增連吃判定）
│   └── rook_rush_rule_set.dart# 車直衝規則（繼承連吃，新增車直線衝殺）
├── logic/
│   ├── move_engine.dart       # 核心遊戲引擎（點擊處理、盲吃流程、勝負判定）
│   └── turn_state_machine.dart# 回合狀態轉換（翻棋→換人、吃子→連吃或換人）
├── providers/
│   └── game_provider.dart     # Riverpod 狀態管理（遊戲狀態、模式切換）
├── screens/
│   ├── lobby_screen.dart      # 大廳畫面（模式選擇）
│   └── game_screen.dart       # 遊戲畫面（狀態列、棋子清單、棋盤、連吃按鈕）
├── widgets/
│   ├── chess_board.dart       # 棋盤 Widget（8×4 格、合法移動高亮、點擊回調）
│   └── chess_piece.dart       # 棋子 Widget（蓋棋/翻開/選中/盲吃 四種視覺狀態）
└── services/
    ├── firebase_service.dart      # Firebase 服務介面（未來實作線上對戰）
    └── matchmaking_service.dart   # 配對服務介面（未來實作線上配對）
```

## 吃子規則

- **階級規則**：大吃小或同級互吃（將 > 士 > 象 > 車 > 馬 > 砲 > 兵）
- **特殊規則**：兵可吃將，將不能吃兵
- **砲**：跳吃（中間恰好隔一子，無視階級）
- **馬**：可斜吃（對角鄰接，無視階級）
- **盲吃**：攻擊未翻開的棋子，先翻開再判定（砲盲吃仍需炮台）
- **車直衝**（車直衝模式）：同行/列、路徑淨空、至少隔一格、無視階級

## 開發

```bash
# 安裝依賴
flutter pub get

# 分析
flutter analyze

# 測試
flutter test

# 執行
flutter run -d chrome     # Web
flutter run -d macos      # macOS
flutter run -d android  # Android 模擬器
```

## 技術棧

- Flutter 3.41.1 / Dart 3.11.0
- 狀態管理：flutter_riverpod
- 架構：不可變狀態 + 規則引擎繼承鏈
