# 踩坑紀錄

## 1. Navigator.push 未 await 導致子畫面返回後狀態殘留

**症狀**：建立房間 → 進入等待畫面 → 關閉房間 → 返回大廳，「建立房間」按鈕卡在無法點擊狀態。

**根因**：`Navigator.of(context).push(...)` 沒有 `await`，所以從子畫面 pop 回來後沒有執行任何清理邏輯。如果 Notifier 的 state 因任何原因殘留在非 idle 狀態（loading / error），按鈕就會卡死。

**修法**：
1. `await Navigator.push(...)`，返回後呼叫 `notifier.reset()` 強制歸零
2. Notifier 的 `closeRoom` 成功後顯式重置 state 為 idle（原本成功路徑沒有設定 state）
3. 新增 `reset()` 方法供外部強制歸零

**教訓**：
- 任何會改變 Notifier state 的非同步流程，確保**所有路徑**（成功、失敗、取消）都有明確的 state 歸位
- 從子畫面返回大廳時，防禦性地 reset 共用狀態，不要假設子畫面一定會正確清理
- `Navigator.push` 如果後續需要做清理，一定要 `await`

## 2. Firebase Web 上 `roomRef.set()` 的 await 會卡住

**症狀**：同 bug #1，但根因更深 — `createRoom` 的 `await roomRef.set(...)` 在 web 上等 server ack 時卡住，notifier 的 `createRoom` 永遠不 return，state 永駐 loading。

**根因**：Firestore Web SDK 的 `set()` 預設等 server 確認。網路慢或 Firestore 連線不穩時，`await` 可能長時間阻塞。但 Firestore 本地快取已同步到 `watchOpenRooms` stream，房間出現在列表，用戶透過列表「進入」按鈕進入 HostWaitingScreen（繞過 `_createRoom` 的導航路徑），導致 `reset()` 永遠不執行。

**最終修法**：
1. `createRoom` 的 `roomRef.set()` 用 `await` 但加 `.timeout(10s)`，超時不阻塞
2. 房間列表「進入」按鈕也加 `await Navigator.push` + `reset()`

**教訓**：
- Firestore Web 上 `await doc.set()` 不保證快速 return，別用它阻塞 UI 流程
- fire-and-forget 不可行：寫入只存在本地快取，其他用戶看不到。正確做法是 `await` + timeout
- 如果 ID 不依賴 server 回傳（如 Firestore auto-ID），timeout 後仍可用 roomId 繼續

## 3. Firestore Security Rules 未設定導致寫入靜默失敗

**症狀**：Browser A 建立房間看得到，Browser B 進大廳看到 0 間房間。

**根因**：Firestore 預設安全規則 `allow read, write: if false`（或測試模式過期），所有寫入被 server 拒絕。但 Firestore Web SDK 的本地快取會樂觀寫入，讓發起者以為成功了（本地 stream 正常推送），實際上 server 從未接受。其他用戶查 server 當然是空的。

**修法**：
- 建立 `firestore.rules`，設定 `allow read, write: if request.auth != null`
- 用 `firebase deploy --only firestore:rules` 部署

**教訓**：
- Firestore 本地快取的樂觀寫入會掩蓋 server 端的權限拒絕，不會拋異常
- 新專案上線前務必確認 Security Rules 已正確設定
- `await doc.set()` timeout 可能不是「網路慢」，而是 server 拒絕寫入後 SDK 不斷重試

## 4. Firestore 複合查詢缺少 Composite Index

**症狀**：快速配對報錯 `failed-precondition: The query requires an index`。

**根因**：`queue` collection 的查詢用了三個欄位（`mode`、`userId`、`roomId`），Firestore 要求為此建立 composite index。未建立時 query 直接拋錯。

**修法**：
- 建立 `firestore.indexes.json`，定義 `queue` 的複合索引（mode ASC, roomId ASC, userId ASC）
- 用 `firebase deploy --only firestore:indexes` 部署
- 索引建立需 2-5 分鐘生效

**教訓**：
- Firestore 的 `where()` 多欄位查詢幾乎都需要 composite index
- 錯誤訊息會附帶建立索引的 URL，可直接點擊
- 把 `firestore.indexes.json` 納入版控，避免換環境時遺漏
