# 上架進度追蹤

> 最後更新：2026-03-02

## 總覽

| 平台 | 狀態 | 費用 |
|------|------|------|
| Google Play | 準備上傳 AAB | USD $25（一次性，已開通） |
| App Store | 等待開發者帳號 | USD $99/年（未註冊） |

---

## Google Play — 已完成

- [x] App ID 變更為 `com.c879873067877881111.darkchess`
- [x] `android:label` 改為「快棋暗棋」
- [x] INTERNET 權限
- [x] Release keystore 產生（`~/upload-keystore.jks`）
- [x] `android/key.properties` 建立（已加入 .gitignore）
- [x] `build.gradle.kts` 簽章設定（signingConfigs.release）
- [x] Proguard / R8 規則（`proguard-rules.pro`）
- [x] App Icon 產生（PingFang 粗體「暗棋」+ 金色圓環 + 深棕底色）
- [x] Splash Screen 產生（深棕純色）
- [x] Firebase Android App 註冊（`com.c879873067877881111.darkchess`）
- [x] `google-services.json` 更新
- [x] `firebase_options.dart` 重新產生
- [x] `flutter build appbundle --release` 成功（43.1MB）

## Google Play — 未完成

- [ ] 在 Google Play Console 建立應用程式
- [ ] 上傳 AAB（`build/app/outputs/bundle/release/app-release.aab`）
- [ ] 填寫商店資訊（名稱、描述、截圖）
- [ ] 內容分級問卷
- [ ] 隱私權政策 URL（可用 GitHub Pages）
- [ ] 至少 2 張手機截圖 + 1 張特色圖（1024x500）
- [ ] 選擇應用類別：遊戲 > 桌遊
- [ ] 提交審核

---

## App Store — 已完成

- [x] iOS Bundle ID 變更為 `com.c879873067877881111.darkchess`
- [x] `CFBundleDisplayName` 改為「快棋暗棋」
- [x] Firebase iOS App 註冊
- [x] `GoogleService-Info.plist` 更新
- [x] App Icon iOS 版產生（已移除 alpha channel）
- [x] Xcode archive 成功（`Runner.xcarchive`）

## App Store — 未完成

- [ ] **Apple Developer Program 付費註冊（USD $99/年）**
- [ ] 建立 iOS Distribution 憑證
- [ ] 在 App Store Connect 建立 App
- [ ] export IPA 並上傳
- [ ] 填寫 App Store 資訊（副標題、關鍵字、截圖）
- [ ] 隱私權政策 URL
- [ ] App 審查資訊
- [ ] 提交審核

---

## 共用 — 已完成

- [x] `pubspec.yaml` description 改為「台灣暗棋 Flutter 跨平台應用」
- [x] version 確認 `1.0.0+1`
- [x] `flutter analyze` — 0 issues
- [x] `flutter test` — 56 tests passed
- [x] `flutter_launcher_icons` + `flutter_native_splash` 加入 dev_dependencies
- [x] `analysis_options.yaml` 排除 `tool/` 目錄
- [x] `.gitignore` 加入 `key.properties`、`*.jks`、`*.keystore`
- [x] `Main.storyboard` 補回（原被 .gitignore 誤排除）

## 共用 — 未完成

- [ ] 隱私權政策頁面（GitHub Pages）
- [ ] 上架截圖製作
- [ ] 特色圖製作（Google Play 1024x500）

---

## 上架描述文案

### 短描述（Google Play，80 字內）
台灣暗棋對戰遊戲，支援標準模式與車直衝模式，可線上即時對戰

### 完整描述
快棋暗棋是一款台灣暗棋線上對戰遊戲。

特色功能：
• 標準暗棋模式 — 經典台灣暗棋規則
• 車直衝模式 — 車可直線衝吃，馬可斜吃，更刺激的變體規則
• 連吃模式 — 吃到子可以繼續行動
• 線上即時對戰 — 建立房間或快速配對，與其他玩家對弈
• 翻棋機制 — 棋子蓋面擺放，翻開才知道是什麼
• 支援 Google 登入與匿名登入

遊戲規則：
32 枚棋子隨機蓋面排列在 4×8 棋盤上。玩家輪流翻棋或移動己方棋子。
棋子階級由高到低：帥/將 > 仕/士 > 相/象 > 車/車 > 馬/馬 > 炮/砲 > 兵/卒。
大吃小，同級互吃。炮需隔一子才能吃。兵/卒可吃帥/將。

### App Store 關鍵字
暗棋,台灣暗棋,象棋,棋盤遊戲,對戰,線上對戰,翻棋,桌遊,chess
