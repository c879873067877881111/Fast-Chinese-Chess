// 房主等待申請 / 審核畫面
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums.dart';
import '../../domain/entities/room.dart';
import '../providers/game_repository_provider.dart';
import '../providers/online_game_provider.dart';
import '../providers/online_lobby_provider.dart';
import 'online_game_screen.dart';

class HostWaitingScreen extends ConsumerStatefulWidget {
  const HostWaitingScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<HostWaitingScreen> createState() => _HostWaitingScreenState();
}

class _HostWaitingScreenState extends ConsumerState<HostWaitingScreen> {
  bool _dialogShowing = false;
  bool _isClosing = false;
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomProvider(widget.roomId));

    ref.listen<AsyncValue<Room>>(roomProvider(widget.roomId), (prev, next) {
      if (!mounted || _navigated) return;
      next.whenData((room) {
        // 有申請者 → 彈出確認 dialog
        if (room.pendingPlayerId != null && !_dialogShowing) {
          _dialogShowing = true;
          _showApproveDialog(room.pendingPlayerId!);
        }
        // 申請被清除：若 dialog 還開著（對方取消申請），主動關閉
        if (room.pendingPlayerId == null && _dialogShowing) {
          _dialogShowing = false;
          Navigator.of(context).pop();
        }
        // 對局開始 → 先關閉懸浮 dialog（如有），再進入遊戲
        if (room.status == RoomStatus.playing) {
          _navigated = true;
          if (_dialogShowing) {
            _dialogShowing = false;
            Navigator.of(context).pop(); // 關閉懸浮的審核 dialog
          }
          ref.read(onlineRoomIdProvider.notifier).set(widget.roomId);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnlineGameScreen()),
          );
        }
        // 房間關閉 → 回到大廳（無論是自己關閉或其他原因）
        if (room.status == RoomStatus.finished) {
          _navigated = true;
          Navigator.of(context).pop();
        }
      });
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmClose();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2E1A0E),
        appBar: AppBar(
          title: const Text('等待申請'),
          backgroundColor: const Color(0xFF5C2E00),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _confirmClose,
          ),
        ),
        body: roomAsync.when(
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            room.mode.displayName,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '等待對手申請中...',
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
              onPressed: _confirmClose,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white38, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('關閉房間', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(String pendingId) {
    final shortId = pendingId.length > 6
        ? '${pendingId.substring(0, 6)}...'
        : pendingId;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF3D2010),
        title: const Text('申請加入',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          '玩家 $shortId 申請加入，是否接受？',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _dialogShowing = false;
              ref.read(onlineLobbyProvider.notifier).rejectJoin(widget.roomId);
            },
            child: const Text('拒絕', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A5C1A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _dialogShowing = false;
              ref.read(onlineLobbyProvider.notifier).approveJoin(widget.roomId);
            },
            child: const Text('接受'),
          ),
        ],
      ),
    );
  }

  void _confirmClose() {
    if (_isClosing) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF3D2010),
        title: const Text('關閉房間',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          '確定要關閉房間嗎？正在申請中的玩家將會收到通知。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C2E00),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              _isClosing = true;
              try {
                await ref
                    .read(onlineLobbyProvider.notifier)
                    .closeRoom(widget.roomId);
                // 正常情況由 ref.listen 偵測到 finished 狀態後 pop；
                // 若 stream 尚未觸發，這裡補一次保底。
                if (mounted && !_navigated) {
                  _navigated = true;
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('關閉失敗：$e')),
                  );
                }
              } finally {
                if (mounted) _isClosing = false;
              }
            },
            child: const Text('確定關閉'),
          ),
        ],
      ),
    );
  }

}
