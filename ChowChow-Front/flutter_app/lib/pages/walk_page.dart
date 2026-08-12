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
          color: ChowColors.orange500,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('산책'),
        actions: [
          if (!_isWalking && _status != _WalkStatus.saving)
            IconButton(
              onPressed: _loadWalkData,
              tooltip: '새로고침',
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWalkData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WalkTrackerCard(
                    status: _status,
                    distanceMeters: _distanceMeters,
                    durationSeconds: _durationSeconds,
                    ignoredGpsPoints: _ignoredGpsPoints,
                    onStart: _startWalk,
                    onPause: _pauseWalk,
                    onResume: _resumeWalk,
                    onFinish: _finishWalk,
                  ),
                  const SizedBox(height: 20),
                  if (_loadMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ChowColors.orange50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _loadMessage!,
                        style: const TextStyle(
                          color: ChowColors.orange600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  _TodayRoadmap(
                    loading: _loading,
                    summary: _summary,
                    previewDistanceMeters: previewTodayMeters,
                    isWalking: _isWalking,
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
    );
  }
}

class _WalkTrackerCard extends StatelessWidget {
  const _WalkTrackerCard({
    required this.status,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.ignoredGpsPoints,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
  });

  final _WalkStatus status;
  final double distanceMeters;
  final int durationSeconds;
  final int ignoredGpsPoints;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final active = status == _WalkStatus.tracking;
    final paused = status == _WalkStatus.paused;
    final saving = status == _WalkStatus.saving;
    final averageSpeed = durationSeconds == 0
        ? 0.0
        : distanceMeters * 3.6 / durationSeconds;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ChowColors.orange400, ChowColors.orange600],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33F97316),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                active ? Icons.gps_fixed : Icons.directions_walk_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                active
                    ? 'GPS로 산책 기록 중'
                    : paused
                    ? '산책 일시정지'
                    : saving
                    ? '산책 저장 중'
                    : '반려동물과 산책을 시작해보세요',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            (distanceMeters / 1000).toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'km',
            style: TextStyle(
              color: Color(0xE6FFFFFF),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _WalkMetric(
                  label: '산책 시간',
                  value: _formatDuration(durationSeconds),
                ),
              ),
              Container(width: 1, height: 36, color: const Color(0x55FFFFFF)),
              Expanded(
                child: _WalkMetric(
                  label: '평균 속도',
                  value: '${averageSpeed.toStringAsFixed(1)}km/h',
                ),
              ),
            ],
          ),
          if (ignoredGpsPoints > 0 && (active || paused)) ...[
            const SizedBox(height: 12),
            Text(
              '정확하지 않은 GPS 신호 $ignoredGpsPoints건 제외',
              style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11),
            ),
          ],
          const SizedBox(height: 24),
          if (saving)
            const CircularProgressIndicator(color: Colors.white)
          else if (!active && !paused)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('산책 시작'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ChowColors.orange600,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: active ? onPause : onResume,
                    icon: Icon(
                      active ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    ),
                    label: Text(active ? '일시정지' : '계속 걷기'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: ChowColors.orange600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onFinish,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('산책 종료'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _WalkMetric extends StatelessWidget {
  const _WalkMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

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
                  '오늘의 산책 로드맵',
                  style: TextStyle(
                    color: ChowColors.gray800,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ChowColors.orange50,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${summary?.todayRewardCoins ?? 0} / 50 코인',
                  style: const TextStyle(
                    color: ChowColors.orange600,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isWalking ? '산책을 종료하면 달성 보상이 지급돼요.' : '매일 최대 50코인을 받을 수 있어요.',
            style: const TextStyle(color: ChowColors.gray500, fontSize: 12),
          ),
          const SizedBox(height: 18),
          if (loading)
            const LinearProgressIndicator()
          else
            ...milestones.map((milestone) {
              final achieved = savedMeters >= milestone.targetMeters;
              final preview = !achieved &&
                  isWalking &&
                  previewDistanceMeters >= milestone.targetMeters;
              return _MilestoneRow(
                milestone: milestone,
                achieved: achieved,
                preview: preview,
              );
            }),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.milestone,
    required this.achieved,
    required this.preview,
  });

  final WalkMilestoneModel milestone;
  final bool achieved;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final color = achieved
        ? ChowColors.green500
        : preview
        ? ChowColors.orange500
        : ChowColors.gray300;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: achieved || preview ? color : ChowColors.gray100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              achieved
                  ? Icons.check_rounded
                  : preview
                  ? Icons.flag_rounded
                  : Icons.lock_outline_rounded,
              color: achieved || preview ? Colors.white : ChowColors.gray400,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _formatDistanceTarget(milestone.targetMeters),
              style: TextStyle(
                color: achieved ? ChowColors.gray800 : ChowColors.gray600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (preview)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text(
                '달성 예정',
                style: TextStyle(color: ChowColors.orange500, fontSize: 11),
              ),
            ),
          Row(
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                color: ChowColors.yellow500,
                size: 18,
              ),
              const SizedBox(width: 3),
              Text(
                '+${milestone.rewardCoins}',
                style: const TextStyle(
                  color: ChowColors.gray700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
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
              color: ChowColors.orange50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_walk_rounded,
              color: ChowColors.orange500,
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
                color: ChowColors.orange600,
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
