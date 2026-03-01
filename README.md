# Fast Dark Chess (快棋)

台灣暗棋 Flutter 跨平台應用，支援 Android / iOS / macOS / Web。

## 遊戲模式

| 模式 | 說明 |
|------|------|
| 標準模式 | 基本暗棋規則，翻棋、移動、吃子 |
| 車直衝模式 | 連吃 + 車可沿直線衝殺（路徑淨空、無視階級）+ 馬斜走斜吃 |
| 線上對戰 | Firebase 即時對戰，支援大廳制（建立/加入房間）與快速配對 |

## 專案架構

```
lib/
├── main.dart                          # 應用入口
├── app.dart                           # MaterialApp 設定（主題、路由）
├── firebase_options.dart              # Firebase 設定
├── core/
│   ├── enums.dart                     # 列舉定義（遊戲模式、回合狀態、棋子階級/顏色/狀態）
│   └── position.dart                  # 棋盤座標（4×8）、方向常數、曼哈頓距離
├── data/
│   └── repositories/
│       ├── firebase_auth_repository.dart       # Firebase 匿名登入
│       ├── firebase_game_repository.dart       # Firestore 遊戲狀態讀寫
│       └── firebase_matchmaking_repository.dart # Firestore 快速配對佇列
├── domain/
│   ├── entities/
│   │   ├── piece.dart                 # 棋子資料模型（階級判定、中文名稱映射）
│   │   ├── board.dart                 # 棋盤（翻棋、移動、吃子、統計被吃/未翻數量）
│   │   ├── game_state.dart            # 遊戲狀態容器（不可變、copyWith 模式）
│   │   ├── move.dart                  # 移動紀錄
│   │   └── room.dart                  # 線上房間資料模型
│   ├── repositories/
│   │   ├── auth_repository.dart       # 認證介面
│   │   ├── game_repository.dart       # 遊戲存取介面
│   │   └── matchmaking_repository.dart # 配對介面
│   ├── engine/
│   │   ├── move_engine.dart           # 核心遊戲引擎（點擊處理、盲吃流程、勝負判定）
│   │   └── turn_state_machine.dart    # 回合狀態轉換（翻棋→換人、吃子→連吃或換人）
│   └── rules/
│       ├── game_rule_set.dart         # 規則引擎抽象介面
│       ├── standard_rule_set.dart     # 標準規則（正交移動、階級吃子、砲跳吃、盲吃）
│       ├── chain_rule_set.dart        # 連吃規則（繼承標準，新增連吃判定）
│       └── rook_rush_rule_set.dart    # 車直衝規則（繼承連吃，新增車直線衝殺 + 馬斜走斜吃）
└── presentation/
    ├── providers/
    │   ├── auth_provider.dart         # 認證狀態
    │   ├── game_provider.dart         # 本機遊戲狀態、模式切換
    │   ├── game_repository_provider.dart # 遊戲 Repository DI
    │   ├── matchmaking_provider.dart  # 快速配對狀態
    │   ├── online_game_provider.dart  # 線上對戰狀態
    │   └── online_lobby_provider.dart # 線上大廳狀態（房間 CRUD、配對佇列）
    ├── screens/
    │   ├── lobby_screen.dart          # 大廳畫面（模式選擇、響應式橫向佈局）
    │   ├── game_screen.dart           # 本機遊戲畫面
    │   ├── online_lobby_screen.dart   # 線上大廳（房間列表、快速配對）
    │   ├── online_game_screen.dart    # 線上對戰畫面
    │   ├── host_waiting_screen.dart   # 房主等待對手加入
    │   ├── guest_waiting_screen.dart  # 來賓等待房主確認
    │   └── waiting_screen.dart        # 快速配對等待畫面
    └── widgets/
        ├── chess_board.dart           # 棋盤 Widget（8×4 格、合法移動高亮、點擊回調）
        └── chess_piece.dart           # 棋子 Widget（蓋棋/翻開/選中/盲吃 四種視覺狀態）
```

## 吃子規則

- **階級規則**：大吃小或同級互吃（將 > 士 > 象 > 車 > 馬 > 砲 > 兵）
- **特殊規則**：兵可吃將，將不能吃兵
- **砲**：跳吃（中間恰好隔一子，無視階級）
- **馬**（標準模式）：正交一步吃，遵守階級
- **馬**（車直衝模式）：斜走斜吃（對角鄰接，無視階級）
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
flutter run -d chrome      # Web
flutter run -d macos       # macOS
flutter run -d android     # Android 模擬器
```

## 技術棧

- Flutter 3.41.1 / Dart 3.11.0
- 狀態管理：flutter_riverpod
- 後端：Firebase (Firestore + Anonymous Auth)
- 架構：Clean Architecture + 不可變狀態 + 規則引擎繼承鏈
