// 配對等待畫面：顯示配對中動畫、模式、取消按鈕
// 找到對手後自動導覽至 OnlineGameScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums.dart';
import '../providers/matchmaking_provider.dart';
import '../providers/online_game_provider.dart';
import 'online_game_screen.dart';

class WaitingScreen extends ConsumerStatefulWidget {
  const WaitingScreen({super.key, required this.mode});

  final GameMode mode;

  @override
  ConsumerState<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends ConsumerState<WaitingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchmakingProvider.notifier).search(widget.mode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(matchmakingProvider);

    // 找到對手 → 設定 roomId，換頁
    ref.listen<MatchmakingState>(matchmakingProvider, (prev, next) {
      if (!mounted) return;
      if (next.status == MatchmakingStatus.found && next.roomId != null) {
        ref.read(onlineRoomIdProvider.notifier).set(next.roomId!);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnlineGameScreen()),
        );
      }
    });

    return PopScope(
      // 攔截返回鍵：先取消配對再離開
      // didPop=true 表示 pop 已由程式碼（_cancel）執行，不重複呼叫
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2E1A0E),
        appBar: AppBar(
          title: const Text('線上對戰'),
          backgroundColor: const Color(0xFF5C2E00),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _cancel,
          ),
        ),
        body: matchState.status == MatchmakingStatus.error
            ? _buildError(matchState.errorMessage ?? '發生錯誤')
            : _buildSearching(),
      ),
    );
  }

  Widget _buildSearching() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: Colors.amber,
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 36),
          const Text(
            '尋找對手中...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF5C2E00),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.mode.displayName,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 60),
          _buildCancelButton(),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.signal_wifi_off, color: Colors.redAccent, size: 56),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildCancelButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: 200,
      child: OutlinedButton(
        onPressed: _cancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: const BorderSide(color: Colors.white38, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text('取消', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  void _cancel() {
    ref.read(matchmakingProvider.notifier).cancel().ignore();
    if (mounted) Navigator.of(context).pop();
  }
}
