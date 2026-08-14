import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/api_client.dart';
import '../services/walk_service.dart';
import '../theme/chow_theme.dart';

enum _WalkStatus { idle, tracking, paused, saving }

class WalkPage extends StatefulWidget {
  const WalkPage({super.key});

  @override
  State<WalkPage> createState() => _WalkPageState();
}

class _WalkPageState extends State<WalkPage> {
  WalkSummaryModel? _summary;
  List<WalkRecordModel> _recentWalks = [];
  bool _loading = true;
  String? _loadMessage;

  _WalkStatus _status = _WalkStatus.idle;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;
  Position? _lastPosition;
  DateTime? _lastPositionAt;
  DateTime? _startedAt;
  String? _sessionId;
  double _distanceMeters = 0;
  int _durationSeconds = 0;
  int _ignoredGpsPoints = 0;

  bool get _isWalking =>
      _status == _WalkStatus.tracking || _status == _WalkStatus.paused;

  @override
  void initState() {
    super.initState();
    _loadWalkData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadWalkData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadMessage = null;
      });
    }

    WalkSummaryModel? summary;
    List<WalkRecordModel> recent = _recentWalks;
    String? message;

    try {
      summary = await WalkService.fetchToday();
      recent = await WalkService.fetchRecent();
    } on ApiException catch (error) {
      message = error.statusCode == 403
          ? '로그인 정보가 만료되어 산책 기록을 불러오지 못했어요.'
          : '산책 서버가 아직 준비되지 않았어요.';
    } catch (_) {
      message = '산책 기록을 불러오지 못했어요.';
    }

    if (!mounted) return;
    setState(() {
      _summary = summary ?? _summary;
      _recentWalks = recent;
      _loadMessage = message;
      _loading = false;
    });
  }

  Future<void> _startWalk() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _showLocationDialog(
          title: '위치 서비스가 꺼져 있어요',
          message: '휴대폰의 위치 서비스를 켠 뒤 다시 시작해주세요.',
          openSettings: Geolocator.openLocationSettings,
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _showMessage('산책 거리를 기록하려면 위치 권한이 필요해요.');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        await _showLocationDialog(
          title: '위치 권한이 차단됐어요',
          message: '앱 설정에서 위치 권한을 허용해주세요.',
          openSettings: Geolocator.openAppSettings,
        );
        return;
      }

      final now = DateTime.now();
      setState(() {
        _status = _WalkStatus.tracking;
        _sessionId =
            'walk-${now.microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
        _startedAt = now;
        _distanceMeters = 0;
        _durationSeconds = 0;
        _ignoredGpsPoints = 0;
        _lastPosition = null;
        _lastPositionAt = null;
      });

      _startTimer();
      _startPositionUpdates();
    } catch (_) {
      await _stopTracking();
      if (!mounted) return;
      setState(() => _status = _WalkStatus.idle);
      _showMessage('현재 기기에서 위치 정보를 시작하지 못했어요.');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _status != _WalkStatus.tracking) return;
      setState(() => _durationSeconds++);
    });
  }

  void _startPositionUpdates() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      _handlePosition,
      onError: (_) {
        if (mounted) _showMessage('GPS 신호를 확인하고 있어요.');
      },
    );
  }

  void _handlePosition(Position position) {
    if (!mounted || _status != _WalkStatus.tracking) return;
    if (position.accuracy < 0 || position.accuracy > 30) {
      _ignoredGpsPoints++;
      return;
    }

    final now = DateTime.now();
    final previous = _lastPosition;
    final previousAt = _lastPositionAt;
    if (previous == null || previousAt == null) {
      _lastPosition = position;
      _lastPositionAt = now;
      return;
    }

    final elapsedSeconds = now.difference(previousAt).inMilliseconds / 1000;
    if (elapsedSeconds <= 0) return;

    final deltaMeters = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      position.latitude,
      position.longitude,
    );
    final speedMetersPerSecond = deltaMeters / elapsedSeconds;

    if (deltaMeters > 200 || speedMetersPerSecond > 5.6) {
      _ignoredGpsPoints++;
      return;
    }
    if (deltaMeters < 3) return;

    setState(() {
      _distanceMeters += deltaMeters;
      _lastPosition = position;
      _lastPositionAt = now;
    });
  }

  Future<void> _pauseWalk() async {
    if (_status != _WalkStatus.tracking) return;
    await _stopTracking();
    if (!mounted) return;
    setState(() {
      _status = _WalkStatus.paused;
      _lastPosition = null;
      _lastPositionAt = null;
    });
  }

  Future<void> _resumeWalk() async {
    if (_status != _WalkStatus.paused) return;
    setState(() => _status = _WalkStatus.tracking);
    _startTimer();
    _startPositionUpdates();
  }

  Future<void> _stopTracking() async {
    _timer?.cancel();
    _timer = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> _finishWalk() async {
    if (!_isWalking || _startedAt == null || _sessionId == null) return;

    final shouldFinish = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('산책을 종료할까요?'),
        content: Text(
          _distanceMeters < 50
              ? '이동 거리가 매우 짧아요. 그래도 기록할까요?'
              : '${(_distanceMeters / 1000).toStringAsFixed(2)}km 산책을 저장하고 오늘의 보상을 확인합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속 걷기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('종료'),
          ),
        ],
      ),
    );
    if (shouldFinish != true || !mounted) return;

    await _stopTracking();
    setState(() => _status = _WalkStatus.saving);

    try {
      final result = await WalkService.finish(
        sessionId: _sessionId!,
        distanceMeters: _distanceMeters.round(),
        durationSeconds: max(1, _durationSeconds),
        startedAt: _startedAt!,
        endedAt: DateTime.now(),
      );
      if (!mounted) return;
      setState(() {
        _summary = result.today;
        _status = _WalkStatus.idle;
        _sessionId = null;
        _startedAt = null;
        _distanceMeters = 0;
        _durationSeconds = 0;
      });
      await _showResult(result);
      await _loadWalkData();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _status = _WalkStatus.paused);
      _showMessage(
        error.statusCode == 403
            ? '로그인 정보가 없어 저장하지 못했어요.'
            : error.message,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _WalkStatus.paused);
      _showMessage('산책을 저장하지 못했어요. 잠시 후 다시 시도해주세요.');
    }
  }

  Future<void> _showResult(WalkFinishResult result) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.celebration_rounded,
          color: ChowCozy.stone500,
          size: 42,
        ),
        title: const Text('산책 완료!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${result.walk.distanceKm.toStringAsFixed(2)}km',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: ChowColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.earnedCoins > 0
                  ? '로드맵 달성으로 ${result.earnedCoins}코인을 받았어요.'
                  : '다음 거리 목표를 향해 계속 걸어보세요.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocationDialog({
    required String title,
    required String message,
    required Future<bool> Function() openSettings,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openSettings();
            },
            child: const Text('설정 열기'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final previewTodayMeters =
        (_summary?.todayDistanceMeters ?? 0) + _distanceMeters.round();
    final steps = (previewTodayMeters / 1000 * 1350).round();
    final active = _status == _WalkStatus.tracking;

    return Scaffold(
      backgroundColor: ChowCozy.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadWalkData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 상단바: 뒤로가기 + 제목 + 오늘 적립 코인
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back, color: ChowCozy.stone700),
                        ),
                        const Expanded(
                          child: Text(
                            '🚶 산책',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ChowCozy.stone900),
                          ),
                        ),
                        if (!_isWalking && _status != _WalkStatus.saving)
                          IconButton(
                            onPressed: _loadWalkData,
                            tooltip: '새로고침',
                            icon: const Icon(Icons.refresh, color: ChowCozy.stone700),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                    if (_loadMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ChowCozy.stone100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _loadMessage!,
                          style: const TextStyle(color: ChowCozy.stone700, fontSize: 12),
                        ),
                      ),

                    // 오늘의 기록
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [BoxShadow(blurRadius: 12, offset: Offset(0, 4), color: Color(0x0F000000))],
                      ),
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('오늘의 기록', style: TextStyle(fontSize: 12, color: ChowCozy.mutedForeground)),
                          ),
                          const SizedBox(height: 10),
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _WalkMetric(
                                    icon: '📍',
                                    label: 'km',
                                    value: (previewTodayMeters / 1000).toStringAsFixed(2),
                                  ),
                                ),
                                const VerticalDivider(color: ChowCozy.stone100, thickness: 1),
                                Expanded(
                                  child: _WalkMetric(icon: '👣', label: '걸음', value: steps.toString()),
                                ),
                                const VerticalDivider(color: ChowCozy.stone100, thickness: 1),
                                Expanded(
                                  child: _WalkMetric(
                                    icon: '⏱️',
                                    label: '시간',
                                    value: _formatDuration(_durationSeconds),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (active) ...[
                            const SizedBox(height: 12),
                            const Divider(color: ChowCozy.stone100, height: 1),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const _PulsingDot(),
                                const SizedBox(width: 6),
                                const Text('GPS 측정 중', style: TextStyle(fontSize: 12, color: ChowColors.green500, fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Text(
                                  _durationSeconds > 0 && _distanceMeters > 0
                                      ? '페이스 ${(_durationSeconds / 60 / (_distanceMeters / 1000)).toStringAsFixed(1)}분/km'
                                      : '페이스 --',
                                  style: const TextStyle(fontSize: 12, color: ChowCozy.mutedForeground),
                                ),
                              ],
                            ),
                          ],
                          if (_ignoredGpsPoints > 0 && _isWalking) ...[
                            const SizedBox(height: 8),
                            Text(
                              '정확하지 않은 GPS 신호 $_ignoredGpsPoints건 제외',
                              style: const TextStyle(color: ChowCozy.mutedForeground, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 시작/종료 버튼
                    Center(child: _WalkActionButton(status: _status, onStart: _startWalk, onPause: _pauseWalk, onResume: _resumeWalk, onFinish: _finishWalk)),
                    const SizedBox(height: 20),

                    _TodayRoadmap(
                      loading: _loading,
                      summary: _summary,
                      previewDistanceMeters: previewTodayMeters,
                      isWalking: _isWalking,
                    ),
                    const SizedBox(height: 14),

                    // 코인 안내 배너
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: ChowCozy.stone800,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('🪙 거리별 코인 적립', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                SizedBox(height: 2),
                                Text('하루 최대 50코인까지 받을 수 있어요', style: TextStyle(color: Color(0xFFC0AFA0), fontSize: 11)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${_summary?.todayRewardCoins ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                              const Text('오늘 적립', style: TextStyle(color: Color(0xFFC0AFA0), fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    const Text(
                      '최근 산책',
                      style: TextStyle(
                        color: ChowColors.gray800,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else if (_recentWalks.isEmpty)
                      const _EmptyWalkHistory()
                    else
                      ..._recentWalks.map(_WalkHistoryTile.new),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// GPS 기록 중 표시되는 초록 점 펄스 애니메이션 (웹 버전 motion.div 대응)
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: ChowColors.green500,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Start/Pause/Resume/Finish 버튼 — Walk.tsx의 중앙 pill 버튼 스타일
class _WalkActionButton extends StatelessWidget {
  const _WalkActionButton({
    required this.status,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
  });

  final _WalkStatus status;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final active = status == _WalkStatus.tracking;
    final paused = status == _WalkStatus.paused;

    if (status == _WalkStatus.saving) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: CircularProgressIndicator(color: ChowCozy.stone500),
      );
    }

    if (!active && !paused) {
      return _pillButton(
        icon: Icons.play_arrow_rounded,
        label: '산책 시작',
        color: ChowCozy.stone800,
        onTap: onStart,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pillButton(
          icon: active ? Icons.pause_rounded : Icons.play_arrow_rounded,
          label: active ? '일시정지' : '계속 걷기',
          color: ChowCozy.stone800,
          onTap: active ? onPause : onResume,
        ),
        const SizedBox(width: 10),
        _pillButton(
          icon: Icons.stop_rounded,
          label: '산책 종료',
          color: ChowColors.red500,
          onTap: onFinish,
        ),
      ],
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalkMetric extends StatelessWidget {
  const _WalkMetric({required this.icon, required this.label, required this.value});

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: ChowCozy.stone900, fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 1),
        Text(label, style: const TextStyle(color: ChowCozy.mutedForeground, fontSize: 11)),
      ],
    );
  }
}

/// 산책 로드맵 — Walk.tsx처럼 가로 경로 위에 마일스톤을 나열
class _TodayRoadmap extends StatelessWidget {
  const _TodayRoadmap({
    required this.loading,
    required this.summary,
    required this.previewDistanceMeters,
    required this.isWalking,
  });

  final bool loading;
  final WalkSummaryModel? summary;
  final int previewDistanceMeters;
  final bool isWalking;

  static const fallbackMilestones = [
    WalkMilestoneModel(targetMeters: 500, rewardCoins: 5, achieved: false),
    WalkMilestoneModel(targetMeters: 1000, rewardCoins: 5, achieved: false),
    WalkMilestoneModel(targetMeters: 2000, rewardCoins: 10, achieved: false),
    WalkMilestoneModel(targetMeters: 3000, rewardCoins: 10, achieved: false),
    WalkMilestoneModel(targetMeters: 5000, rewardCoins: 20, achieved: false),
  ];

  @override
  Widget build(BuildContext context) {
    final milestones = summary?.milestones ?? fallbackMilestones;
    final savedMeters = summary?.todayDistanceMeters ?? 0;
    final maxTarget = milestones.isEmpty ? 1 : milestones.last.targetMeters;
    final trackFrac = (savedMeters / maxTarget).clamp(0.0, 1.0);

    final nextIndex = milestones.indexWhere((m) => savedMeters < m.targetMeters);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ChowColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '🗺️ 산책 로드맵',
                  style: TextStyle(color: ChowCozy.stone900, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              if (nextIndex >= 0)
                Text(
                  '다음 목표 ${_formatDistanceTarget(milestones[nextIndex].targetMeters)}',
                  style: const TextStyle(color: ChowCozy.mutedForeground, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (loading)
            const LinearProgressIndicator()
          else ...[
            // 경로 + 마일스톤 노드
            LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned(
                      top: 20,
                      left: 20,
                      right: 20,
                      child: Container(height: 4, decoration: BoxDecoration(color: ChowCozy.stone100, borderRadius: BorderRadius.circular(999))),
                    ),
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        height: 4,
                        width: (constraints.maxWidth - 40) * trackFrac,
                        decoration: BoxDecoration(color: ChowCozy.stone400, borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _MilestoneNode(emoji: null, label: '출발', achieved: true, isStart: true),
                        ...milestones.map((m) {
                          final achieved = savedMeters >= m.targetMeters;
                          final preview = !achieved && isWalking && previewDistanceMeters >= m.targetMeters;
                          return _MilestoneNode(
                            emoji: '🎁',
                            label: _formatDistanceTarget(m.targetMeters),
                            reward: '+${m.rewardCoins}',
                            achieved: achieved,
                            preview: preview,
                          );
                        }),
                      ],
                    ),
                  ],
                );
              },
            ),
            if (nextIndex >= 0) ...[
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('다음 보상까지', style: TextStyle(fontSize: 11, color: ChowCozy.mutedForeground)),
                  Text(
                    '🎁 +${milestones[nextIndex].rewardCoins}코인',
                    style: const TextStyle(fontSize: 11, color: ChowCozy.stone700, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    children: [
                      Container(color: ChowCozy.stone100),
                      FractionallySizedBox(
                        widthFactor: () {
                          final prevTarget = nextIndex == 0 ? 0 : milestones[nextIndex - 1].targetMeters;
                          final span = milestones[nextIndex].targetMeters - prevTarget;
                          if (span <= 0) return 1.0;
                          return ((savedMeters - prevTarget) / span).clamp(0.0, 1.0);
                        }(),
                        child: Container(
                          decoration: const BoxDecoration(gradient: LinearGradient(colors: [ChowCozy.stone400, ChowCozy.stone700])),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Center(
                  child: Text('🎉 모든 미션 완료! 대단해요!', style: TextStyle(color: ChowCozy.stone700, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MilestoneNode extends StatelessWidget {
  const _MilestoneNode({
    required this.emoji,
    required this.label,
    this.reward,
    required this.achieved,
    this.preview = false,
    this.isStart = false,
  });

  final String? emoji;
  final String label;
  final String? reward;
  final bool achieved;
  final bool preview;
  final bool isStart;

  @override
  Widget build(BuildContext context) {
    final active = achieved || preview;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isStart
                ? ChowCozy.stone600
                : achieved
                ? ChowCozy.stone600
                : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: active ? ChowCozy.stone600 : ChowCozy.stone200, width: 2),
            boxShadow: active ? const [BoxShadow(blurRadius: 6, color: Color(0x1F000000))] : null,
          ),
          alignment: Alignment.center,
          child: isStart
              ? const Icon(Icons.location_on, color: Colors.white, size: 16)
              : Text(achieved ? '✅' : emoji ?? '🎁', style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: achieved ? ChowCozy.stone700 : preview ? ChowCozy.stone700 : ChowCozy.mutedForeground,
          ),
        ),
        if (reward != null)
          Text(reward!, style: const TextStyle(fontSize: 9, color: ChowCozy.mutedForeground)),
      ],
    );
  }
}

class _WalkHistoryTile extends StatelessWidget {
  const _WalkHistoryTile(this.walk);

  final WalkRecordModel walk;

  @override
  Widget build(BuildContext context) {
    final localDate = walk.startedAt?.toLocal();
    final dateText = localDate == null
        ? '날짜 정보 없음'
        : '${localDate.month}월 ${localDate.day}일 ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ChowColors.gray200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: ChowCozy.stone100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_walk_rounded,
              color: ChowCozy.stone500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${walk.distanceKm.toStringAsFixed(2)}km · ${_formatDuration(walk.durationSeconds)}',
                  style: const TextStyle(
                    color: ChowColors.gray800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$dateText · 평균 ${walk.averageSpeedKmh.toStringAsFixed(1)}km/h',
                  style: const TextStyle(
                    color: ChowColors.gray500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (walk.rewardCoins > 0)
            Text(
              '+${walk.rewardCoins}',
              style: const TextStyle(
                color: ChowCozy.stone700,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyWalkHistory extends StatelessWidget {
  const _EmptyWalkHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ChowColors.gray200),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.route_outlined,
            color: ChowColors.gray400,
            size: 36,
          ),
          SizedBox(height: 10),
          Text(
            '아직 저장된 산책이 없어요.',
            style: TextStyle(color: ChowColors.gray600),
          ),
          SizedBox(height: 4),
          Text(
            '첫 산책을 시작해 기록을 남겨보세요.',
            style: TextStyle(color: ChowColors.gray400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainingSeconds = seconds % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}

String _formatDistanceTarget(int meters) {
  final km = meters / 1000;
  return km == km.roundToDouble()
      ? '${km.toStringAsFixed(0)}km'
      : '${km.toStringAsFixed(1)}km';
}
