import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/chow_theme.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool pushEnabled = true;
  bool newRecipe = true;
  bool communityReply = true;
  bool communityLike = true;
  bool aiChatResponse = true;

  bool emailEnabled = true;
  bool weeklyDigest = true;
  bool promotions = false;
  bool updates = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChowColors.gray50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    _buildSection(
                      title: '푸시 알림',
                      subtitle: '앱에서 실시간으로 받는 알림',
                      value: pushEnabled,
                      onChanged: (value) {
                        setState(() {
                          pushEnabled = value;
                        });
                      },
                      children: pushEnabled
                          ? [
                              _buildNotificationRow(
                                icon: Icons.menu_book_outlined,
                                iconColor: ChowColors.orange500,
                                iconBgColor: ChowColors.orange50,
                                title: '새로운 레시피 추천',
                                subtitle: '맞춤 레시피가 추가되면 알려드려요',
                                value: newRecipe,
                                onChanged: (value) {
                                  setState(() {
                                    newRecipe = value;
                                  });
                                },
                              ),
                              _buildNotificationRow(
                                icon: Icons.chat_bubble_outline,
                                iconColor: ChowColors.orange500,
                                iconBgColor: ChowColors.orange50,
                                title: '댓글 알림',
                                subtitle: '내 게시물에 댓글이 달렸을 때',
                                value: communityReply,
                                onChanged: (value) {
                                  setState(() {
                                    communityReply = value;
                                  });
                                },
                              ),
                              _buildNotificationRow(
                                icon: Icons.favorite_border,
                                iconColor: ChowColors.orange500,
                                iconBgColor: ChowColors.orange50,
                                title: '좋아요 알림',
                                subtitle: '내 게시물을 누군가 좋아할 때',
                                value: communityLike,
                                onChanged: (value) {
                                  setState(() {
                                    communityLike = value;
                                  });
                                },
                              ),
                              _buildNotificationRow(
                                icon: Icons.notifications_none,
                                iconColor: ChowColors.orange500,
                                iconBgColor: ChowColors.orange50,
                                title: 'AI 응답 알림',
                                subtitle: 'AI가 답변을 완료했을 때',
                                value: aiChatResponse,
                                onChanged: (value) {
                                  setState(() {
                                    aiChatResponse = value;
                                  });
                                },
                              ),
                            ]
                          : [],
                    ),

                    const SizedBox(height: 12),

                    _buildSection(
                      title: '이메일 알림',
                      subtitle: '이메일로 받는 소식',
                      value: emailEnabled,
                      onChanged: (value) {
                        setState(() {
                          emailEnabled = value;
                        });
                      },
                      children: emailEnabled
                          ? [
                              _buildNotificationRow(
                                icon: Icons.mail_outline,
                                iconColor: ChowColors.blue500,
                                iconBgColor: const Color(0xFFEFF6FF),
                                title: '주간 요약',
                                subtitle: '일주일간의 레시피와 활동 요약',
                                value: weeklyDigest,
                                onChanged: (value) {
                                  setState(() {
                                    weeklyDigest = value;
                                  });
                                },
                              ),
                              _buildNotificationRow(
                                icon: Icons.mail_outline,
                                iconColor: ChowColors.blue500,
                                iconBgColor: const Color(0xFFEFF6FF),
                                title: '프로모션 및 혜택',
                                subtitle: '특별 이벤트와 할인 정보',
                                value: promotions,
                                onChanged: (value) {
                                  setState(() {
                                    promotions = value;
                                  });
                                },
                              ),
                              _buildNotificationRow(
                                icon: Icons.mail_outline,
                                iconColor: ChowColors.blue500,
                                iconBgColor: const Color(0xFFEFF6FF),
                                title: '업데이트 소식',
                                subtitle: '새로운 기능 및 개선 사항',
                                value: updates,
                                onChanged: (value) {
                                  setState(() {
                                    updates = value;
                                  });
                                },
                              ),
                            ]
                          : [],
                    ),

                    const SizedBox(height: 12),

                    _buildInfoBox(),

                    const SizedBox(height: 24),
                  ],
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
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
            icon: const Icon(
              Icons.arrow_back,
              color: ChowColors.gray700,
              size: 24,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '알림 설정',
                style: TextStyle(
                  color: ChowColors.gray900,
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ChowColors.gray900,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: ChowColors.gray500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _OrangeSwitch(
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(
              height: 1,
              thickness: 1,
              color: ChowColors.gray100,
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ChowColors.gray800,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: ChowColors.gray500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _OrangeSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 알림 권한 안내',
            style: TextStyle(
              color: Color(0xFF1E40AF),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 7),
          Text(
            '푸시 알림을 받으려면 기기의 설정에서 알림 권한을 허용해주세요. 설정 앱에서 언제든지 변경할 수 있습니다.',
            style: TextStyle(
              color: Color(0xFF1D4ED8),
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrangeSwitch extends StatelessWidget {
  const _OrangeSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.82,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: const Color(0xFFFF6B00),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: const Color(0xFFD1D5DB),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}