// 應用入口：以 Riverpod ProviderScope 包裝根 Widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(const ProviderScope(child: DarkChessApp()));
}
