import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoticesPage extends StatefulWidget {
  const NoticesPage({super.key});

  @override
  State<NoticesPage> createState() => _NoticesPageState();
}

class _NoticesPageState extends State<NoticesPage> {
  int? _expandedNoticeId;
  Set<int> _readIds = {};

  static const _prefsKey = 'read_notice_ids';

  @override
  void initState() {
    super.initState();
    _loadReadState();
  }

  Future<void> _loadReadState() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey) ?? [];
    if (!mounted) return;
    setState(() => _readIds = saved.map(int.parse).toSet());
  }

  Future<void> _saveReadState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _readIds.map((id) => id.toString()).toList());
  }

  final List<_NoticeItem> _notices = const [
    _NoticeItem(
      id: 1,
      type: 'important',
      title: '서비스 점검 안내',
      date: '2026.05.28',
      isNew: true,
      preview: '보다 나은 서비스 제공을 위한 시스템 점검이 진행됩니다.',
      content: '''안녕하세요, 펫푸드 레시피입니다.

보다 안정적인 서비스 제공을 위해 시스템 점검을 진행하고자 합니다.

▶ 점검 일시: 2026년 5월 30일 (금) 02:00 ~ 06:00 (4시간)
▶ 점검 내용: 서버 안정화 및 신규 기능 업데이트
▶ 영향 범위: 전체 서비스 이용 불가

점검 시간 동안 서비스 이용이 일시적으로 중단되는 점 양해 부탁드립니다.

감사합니다.''',
    ),
    _NoticeItem(
      id: 2,
      type: 'event',
      title: '신규 회원 가입 이벤트',
      date: '2026.05.25',
      isNew: true,
      preview: '지금 가입하고 프리미엄 레시피를 무료로 받아보세요!',
      content: '''🎉 신규 회원 가입 이벤트 🎉

펫푸드 레시피에 가입하고 특별한 혜택을 받아가세요!

▶ 이벤트 기간: 2026년 5월 25일 ~ 6월 25일
▶ 이벤트 내용:
  - 신규 가입 시 프리미엄 레시피 3개 무료 제공
  - 첫 레시피 생성 시 추가 포인트 1,000P 지급
  - 친구 추천 시 추천인/피추천인 모두 500P 적립

이 기회를 놓치지 마세요!''',
    ),
    _NoticeItem(
      id: 3,
      type: 'update',
      title: 'AI 레시피 생성 기능 개선',
      date: '2026.05.20',
      isNew: false,
      preview: '더욱 정확하고 다양한 레시피를 생성할 수 있게 되었습니다.',
      content: '''AI 레시피 생성 기능이 업데이트 되었습니다!

▶ 주요 개선 사항:
  - 알러지 정보 반영 정확도 향상
  - 반려동물 연령별 맞춤 레시피 추천 기능 추가
  - 계절별 제철 재료 추천 기능 신설
  - 레시피 생성 속도 30% 개선

더욱 정확하고 맛있는 레시피로 우리 아이를 위한 건강한 식단을 만들어보세요!''',
    ),
    _NoticeItem(
      id: 4,
      type: 'notice',
      title: '개인정보 처리방침 변경 안내',
      date: '2026.05.15',
      isNew: false,
      preview: '개인정보 처리방침이 일부 변경되었습니다.',
      content: '''개인정보 처리방침 변경 안내

관련 법령의 개정에 따라 개인정보 처리방침이 일부 변경되었습니다.

▶ 변경 일자: 2026년 5월 15일
▶ 시행 일자: 2026년 5월 22일

▶ 주요 변경 내용:
  - 개인정보 보유 기간 명시
  - 제3자 제공 관련 항목 추가
  - 이용자 권리 및 행사 방법 구체화

자세한 내용은 앱 하단의 '개인정보처리방침'에서 확인하실 수 있습니다.''',
    ),
    _NoticeItem(
      id: 5,
      type: 'event',
      title: '리뷰 작성 이벤트',
      date: '2026.05.10',
      isNew: false,
      preview: '레시피 리뷰를 남기고 포인트를 받아가세요!',
      content: '''📝 리뷰 작성 이벤트

레시피를 이용하고 소중한 리뷰를 남겨주세요!

▶ 이벤트 기간: 2026년 5월 10일 ~ 6월 10일
▶ 참여 방법:
  1. 레시피를 조리해보세요
  2. 사진과 함께 리뷰를 작성해주세요
  3. 자동으로 포인트가 적립됩니다!

▶ 혜택:
  - 텍스트 리뷰: 100P
  - 사진 포함 리뷰: 300P
  - 베스트 리뷰 선정 시: 추가 1,000P

여러분의 소중한 의견을 기다립니다!''',
    ),
    _NoticeItem(
      id: 6,
      type: 'update',
      title: '커뮤니티 기능 오픈',
      date: '2026.05.05',
      isNew: false,
      preview: '다른 반려동물 보호자들과 소통할 수 있는 공간이 열렸습니다.',
      content: '''🎊 커뮤니티 기능 오픈!

반려동물을 사랑하는 분들과 함께 소통하는 공간이 마련되었습니다.

▶ 주요 기능:
  - 레시피 공유 및 추천
  - 질문과 답변
  - 반려동물 사진 공유
  - 육아 팁 교환

▶ 커뮤니티 이용 규칙:
  - 서로를 존중하는 대화
  - 상업적 광고 금지
  - 건전한 콘텐츠 공유

많은 참여 부탁드립니다!''',
    ),
  ];

  void _toggleNotice(int noticeId) {
    setState(() {
      _expandedNoticeId = _expandedNoticeId == noticeId ? null : noticeId;
      _readIds.add(noticeId);
    });
    _saveReadState();
  }

  bool _isNew(_NoticeItem notice) =>
      notice.isNew && !_readIds.contains(notice.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: _notices.isEmpty
                      ? _buildEmptyState()
                      : CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: _buildNoticeCount(),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final notice = _notices[index];

                                  return _NoticeTile(
                                    notice: notice,
                                    isExpanded: _expandedNoticeId == notice.id,
                                    isNew: _isNew(notice),
                                    onTap: () => _toggleNotice(notice.id),
                                  );
                                },
                                childCount: _notices.length,
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 32),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _HeaderBackButton(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
          ),
          const Expanded(
            child: Center(
              child: Text(
                '공지사항',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildNoticeCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.25,
          ),
          children: [
            const TextSpan(text: '총 '),
            TextSpan(
              text: '${_notices.length}',
              style: const TextStyle(
                color: Color(0xFFF97316),
                fontWeight: FontWeight.w500,
              ),
            ),
            const TextSpan(text: '개의 공지사항'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none,
                  size: 32,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '등록된 공지사항이 없습니다',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '새로운 소식이 있으면 알려드릴게요',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({
    required this.notice,
    required this.isExpanded,
    required this.isNew,
    required this.onTap,
  });

  final _NoticeItem notice;
  final bool isExpanded;
  final bool isNew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _NoticeTypeStyle.fromType(notice.type);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            child: InkWell(
              onTap: onTap,
              splashColor: const Color(0xFFF9FAFB),
              highlightColor: const Color(0xFFF9FAFB),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NoticeIcon(style: style, type: notice.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NoticeTextContent(
                        notice: notice,
                        style: style,
                        isNew: isNew,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: style.bg,
                border: const Border(
                  top: BorderSide(
                    color: Color(0xFFF3F4F6),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              child: Text(
                notice.content,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOut,
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeOut,
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF3F4F6),
          ),
        ],
      ),
    );
  }
}

class _NoticeTextContent extends StatelessWidget {
  const _NoticeTextContent({
    required this.notice,
    required this.style,
    required this.isNew,
  });

  final _NoticeItem notice;
  final _NoticeTypeStyle style;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Badge(
              text: _noticeTypeLabel(notice.type),
              color: style.badge,
              minWidth: _categoryBadgeMinWidth(notice.type),
            ),
            if (isNew) ...[
              const SizedBox(width: 6),
              const _Badge(
                text: 'NEW',
                color: Color(0xFFF97316),
                minWidth: 36,
              ),
            ],
            const SizedBox(width: 8),
            Text(
              notice.date,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          notice.title,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.28,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          notice.preview,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _NoticeIcon extends StatelessWidget {
  const _NoticeIcon({
    required this.style,
    required this.type,
  });

  final _NoticeTypeStyle style;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: style.iconBg,
        shape: BoxShape.circle,
      ),
      child: Icon(
        _noticeIcon(type),
        color: style.iconColor,
        size: 20,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.color,
    this.minWidth,
  });

  final String text;
  final Color color;
  final double? minWidth;

  static const _height = 20.0;
  static const _hPadding = 6.0;
  static const _radius = 4.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      constraints: BoxConstraints(minWidth: minWidth ?? 0),
      padding: const EdgeInsets.symmetric(horizontal: _hPadding),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1.0,
          letterSpacing: -0.2,
        ),
        strutStyle: const StrutStyle(
          fontSize: 11,
          height: 1.0,
          forceStrutHeight: true,
          leading: 0,
        ),
      ),
    );
  }
}

double _categoryBadgeMinWidth(String type) {
  switch (type) {
    case 'important':
      return 36;
    case 'event':
      return 44;
    case 'update':
      return 56;
    default:
      return 36;
  }
}

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back,
            color: Color(0xFF374151),
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _NoticeItem {
  const _NoticeItem({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    required this.isNew,
    required this.preview,
    required this.content,
  });

  final int id;
  final String type;
  final String title;
  final String date;
  final bool isNew;
  final String preview;
  final String content;
}

class _NoticeTypeStyle {
  const _NoticeTypeStyle({
    required this.bg,
    required this.iconBg,
    required this.iconColor,
    required this.badge,
  });

  final Color bg;
  final Color iconBg;
  final Color iconColor;
  final Color badge;

  factory _NoticeTypeStyle.fromType(String type) {
    switch (type) {
      case 'important':
        return const _NoticeTypeStyle(
          bg: Color(0xFFFEF2F2),
          iconBg: Color(0xFFFEE2E2),
          iconColor: Color(0xFFDC2626),
          badge: Color(0xFFEF4444),
        );
      case 'event':
        return const _NoticeTypeStyle(
          bg: Color(0xFFFAF5FF),
          iconBg: Color(0xFFF3E8FF),
          iconColor: Color(0xFF9333EA),
          badge: Color(0xFFA855F7),
        );
      case 'update':
        return const _NoticeTypeStyle(
          bg: Color(0xFFEFF6FF),
          iconBg: Color(0xFFDBEAFE),
          iconColor: Color(0xFF2563EB),
          badge: Color(0xFF3B82F6),
        );
      default:
        return const _NoticeTypeStyle(
          bg: Color(0xFFF9FAFB),
          iconBg: Color(0xFFF3F4F6),
          iconColor: Color(0xFF4B5563),
          badge: Color(0xFF6B7280),
        );
    }
  }
}

IconData _noticeIcon(String type) {
  switch (type) {
    case 'important':
      return Icons.error_outline;
    case 'event':
      return Icons.card_giftcard;
    case 'update':
      return Icons.campaign_outlined;
    default:
      return Icons.notifications_none;
  }
}

String _noticeTypeLabel(String type) {
  switch (type) {
    case 'important':
      return '중요';
    case 'event':
      return '이벤트';
    case 'update':
      return '업데이트';
    default:
      return '공지';
  }
}
