// 線上大廳：模式選擇、快速配對、建立房間、房間列表
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums.dart';
import '../../domain/entities/room.dart';
import '../providers/auth_provider.dart';
import '../providers/online_lobby_provider.dart';
import 'guest_waiting_screen.dart';
import 'host_waiting_screen.dart';
import 'waiting_screen.dart';

class OnlineLobbyScreen extends ConsumerStatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  ConsumerState<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends ConsumerState<OnlineLobbyScreen> {
  GameMode _selectedMode = GameMode.standard;

  @override
  Widget build(BuildContext context) {
    final openRooms = ref.watch(openRoomsProvider);
    final userId = ref.read(authRepositoryProvider).userId;

    return Scaffold(
      backgroundColor: const Color(0xFF2E1A0E),
      appBar: AppBar(
        title: const Text('線上大廳'),
        backgroundColor: const Color(0xFF5C2E00),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildModeSelector(),
          _buildActionButtons(context),
          const Divider(color: Colors.white24, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: const [
                Text(
                  '等待中的房間',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: openRooms.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              ),
              error: (e, _) => Center(
                child: Text(e.toString(),
                    style: const TextStyle(color: Colors.redAccent)),
              ),
              data: (rooms) => rooms.isEmpty
                  ? const Center(
                      child: Text(
                        '目前沒有等待中的房間',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    )
                  : _buildRoomList(context, rooms, userId),
            ),
          ),
        ],
      ),
    );
  }

  // ── 模式選擇器 ─────────────────────────────────────────────────────────────

  Widget _buildModeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: GameMode.values.map((mode) {
          final isSelected = mode == _selectedMode;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMode = mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF5C2E00)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFAA5500)
                        : Colors.white24,
                  ),
                ),
                child: Text(
                  _modeName(mode),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 動作按鈕 ───────────────────────────────────────────────────────────────

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(child: _buildQuickMatchButton(context)),
          const SizedBox(width: 12),
          Expanded(child: _buildCreateRoomButton(context)),
        ],
      ),
    );
  }

  Widget _buildQuickMatchButton(BuildContext context) {
    final queueCount = ref.watch(
      queueCountProvider(_selectedMode).select((v) => v.asData?.value ?? 0),
    );

    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => WaitingScreen(mode: _selectedMode)),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A3A5C),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt, size: 18),
              SizedBox(width: 4),
              Text('快速配對',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            queueCount > 0 ? '⚡ $queueCount 人正在等待' : '目前無人等待',
            style: TextStyle(
              fontSize: 11,
              color: queueCount > 0
                  ? const Color(0xFF66FF88)
                  : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateRoomButton(BuildContext context) {
    final lobbyState = ref.watch(onlineLobbyProvider);
    final isLoading = lobbyState.status == OnlineLobbyStatus.loading;

    return ElevatedButton(
      onPressed: isLoading ? null : () => _createRoom(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E5C1A),
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            const Color(0xFF2E5C1A).withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add_circle_outline, size: 18),
              const SizedBox(width: 4),
              const Text('建立房間',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '等待對手申請',
            style: TextStyle(fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  // ── 房間列表 ───────────────────────────────────────────────────────────────

  Widget _buildRoomList(
      BuildContext context, List<Room> rooms, String? userId) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        final isOwn = room.redPlayerId == userId;
        return _RoomCard(
          room: room,
          isOwn: isOwn,
          onTap: isOwn
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            HostWaitingScreen(roomId: room.id)),
                  )
              : () => _applyRoom(context, room),
        );
      },
    );
  }

  // ── 動作 ───────────────────────────────────────────────────────────────────

  Future<void> _createRoom(BuildContext context) async {
    final roomId =
        await ref.read(onlineLobbyProvider.notifier).createRoom(_selectedMode);
    if (!context.mounted) return;
    if (roomId == null) {
      final err = ref.read(onlineLobbyProvider).errorMessage ?? '未知錯誤';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('建立失敗：$err')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HostWaitingScreen(roomId: roomId)),
    );
    if (!context.mounted) return;
    ref.read(onlineLobbyProvider.notifier).reset();
  }

  Future<void> _applyRoom(BuildContext context, Room room) async {
    final ok =
        await ref.read(onlineLobbyProvider.notifier).requestJoin(room.id);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('該房間目前已有人申請中，請稍後再試')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => GuestWaitingScreen(roomId: room.id)),
    );
    if (!context.mounted) return;
    ref.read(onlineLobbyProvider.notifier).reset();
  }

  String _modeName(GameMode mode) => switch (mode) {
        GameMode.standard => '標準',
        GameMode.chainCapture => '連吃',
        GameMode.chainCaptureWithRookRush => '車直衝',
      };
}

// ── 房間卡片 ──────────────────────────────────────────────────────────────────

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.isOwn,
    required this.onTap,
  });

  final Room room;
  final bool isOwn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPending = room.pendingPlayerId != null;
    final shortId = room.id.length > 4
        ? '...#${room.id.substring(room.id.length - 4)}'
        : room.id;
    final timeAgo = _timeAgo(room.createdAt);

    return Card(
      color: isOwn
          ? const Color(0xFF4A2800)
          : const Color(0xFF3D2010),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isOwn
            ? const BorderSide(color: Color(0xFF8B4513), width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _ModeTag(mode: room.mode),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '房間 $shortId',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                      if (isOwn) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B4513),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '我的',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeAgo,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: ElevatedButton(
                onPressed: (!isOwn && hasPending) ? null : onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOwn
                      ? const Color(0xFF5C2E00)
                      : const Color(0xFF1A3A5C),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white38,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  isOwn ? '進入' : (hasPending ? '審核中' : '申請'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '剛剛';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分鐘前';
    if (diff.inHours < 24) return '${diff.inHours} 小時前';
    return '${diff.inDays} 天前';
  }
}

class _ModeTag extends StatelessWidget {
  const _ModeTag({required this.mode});

  final GameMode mode;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (mode) {
      GameMode.standard => ('標準', const Color(0xFF4A7CC7)),
      GameMode.chainCapture => ('連吃', const Color(0xFF7C4AC7)),
      GameMode.chainCaptureWithRookRush => ('車衝', const Color(0xFFC74A4A)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}
