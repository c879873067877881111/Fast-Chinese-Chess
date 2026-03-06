對這個項目而言，Firebase vs Spring Boot

Firebase 的優點

1. 零運維成本
   你不需要管伺服器。沒有 EC2、沒有 Kubernetes、沒有 Nginx。對一個 side project 來說，運維成本是殺手，Spring Boot 部署還沒開始你就先死在 DevOps 上。

2. Realtime Database / Firestore 天生適合棋盤同步
   看你的 watchRoom() 回傳 Stream，這個設計天然對應 Firebase 的 snapshot listener。棋盤狀態變更 → 對手即時看到，這種 pub/sub 模型 Firebase 開箱即用，Spring Boot
   你得自己實作 WebSocket + STOMP 或 SSE，代碼量多三倍。

3. 跨平台 SDK 完整
   你的目標是 Android / iOS / macOS / Web 四個平台，Firebase SDK 全部支援，Flutter 的 firebase_core 生態成熟。

4. Auth 直接整合
   Google Sign-In、匿名登入，三行代碼搞定。

  ---
Firebase 的缺點

1. 業務邏輯在客戶端 = 安全漏洞
   這是最嚴重的問題。你的規則引擎（standard_rule_set.dart、chain_rule_set.dart）全在 Flutter 端。如果你直接讓 client 寫棋步到 Firestore，惡意用戶可以發任何合法格式的
   move，繞過所有規則。

正確做法是用 Cloud Functions 做服務端驗證，但這等於你還是要寫後端，只是換成 Node.js/Python。

2. 費用不可預測
   Firestore 按讀寫次數計費。一場棋局幾十步還好，但如果有大量 snapshot listener 在不必要地觸發，帳單會讓你哭。

3. 被 Google 綁架
   Firebase 是 vendor lock-in 的教科書案例。你的 FirebaseService 雖然有做 abstract interface（這個設計是對的），但遷移成本依然不低。

4. 複雜查詢能力弱
   Firestore 查詢限制多（不支援 OR、不支援多欄位不等式）。如果你以後要做天梯排名、歷史對局查詢，你會很痛苦。

  ---
Spring Boot 的優點

1. 業務邏輯完整留在服務端
   規則引擎放後端，client 只負責展示。這才是正確的架構，作弊空間為零。

2. WebSocket 原生支援
   Spring 的 @MessageMapping + SockJS，棋局同步乾淨直接。

3. 查詢能力完整
   配 PostgreSQL，你想要什麼查詢都能做，不被 NoSQL 的限制卡死。

4. 完全掌控
   沒有 vendor lock-in，費用可預測，架構你說了算。

  ---
Spring Boot 的缺點

1. 對這個項目，運維成本不成比例
   你需要：伺服器、資料庫、反向代理、SSL、CI/CD、監控。這是一個暗棋遊戲，不是銀行系統。

2. 啟動複雜度高
   Spring Boot 的樣板代碼量，相比 Firebase 的三行初始化，開發速度慢很多。

3. 跨平台 client 要自己管連線
   WebSocket 重連、斷線處理，你得自己寫。

  ---
我的判斷

你用 Firebase 這個選擇在當前階段是合理的——項目還在 MVP 階段，FirebaseService 甚至還是空殼，先把遊戲邏輯做對比選技術棧更重要。

但你必須注意：firebase_service.dart 已經有 sendMove() 了。等你真正接 Firebase 時，千萬不要讓 client 直接寫棋步到 Firestore 而不經過 Cloud Functions
驗證。不然你的規則引擎 Dart 代碼等於廢紙——任何人開 Chrome DevTools 就能作弊。

你現在做的 abstract interface 隔離是對的，繼續保持這個設計。
