// 訪客等待房主審核畫面
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/room.dart';
import '../providers/auth_provider.dart';
import '../providers/game_repository_provider.dart';
import '../providers/online_game_provider.dart';
import '../providers/online_lobby_provider.dart';
import 'online_game_screen.dart';

class GuestWaitingScreen extends ConsumerStatefulWidget {
  const GuestWaitingScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<GuestWaitingScreen> createState() => _GuestWaitingScreenState();
}

class _GuestWaitingScreenState extends ConsumerState<GuestWaitingScreen> {
  // 防止 pushReplacement 之後 listener 再次觸發其他分支
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authRepositoryProvider).userId;

    ref.listen<AsyncValue<Room>>(roomProvider(widget.roomId), (prev, next) {
      if (!mounted || _navigated) return;
      next.whenData((room) {
        // 被接受 → 進入遊戲
        if (room.status == RoomStatus.playing) {
          _navigated = true;
          ref.read(onlineRoomIdProvider.notifier).set(widget.roomId);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnlineGameScreen()),
          );
          return;
        }
        // 房間關閉
        if (room.status == RoomStatus.finished) {
          _navigated = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('房間已關閉')),
          );
          Navigator.of(context).pop();
          return;
        }
        // 申請被拒：prev 必須非 null（排除初始觸發），且自己曾是 pendingPlayerId
        final uid = userId;
        if (uid != null &&
            prev != null &&
            room.pendingPlayerId == null &&
            room.status == RoomStatus.waiting &&
            prev.asData?.value.pendingPlayerId == uid) {
          _navigated = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('申請被拒絕')),
          );
          Navigator.of(context).pop();
        }
      });
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _cancel(userId);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2E1A0E),
        appBar: AppBar(
          title: const Text('等待審核'),
          backgroundColor: const Color(0xFF5C2E00),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _cancel(userId),
          ),
        ),
        body: ref.watch(roomProvider(widget.roomId)).when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          ),
          error: (e, _) => Center(
            child: Text(e.toString(),
                style: const TextStyle(color: Colors.redAccent)),
          ),
          data: (room) => _buildBody(room),
        ),
      ),
    );
  }

  Widget _buildBody(Room room) {
    final shortId = widget.roomId.length > 4
        ? '...#${widget.roomId.substring(widget.roomId.length - 4)}'
        : widget.roomId;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 4),
          ),
          const SizedBox(height: 32),
          Text(
            '房間 $shortId',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            '等待房主審核中...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 60),
          SizedBox(
            width: 200,
            child: OutlinedButton(
              onPressed: () => _cancel(ref.read(authRepositoryProvider).userId),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white38, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('取消申請', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(String? userId) async {
    if (_navigated) return;
    _navigated = true;
    // 等待 Firestore transaction 完成再 pop，避免取消尚未寫入就重新申請被拒
    await ref
        .read(onlineLobbyProvider.notifier)
        .cancelJoin(widget.roomId);
    if (mounted) Navigator.of(context).pop();
  }
}
