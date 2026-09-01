import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/character_service.dart';
import '../services/shop_service.dart';
import '../theme/chow_theme.dart';
import '../theme/shop_visuals.dart';
import 'character_sheets.dart';

/// Figma "Character.tsx" 구조 그대로 이식:
/// 상단바(뒤로가기+코인) → 가로 숏컷(출석체크/성장미션/산책/꾸미기/제작소)
/// → 캐릭터 무대(플로팅 데코+탭 인터랙션) → 하단 고정 패널(레벨/경험치+액션 버튼).
/// 데이터/로직(코인, 스탯, 상점, 출석 보상 등)은 기존 백엔드 연동 그대로 사용.
class CharacterPage extends StatefulWidget {
  const CharacterPage({super.key, this.characterId});

  final int? characterId;

  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage>
    with TickerProviderStateMixin {
  int level = 1;
  int exp = 0;
  int _coins = 0;
  int maxExp = 100;
  int health = 80;
  int happiness = 80;
  int hunger = 50;

  String _petName = '';
  String _petType = 'DOG';
  String? _characterImageUrl;
  String? _groupName; // 강아지 그룹(Toy, Terrier...) 또는 고양이 그룹(Longhair, Shorthair, Hairless)
  String _roomBackgroundKey = 'room_sunrise';
  Set<String> _equippedDecorKeys = {};
  bool _attendanceClaimedToday = false;

  int? _characterId;
  List<DailyMissionModel> _missions = [];
  bool _missionsLoading = true;
  final Map<String, DateTime> _cooldownUntil = {};
  Timer? _cooldownTimer;

  bool _isInteracting = false;
  final List<_Particle> _particles = [];
  final _random = Random();
  String _currentAnimation = 'idle';

  // 활동별 배경 전환(놀아주기/밥주기/목욕하기/쓰다듬기) — 다른 활동을 누르기 전까지 유지
  _Scene _scene = _Scene.none;

  late final AnimationController _idleCtrl;
  late final AnimationController _interactCtrl;
  late final AnimationController _decorCtrl;
  late final Animation<double> _idleScale;
  late final Animation<double> _idleRotate;

  _InteractAnim _interactAnim = _InteractAnim.bounce;

  static const _activities = [
    _ActivityData(Icons.restaurant, '밥주기', 0, ChowCozy.stone500, '🍖'),
    _ActivityData(Icons.favorite, '쓰다듬기', 0, ChowColors.pink500, '💕'),
    _ActivityData(Icons.fitness_center, '운동하기', 50, Color(0xFF3B82F6), '💪'),
    _ActivityData(Icons.auto_awesome, '목욕시키기', 100, ChowColors.purple500, '✨'),
  ];

  @override
  void initState() {
    super.initState();
    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _idleScale = Tween<double>(
      begin: 1,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _idleCtrl, curve: Curves.easeInOut));
    _idleRotate = Tween<double>(
      begin: -0.035,
      end: 0.035,
    ).animate(CurvedAnimation(parent: _idleCtrl, curve: Curves.easeInOut));
    _interactCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _decorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _loadCharacter();
    _loadCoinBalance();
    _loadShopStyle();
    _claimDailyLogin();
    _loadDailyMissions();
    _cooldownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && _cooldownUntil.isNotEmpty) setState(() {});
    });
  }

  Future<void> _loadDailyMissions() async {
    try {
      final summary = await CharacterService.fetchDailyMissions();
      if (!mounted) return;
      setState(() {
        _missions = summary.missions;
        _missionsLoading = false;
        _coins = summary.balance;
      });
    } catch (_) {
      if (mounted) setState(() => _missionsLoading = false);
    }
  }

  Future<void> _loadActivityCooldowns(int characterId) async {
    try {
      final logs = await CharacterService.fetchGrowthLogs(characterId);
      final next = <String, DateTime>{};
      for (final type in ['FEED', 'PET']) {
        final matching = logs.where(
          (log) => log.activityType == type && log.createdAt != null,
        );
        if (matching.isEmpty) continue;
        final availableAt = matching.first.createdAt!
            .toLocal()
            .add(const Duration(hours: 3));
        if (availableAt.isAfter(DateTime.now())) next[type] = availableAt;
      }
      if (!mounted) return;
      setState(() {
        _cooldownUntil
          ..clear()
          ..addAll(next);
      });
    } catch (_) {}
  }

  String _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      if (_petType == 'CAT') {
        // 고양이는 groupName에 따라 기본 이미지 선택
        if (_groupName == 'Longhair') {
          return 'assets/images/characters/character_group_8.png';
        } else if (_groupName == 'Shorthair') {
          return 'assets/images/characters/character_group_9.png';
        } else if (_groupName == 'Hairless') {
          return 'assets/images/characters/character_group_10.png';
        } else {
          return 'assets/images/characters/character_group_8.png'; // 기본값
        }
      }
      return 'assets/images/characters/character_group_1.png';
    }
    // 파일명만 있는 경우 (예: "character_group_2")
    if (!url.contains('/') && url.contains('character_group')) {
      return 'assets/images/characters/$url.png';
    }
    return url;
  }

  int _getGroupNumber() {
    final groupMap = {
      'Toy': 1,
      'Terrier': 2,
      'Working': 3,
      'Herding': 4,
      'Hound': 5,
      'Sporting': 6,
      'Non-Sporting': 7,
    };
    return groupMap[_groupName] ?? 1;
  }

  String _getCatGroupName() {
    final catMap = {
      'Longhair': 'cat1_longhair',
      'Shorthair': 'cat2_shorthair',
      'Hairless': 'cat3_hairless',
    };
    return catMap[_groupName] ?? 'cat1_longhair';
  }

  /// 강아지/고양이 GIF 캔버스의 여백 비율이 서로 달라(강아지는 세로로 긴 캔버스에
  /// 여백이 많고, 고양이는 캔버스를 꽉 채움) 같은 프레임에 넣어도 고양이가 훨씬 커
  /// 보인다. 실측한 캐릭터 픽셀 비율을 기준으로 둘의 중간 크기로 보정한다.
  double get _speciesSizeScale => _petType == 'CAT' ? 0.8 : 1.35;

  String _getGifPath() {
    final anim = _currentAnimation;
    if (_petType == 'CAT') {
      final catGroup = _getCatGroupName();
      final path = 'assets/gifs/${catGroup}_$anim.gif';
      debugPrint(
        '🎯 [CharacterPage] CAT - group=$_groupName, catGroup=$catGroup, anim=$anim, path=$path',
      );
      return path;
    }
    final group = _getGroupNumber();
    final path = 'assets/gifs/group${group}_$anim.gif';
    debugPrint(
      '🎯 [CharacterPage] DOG - groupName=$_groupName, group=$group, anim=$anim, path=$path',
    );
    return path;
  }

  Widget _buildCharacterImage(String url) {
    final fallback = Text(
      _petType == 'CAT' ? '🐱' : '🐶',
      style: const TextStyle(fontSize: 165),
    );

    final resolvedUrl = _resolveImageUrl(url);

    // GIF 로드 시도
    return Image.asset(
      _getGifPath(),
      fit: BoxFit.contain,
      width: 380,
      height: 380,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ [CharacterPage] GIF 로드 실패: ${_getGifPath()} - $error');
        // GIF 실패 시 기존 이미지 로드
        if (resolvedUrl.startsWith('assets/')) {
          return Image.asset(
            resolvedUrl,
            fit: BoxFit.contain,
            width: 380,
            height: 380,
            errorBuilder: (_, _, _) => fallback,
          );
        } else {
          return Image.network(
            resolvedUrl,
            fit: BoxFit.contain,
            width: 380,
            height: 380,
            errorBuilder: (_, _, _) => fallback,
          );
        }
      },
    );
  }

  Future<void> _loadCharacter() async {
    try {
      if (widget.characterId != null) {
        // characterId로 캐릭터 직접 로드
        final c =
            await ApiClient.get('/api/characters/${widget.characterId}')
                as Map<String, dynamic>;
        debugPrint('📊 Character API 응답: $c');

        // petId로 pet 정보 조회해서 groupName 얻기
        String? groupName = c['groupName'] as String?;
        final petType = c['petType'] as String? ?? 'DOG';
        if (groupName == null && c['petId'] != null) {
          try {
            final pet =
                await ApiClient.get('/api/pets/${c['petId']}')
                    as Map<String, dynamic>;
            debugPrint('📊 Pet API 응답: $pet');
            groupName =
                pet['group_name'] as String? ?? pet['groupName'] as String?;
          } catch (e) {
            debugPrint('⚠️ Pet 조회 실패: $e');
          }
        }

        if (!mounted) return;
        setState(() {
          _characterId = (c['characterId'] as num?)?.toInt();
          _petName = c['characterName'] as String? ?? '';
          _petType = petType;
          _characterImageUrl = c['characterImageUrl'] as String?;
          _groupName = groupName;
          level = (c['characterLevel'] as num?)?.toInt() ?? 1;
          exp = (c['currentExp'] as num?)?.toInt() ?? 0;
          maxExp = (c['requiredExp'] as num?)?.toInt() ?? 100;
          health = (c['health'] as num?)?.toInt() ?? 80;
          happiness = (c['happiness'] as num?)?.toInt() ?? 80;
          hunger = (c['hunger'] as num?)?.toInt() ?? 50;
        });

        final characterId = _characterId;
        if (characterId != null) await _loadActivityCooldowns(characterId);

        debugPrint('🎯 [CharacterPage] Loaded: type=$petType, group=$groupName');
      } else {
        final res = await ApiClient.get('/api/characters') as List<dynamic>;
        if (res.isEmpty || !mounted) return;
        final c = res.first as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _characterId = (c['characterId'] as num?)?.toInt();
          _petName = c['characterName'] as String? ?? '';
          _petType = c['petType'] as String? ?? 'DOG';
          _characterImageUrl = c['characterImageUrl'] as String?;
          _groupName = c['groupName'] as String?;
          level = (c['characterLevel'] as num?)?.toInt() ?? 1;
          exp = (c['currentExp'] as num?)?.toInt() ?? 0;
          maxExp = (c['requiredExp'] as num?)?.toInt() ?? 100;
          health = (c['health'] as num?)?.toInt() ?? 80;
          happiness = (c['happiness'] as num?)?.toInt() ?? 80;
          hunger = (c['hunger'] as num?)?.toInt() ?? 50;
        });
        final characterId = _characterId;
        if (characterId != null) await _loadActivityCooldowns(characterId);
      }
    } catch (_) {}
  }

  Future<void> _loadCoinBalance() async {
    try {
      final res =
          await ApiClient.get('/api/coins/balance') as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _coins = (res['balance'] as num?)?.toInt() ?? 0);
    } catch (_) {}
  }

  Future<void> _loadShopStyle() async {
    try {
      final catalog = await ShopService.fetchCatalog();
      if (!mounted) return;
      _applyShopCatalog(catalog);
    } catch (_) {}
  }

  void _applyShopCatalog(ShopCatalogModel catalog) {
    setState(() {
      _coins = catalog.balance;
      _roomBackgroundKey = catalog.equippedBackgroundKey;
      _equippedDecorKeys = catalog.equippedDecorKeys;
    });
  }

  Future<void> _openCoinShop() async {
    await context.push('/coin-shop');
    if (!mounted) return;
    await _loadShopStyle();
  }

  /// "꾸미기" 숏컷 — 방 배경 테마 하나만 고를 수 있는 시트.
  void _openThemeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ThemeSheet(onChanged: _applyShopCatalog),
    );
  }

  Future<void> _openWalk() async {
    await context.push('/walk');
    if (!mounted) return;
    await Future.wait([_loadCoinBalance(), _loadDailyMissions()]);
  }

  Future<void> _openMissionSheet() async {
    setState(() => _missionsLoading = true);
    await _loadDailyMissions();
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          MissionSheet(missions: _missions, loading: _missionsLoading),
    );
  }

  void _openCraftSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const CraftSheet(),
    );
  }

  void _openAttendanceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AttendanceSheet(claimedToday: _attendanceClaimedToday),
    );
  }

  Future<void> _claimDailyLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final lastShown = prefs.getString('daily_login_shown');

    try {
      final res =
          await ApiClient.post('/api/coins/daily-login', {})
              as Map<String, dynamic>;
      if (!mounted) return;
      final newBalance = (res['balance'] as num?)?.toInt() ?? _coins;
      final reward = (res['reward'] as num?)?.toInt() ?? 0;
      setState(() {
        _coins = newBalance;
        _attendanceClaimedToday = true;
      });

      if (reward > 0 && lastShown != todayStr) {
        await prefs.setString('daily_login_shown', todayStr);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🪙 출석 보상 +$reward 코인!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _attendanceClaimedToday = lastShown == todayStr);
      }
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _idleCtrl.dispose();
    _interactCtrl.dispose();
    _decorCtrl.dispose();
    super.dispose();
  }

  /// 활동에 맞는 배경으로 전환한다. 다른 활동을 누르기 전까지 그대로 유지된다.
  void _switchScene(_Scene scene) {
    setState(() => _scene = scene);
  }

  double get _expFrac => exp / maxExp;

  ({double dy, double scale, double rotate}) _interactTransform(double t) {
    switch (_interactAnim) {
      case _InteractAnim.bounce:
        final y = t < 0.5 ? -40 * sin(t * pi) : -10 * (1 - t);
        return (
          dy: y,
          scale: 1 + 0.1 * sin(t * pi),
          rotate: 0.17 * sin(t * pi * 2),
        );
      case _InteractAnim.shake:
        return (dy: 0, scale: 1, rotate: 0);
      case _InteractAnim.scale:
        return (dy: 0, scale: 1 + 0.15 * sin(t * pi), rotate: 0);
      case _InteractAnim.wiggle:
        return (
          dy: -8 * sin(t * pi * 4),
          scale: 1,
          rotate: 0.12 * sin(t * pi * 4),
        );
    }
  }

  Future<void> _runInteract(
    _InteractAnim anim, {
    Duration? duration,
    VoidCallback? onDone,
  }) async {
    if (_isInteracting) return;
    setState(() => _isInteracting = true);
    _idleCtrl.stop();
    _interactAnim = anim;
    _interactCtrl.duration = duration ?? const Duration(milliseconds: 600);
    await _interactCtrl.forward(from: 0);
    onDone?.call();
    if (mounted) {
      setState(() => _isInteracting = false);
      _idleCtrl.repeat(reverse: true);
    }
  }

  Future<void> _handlePetClick() async {
    await _runInteract(
      _InteractAnim.bounce,
      onDone: () {
        _spawnParticles(['💕', '❤️', '💖', '✨'], count: 6);
        happiness = (happiness + 5).clamp(0, 100);
      },
    );
    setState(() {});
  }

  String _activityTypeFor(_ActivityData activity) => switch (activity.label) {
    '밥주기' => 'FEED',
    '쓰다듬기' => 'PET',
    '운동하기' => 'EXERCISE',
    '목욕시키기' => 'BATH',
    _ => throw StateError('지원하지 않는 활동입니다.'),
  };

  String? _cooldownLabel(String activityType) {
    final until = _cooldownUntil[activityType];
    if (until == null) return null;
    final remaining = until.difference(DateTime.now());
    if (remaining.isNegative) return null;
    final roundedMinutes = (remaining.inSeconds / 60).ceil();
    final hours = roundedMinutes ~/ 60;
    final minutes = roundedMinutes % 60;
    return hours > 0 ? '$hours시간 $minutes분' : '$minutes분';
  }

  Future<void> _handleActivity(_ActivityData activity) async {
    final characterId = _characterId;
    if (characterId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('캐릭터 정보를 불러온 뒤 다시 시도해주세요.')));
      return;
    }
    final activityType = _activityTypeFor(activity);
    final cooldown = _cooldownLabel(activityType);
    if (cooldown != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${activity.label}는 $cooldown 후 다시 할 수 있습니다.')),
      );
      return;
    }
    if (activity.cost > _coins) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('코인이 부족합니다. (보유: $_coins / 필요: ${activity.cost})'),
        ),
      );
      return;
    }

    final previousBalance = _coins;
    final previousLevel = level;

    String? gifAnimation;
    try {
      final updated = await CharacterService.performActivity(
        characterId,
        activityType,
      );

      // 성장미션 API는 백엔드 배포 이전 버전에는 없을 수 있다. 활동 처리와
      // 미션 새로고침을 분리해, 미션 조회 실패가 성공한 활동까지 실패로
      // 보이게 하지 않는다.
      DailyMissionSummaryModel? missionSummary;
      try {
        missionSummary = await CharacterService.fetchDailyMissions();
      } on ApiException catch (error) {
        debugPrint('⚠️ 성장미션 새로고침 실패 (${error.statusCode}): ${error.message}');
      }
      if (!mounted) return;
      setState(() {
        level = updated.level;
        exp = updated.exp;
        maxExp = updated.requiredExp;
        health = updated.health;
        happiness = updated.happiness;
        hunger = updated.hunger;
        if (missionSummary != null) {
          _coins = missionSummary.balance;
          _missions = missionSummary.missions;
        }
        if (activityType == 'FEED' || activityType == 'PET') {
          _cooldownUntil[activityType] = DateTime.now().add(
            const Duration(hours: 3),
          );
        }
      });

      switch (activity.label) {
        case '밥주기':
          gifAnimation = 'eating';
          _switchScene(_Scene.feed);
          await _runInteract(
            _InteractAnim.wiggle,
            duration: const Duration(milliseconds: 500),
          );
        case '쓰다듬기':
          gifAnimation = 'petting';
          _switchScene(_Scene.pet);
          await _runInteract(
            _InteractAnim.scale,
            duration: const Duration(milliseconds: 400),
          );
        case '운동하기':
          gifAnimation = 'exercise';
          _switchScene(_Scene.play);
          await _runInteract(
            _InteractAnim.shake,
            duration: const Duration(milliseconds: 1000),
          );
        case '목욕시키기':
          gifAnimation = 'bath';
          _switchScene(_Scene.bath);
          await _runInteract(
            _InteractAnim.wiggle,
            duration: const Duration(milliseconds: 800),
          );
      }

      final expectedAfterCost = previousBalance - activity.cost;
      final earnedCoins = missionSummary == null
          ? 0
          : missionSummary.balance - expectedAfterCost;
      if (earnedCoins > 0 && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('🎯 성장미션 완료! +$earnedCoins 코인')));
      }
      if (updated.level > previousLevel && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('🎉 레벨 업! Lv.${updated.level}')));
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      await _loadActivityCooldowns(characterId);
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('활동 처리에 실패했습니다.')));
      return;
    }

    // GIF 애니메이션 설정
    if (gifAnimation != null) {
      if (!mounted) return;
      setState(() => _currentAnimation = gifAnimation!);
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() => _currentAnimation = 'idle');
      }
    }

    if (!mounted) return;
    _spawnParticles([activity.emoji], count: 8);
  }

  void _spawnParticles(List<String> emojis, {required int count}) {
    if (!mounted) return;
    final batch = List<_Particle>.generate(count, (i) {
      return _Particle(
        id: DateTime.now().millisecondsSinceEpoch + i,
        emoji: emojis[_random.nextInt(emojis.length)],
        dx: _random.nextDouble() * 200 - 100,
        dy: _random.nextDouble() * 200 - 100,
      );
    });
    setState(() => _particles.addAll(batch));
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(
        () => _particles.removeWhere((p) => batch.any((b) => b.id == p.id)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomStyle = roomVisualFor(_roomBackgroundKey);
    final sceneAsset = _sceneAssetFor(_scene);
    // 구매/장착한 테마 이미지가 있으면, 밥주기/쓰다듬기 등 상호작용 중에도
    // 기본 씬 이미지로 바꾸지 않고 테마 배경을 그대로 유지한다.
    final hasThemeBg = roomStyle.imagePath != null;
    // 테마 미장착 상태(기본 방)라면 흰 배경 대신 항상 씬 이미지를 깔아준다.
    // 상호작용 전(_Scene.none)에는 scene_pet 사진이, 상호작용 중엔 해당 활동 사진이 뜬다.
    final showActivityScene = !hasThemeBg;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 기본 방 배경(코인 상점에서 고른 색상) — 항상 깔려 있고, 그 위를 테마/씬 이미지가 덮는다.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  roomStyle.wallColors.first,
                  roomStyle.wallColors.last,
                  roomStyle.floorColor,
                ],
              ),
            ),
          ),
          // 구매/장착한 테마 이미지(궁전/크리스마스/별빛 캠핑 등) — 상호작용 중에도 계속 유지된다.
          if (hasThemeBg)
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: 1,
                duration: const Duration(milliseconds: 400),
                child: Image.asset(
                  roomStyle.imagePath!,
                  key: ValueKey(roomStyle.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // 활동별 배경 — 테마 미장착 상태에서 밥주기/쓰다듬기/운동하기/목욕시키기 중일 때만 해당 씬으로 페이드 전환
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: showActivityScene ? 1 : 0,
              duration: const Duration(milliseconds: 550),
              curve: Curves.easeInOut,
              child: Image.asset(
                sceneAsset,
                key: ValueKey(sceneAsset),
                fit: BoxFit.cover,
                alignment: const Alignment(0, -2.2),
              ),
            ),
          ),
          // 씬 이미지 위 은은한 그림자 오버레이(상단 UI 가독성 유지)
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: showActivityScene ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.02),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildShortcuts(),
                Expanded(child: _buildCharacterStage(roomStyle)),
                _buildBottomPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.35),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: ChowCozy.stone900,
                ),
              ),
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _openCoinShop,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 5),
                    Text(
                      '$_coins',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ChowCozy.stone800,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 15,
                      color: ChowCozy.stone600,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcuts() {
    final shortcuts = [
      _ShortcutData(Icons.event_available, '출석체크', true, _openAttendanceSheet),
      _ShortcutData(Icons.track_changes, '성장미션', true, _openMissionSheet),
      _ShortcutData(Icons.directions_walk, '산책', false, _openWalk),
      _ShortcutData(Icons.auto_awesome, '꾸미기', false, _openThemeSheet),
      _ShortcutData(Icons.auto_fix_high, '제작소', false, _openCraftSheet),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 16.0;
        const spacing = 8.0;
        final side = ((constraints.maxWidth - (horizontalPadding * 2) -
                    (spacing * (shortcuts.length - 1))) /
                shortcuts.length)
            .clamp(0.0, 68.0)
            .toDouble();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < shortcuts.length; i++) ...[
                  SizedBox.square(
                    dimension: side,
                    child: _ShortcutChip(data: shortcuts[i]),
                  ),
                  if (i < shortcuts.length - 1) const SizedBox(width: spacing),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharacterStage(RoomVisualStyle roomStyle) {
    return LayoutBuilder(
      builder: (context, constraints) => _buildCharacterStageContent(
        roomStyle,
        constraints.maxWidth,
        constraints.maxHeight,
      ),
    );
  }

  Widget _buildCharacterStageContent(
    RoomVisualStyle roomStyle,
    double stageWidth,
    double stageHeight,
  ) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // 활동 중엔 씬 뱃지("🛁 목욕 중" 등), 아니면 방 이름(테마) 뱃지
        Positioned(
          top: 4,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(_sceneLabelFor(_scene) ?? roomStyle.label),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: _sceneLabelFor(_scene) != null
                  ? Text(
                      _sceneLabelFor(_scene)!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: ChowCozy.stone700,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_pin_circle_outlined,
                          size: 14,
                          color: ChowCozy.stone700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          roomStyle.label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: ChowCozy.stone700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),

        // 플로팅 데코
        AnimatedBuilder(
          animation: _decorCtrl,
          builder: (context, _) {
            final t = _decorCtrl.value * 2 * pi;
            return Stack(
              children: [
                _FloatingDeco(
                  '🌸',
                  top: 0.10,
                  left: 0.08,
                  dy: sin(t) * 10,
                  angle: sin(t) * 0.09,
                  width: stageWidth,
                  height: stageHeight,
                ),
                _FloatingDeco(
                  '🍖',
                  top: 0.12,
                  right: 0.10,
                  dy: sin(t + 1.4) * 12,
                  width: stageWidth,
                  height: stageHeight,
                ),
                _FloatingDeco(
                  '📚',
                  bottom: 0.20,
                  left: 0.06,
                  dy: sin(t + 2.3) * 8,
                  width: stageWidth,
                  height: stageHeight,
                ),
                _FloatingDeco(
                  '🎾',
                  bottom: 0.22,
                  right: 0.08,
                  dy: sin(t + 0.7) * 10,
                  angle: sin(t + 0.7) * 0.06,
                  width: stageWidth,
                  height: stageHeight,
                ),
              ],
            );
          },
        ),

        // 코인 상점에서 구매/장착한 방 소품
        if (_equippedDecorKeys.contains('decor_lamp'))
          _FloatingDeco(
            '💡',
            bottom: 0.06,
            left: 0.10,
            dy: 0,
            width: stageWidth,
            height: stageHeight,
          ),
        if (_equippedDecorKeys.contains('decor_plant'))
          _FloatingDeco(
            '🪴',
            bottom: 0.04,
            right: 0.08,
            dy: 0,
            width: stageWidth,
            height: stageHeight,
          ),
        if (_equippedDecorKeys.contains('decor_cushion'))
          _FloatingDeco(
            '🧸',
            bottom: 0.02,
            right: 0.32,
            dy: 0,
            width: stageWidth,
            height: stageHeight,
          ),

        // 캐릭터 — 배경(바닥선)에 맞춰 무대 중앙보다 살짝 아래에 배치.
        // 밥주기 씬에서는 밥그릇 쪽(우측 하단 대각선)으로 이동.
        AnimatedAlign(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          alignment: _scene == _Scene.feed
              ? const Alignment(0.55, 0.95)
              : const Alignment(0, 0.95),
          child: AnimatedBuilder(
            animation: Listenable.merge([_idleCtrl, _interactCtrl]),
            builder: (context, child) {
              final t = _interactCtrl.value;
              final usingInteract = _isInteracting || t > 0;
              final tr = usingInteract
                  ? _interactTransform(t)
                  : (
                      dy: 0.0,
                      scale: _idleScale.value,
                      rotate: _idleRotate.value,
                    );
              var dx = 0.0;
              if (usingInteract && _interactAnim == _InteractAnim.shake) {
                dx = 20 * sin(t * pi * 8);
              }
              return Transform.translate(
                offset: Offset(dx, tr.dy),
                child: Transform.rotate(
                  angle: tr.rotate,
                  child: Transform.scale(scale: tr.scale, child: child),
                ),
              );
            },
            child: GestureDetector(
              onTap: _handlePetClick,
              child: SizedBox(
                width: 380,
                height: 380,
                child: _characterImageUrl != null
                    ? Transform.scale(
                        scale: _speciesSizeScale,
                        child: _buildCharacterImage(_characterImageUrl!),
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: ChowCozy.stone500,
                        ),
                      ),
              ),
            ),
          ),
        ),

        ..._particles.map(_ParticleWidget.new),

        Positioned(
          bottom: 0,
          child: Text(
            '탭하면 행복도가 올라가요',
            style: TextStyle(
              fontSize: 12,
              color: ChowCozy.stone700.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, -8),
            color: Color(0x1F000000),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: ChowCozy.stone200,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: ChowCozy.stone600,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _petName.isNotEmpty ? _petName : '나의 반려동물',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: ChowCozy.stone900,
                            ),
                          ),
                          Text(
                            '경험치 $exp / $maxExp',
                            style: const TextStyle(
                              fontSize: 12,
                              color: ChowCozy.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          height: 10,
                          child: Stack(
                            children: [
                              Container(color: ChowCozy.stone100),
                              FractionallySizedBox(
                                widthFactor: _expFrac.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        ChowCozy.stone400,
                                        ChowCozy.stone700,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatRow(
                    icon: Icons.favorite,
                    iconColor: ChowColors.red500,
                    label: '건강',
                    value: health,
                    barColor: ChowColors.red500,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatRow(
                    icon: Icons.auto_awesome,
                    iconColor: ChowColors.yellow500,
                    label: '행복',
                    value: happiness,
                    barColor: ChowColors.yellow500,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatRow(
                    icon: Icons.restaurant,
                    iconColor: ChowCozy.stone600,
                    label: '배고픔',
                    value: hunger,
                    barColor: ChowCozy.stone600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: _activities
                  .map((a) {
                    final type = _activityTypeFor(a);
                    final cooldown = _cooldownLabel(type);
                    final usesCooldown = type == 'FEED' || type == 'PET';
                    return Expanded(
                      child: _ActionButton(
                        activity: a,
                        statusLabel: usesCooldown
                            ? (cooldown ?? '3시간마다')
                            : null,
                        enabled: cooldown == null && !_isInteracting,
                        onTap: () => _handleActivity(a),
                      ),
                    );
                  })
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutData {
  const _ShortcutData(this.icon, this.label, this.badge, this.onTap);
  final IconData icon;
  final String label;
  final bool badge;
  final VoidCallback onTap;
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({required this.data});
  final _ShortcutData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: data.onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(data.icon, size: 20, color: ChowCozy.stone700),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      data.label,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: ChowCozy.stone800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (data.badge)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: ChowColors.red500,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '!',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FloatingDeco extends StatelessWidget {
  const _FloatingDeco(
    this.emoji, {
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.dy,
    this.angle = 0,
    required this.width,
    required this.height,
  });

  final String emoji;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double dy;
  final double angle;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top == null ? null : height * top!,
      bottom: bottom == null ? null : height * bottom!,
      left: left == null ? null : width * left!,
      right: right == null ? null : width * right!,
      child: IgnorePointer(
        child: Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: angle,
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
        ),
      ),
    );
  }
}

enum _InteractAnim { bounce, shake, scale, wiggle }

/// 기본 및 활동별 전환 배경.
enum _Scene { none, play, feed, bath, pet }

String _sceneAssetFor(_Scene scene) => switch (scene) {
  _Scene.play => 'assets/images/scenes/scene_play.png',
  _Scene.feed => 'assets/images/scenes/scene_feed.png',
  _Scene.bath => 'assets/images/scenes/scene_bath.png',
  _Scene.pet => 'assets/images/scenes/scene_pet.png',
  _Scene.none => 'assets/images/scenes/scene_pet.png',
};

String? _sceneLabelFor(_Scene scene) => switch (scene) {
  _Scene.play => '🛝 놀이터',
  _Scene.feed => '🍽️ 식사 시간',
  _Scene.bath => '🛁 목욕 중',
  _Scene.pet => '🏠 아늑한 시간',
  _Scene.none => null,
};

class _ActivityData {
  const _ActivityData(this.icon, this.label, this.cost, this.color, this.emoji);
  final IconData icon;
  final String label;
  final int cost;
  final Color color;
  final String emoji;
}

class _Particle {
  _Particle({
    required this.id,
    required this.emoji,
    required this.dx,
    required this.dy,
  });
  final int id;
  final String emoji;
  final double dx;
  final double dy;
}

class _ParticleWidget extends StatefulWidget {
  const _ParticleWidget(this.particle);
  final _Particle particle;

  @override
  State<_ParticleWidget> createState() => _ParticleWidgetState();
}

class _ParticleWidgetState extends State<_ParticleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_ctrl.value);
        final scale = t < 0.5 ? t * 3 : (1 - t) * 3;
        return Transform.translate(
          offset: Offset(widget.particle.dx * t, widget.particle.dy * t),
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Transform.scale(scale: scale.clamp(0.0, 1.5), child: child),
          ),
        );
      },
      child: Text(widget.particle.emoji, style: const TextStyle(fontSize: 24)),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.barColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final int value;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: ChowCozy.mutedForeground,
              ),
            ),
            const Spacer(),
            Text(
              '$value%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: ChowCozy.stone800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 5,
            child: Stack(
              children: [
                Container(color: ChowCozy.stone100),
                FractionallySizedBox(
                  widthFactor: (value / 100).clamp(0.0, 1.0),
                  child: Container(color: barColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.activity,
    required this.onTap,
    required this.enabled,
    this.statusLabel,
  });
  final _ActivityData activity;
  final VoidCallback onTap;
  final bool enabled;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: enabled ? ChowCozy.stone50 : ChowCozy.stone100,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(activity.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  activity.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: ChowCozy.stone800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  statusLabel ?? (activity.cost > 0 ? '🪙-${activity.cost}' : '무료'),
                  style: TextStyle(
                    fontSize: 10,
                    color: !enabled
                        ? ChowCozy.stone500
                        : statusLabel != null
                            ? ChowColors.green500
                            : activity.cost > 0
                                ? ChowCozy.mutedForeground
                                : ChowColors.green500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
