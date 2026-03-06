# Firebase 初始化紀錄

## 環境

- Flutter SDK ^3.11.0
- flutterfire_cli 1.3.1
- firebase-tools（Firebase CLI）

---

## 步驟

### 1. 在 Firebase Console 建立專案

前往 [console.firebase.google.com](https://console.firebase.google.com)，建立新專案 `dark-chess`，專案 ID `dark-chess-f29b9`。

### 2. 安裝 FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

安裝後 CLI 在 `$HOME/.pub-cache/bin`，需要手動加 PATH：

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

要永久生效，把這行加進 `~/.zshrc`。

### 3. 安裝 Firebase CLI

FlutterFire CLI 依賴官方 Firebase CLI，少了它 `flutterfire configure` 會報錯：

```
ERROR: The FlutterFire CLI currently requires the official Firebase CLI to also be installed
```

安裝：

```bash
npm install -g firebase-tools
```

### 4. Firebase 登入

```bash
firebase login
```

過程中會問是否啟用 Gemini in Firebase 和匿名使用統計，全部 yes 不影響功能。

### 5. 執行 flutterfire configure

```bash
flutterfire configure
```

選擇 Firebase 專案 → 平台選 iOS、Android、macOS、Web。

**踩坑：xcodeproj gem 缺失**

configure 到一半會報 Ruby 錯誤：

```
Exception: cannot load such file -- xcodeproj (LoadError)
```

這是因為 Xcode 專案設定需要 Ruby 的 `xcodeproj` gem，系統預設沒有。

修法：

```bash
sudo gem install xcodeproj
```

裝完再跑一次 `flutterfire configure`，成功後會生成 `lib/firebase_options.dart`。

### 6. 更新 pubspec.yaml

```yaml
dependencies:
  firebase_core: ^3.13.0
  firebase_auth: ^5.5.3
  cloud_firestore: ^5.6.6
  google_sign_in: ^6.2.2
```

```bash
flutter pub get
```

### 7. 更新 main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: DarkChessApp()));
}
```

`main()` 必須改成 `async`，且 `WidgetsFlutterBinding.ensureInitialized()` 要在 `Firebase.initializeApp()` 前面，否則會 crash。

---

## 驗證

```bash
flutter analyze  # 零錯誤即完成
```
