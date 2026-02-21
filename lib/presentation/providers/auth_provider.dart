import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';

/// AuthRepository 單例
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// 使用者 ID stream — null 表示尚未登入
final authStateProvider = StreamProvider<String?>((ref) {
  return ref.watch(authRepositoryProvider).userIdStream;
});

/// 啟動時自動匿名登入
final authInitProvider = FutureProvider<void>((ref) async {
  await ref.read(authRepositoryProvider).signInAnonymously();
});
