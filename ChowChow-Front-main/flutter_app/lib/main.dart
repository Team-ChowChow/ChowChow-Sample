import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'services/api_client.dart';

void main() {
  runApp(const PetFoodApp());
}

class PetFoodApp extends StatelessWidget {
  const PetFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '펫푸드 레시피',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF7A00)),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        useMaterial3: true,
      ),
      home: const LoginPage(), //첫페이지는 로그인 페이지로 설정해둠
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool showPassword = false;
  bool autoLogin = false;

  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> handleLogin() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await ApiClient.post(
        '/api/auth/login',
        {'email': idController.text.trim(), 'password': passwordController.text},
        auth: false,
      );
      final token = res['accessToken'] as String?;
      if (token != null) await ApiClient.saveToken(token);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.statusCode == 401 ? '아이디 또는 비밀번호가 올바르지 않습니다.' : '로그인에 실패했습니다.');
    } catch (_) {
      setState(() => _errorMessage = '서버에 연결할 수 없습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void handleGoogleLogin() {
    debugPrint('Google Login');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
  }

  void handleKakaoLogin() {
    debugPrint('Kakao Login');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF7ED),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),

                          // Logo & Title
                          Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFB923C),
                                      Color(0xFFF97316),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x22000000),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/paw.png',
                                    width: 40,
                                    height: 40,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '펫푸드 레시피',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF97316),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '우리 아이를 위한 건강한 식단',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 36),

                          // ID
                          const Text(
                            '아이디',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: idController,
                            decoration: InputDecoration(
                              hintText: '아이디를 입력하세요',
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFF97316),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Password
                          const Text(
                            '비밀번호',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: passwordController,
                            obscureText: !showPassword,
                            decoration: InputDecoration(
                              hintText: '비밀번호를 입력하세요',
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    showPassword = !showPassword;
                                  });
                                },
                                icon: Icon(
                                  showPassword ? Icons.visibility_off : Icons.visibility,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFF97316),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Auto login
                          Row(
                            children: [
                              Checkbox(
                                value: autoLogin,
                                activeColor: const Color(0xFFF97316),
                                onChanged: (value) {
                                  setState(() {
                                    autoLogin = value ?? false;
                                  });
                                },
                              ),
                              const Text(
                                '자동 로그인',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Login button
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFF97316),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _isLoading ? null : handleLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      '로그인',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Find ID / Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const FindIdPage()),
                                  );
                                },
                                child: const Text(
                                  '아이디 찾기',
                                  style: TextStyle(color: Color(0xFF4B5563)),
                                ),
                              ),
                              const Text(
                                '|',
                                style: TextStyle(color: Color(0xFFD1D5DB)),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  '비밀번호 찾기',
                                  style: TextStyle(color: Color(0xFF4B5563)),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Divider
                          const Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Color(0xFFD1D5DB),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '또는',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Color(0xFFD1D5DB),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Google login
                          SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFFD1D5DB)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: handleGoogleLogin,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.g_mobiledata, size: 26, color: Colors.black87),
                                  SizedBox(width: 6),
                                  Text(
                                    'Google로 로그인',
                                    style: TextStyle(
                                      color: Color(0xFF374151),
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Kakao login
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFEE500),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: handleKakaoLogin,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble, size: 18, color: Colors.black),
                                  SizedBox(width: 8),
                                  Text(
                                    '카카오로 로그인',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Sign up
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '아직 회원이 아니신가요? ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const SignupPage()),
                                  );
                                },
                                child: const Text(
                                  '회원가입',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFF97316),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  '© 2026 펫푸드 레시피. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int index = 0;

  final List<Widget> pages = const [
    HomePage(),
    SearchPage(),
    CharacterPage(),
    CommunityPage(),
    ProfilePage(),
  ];

  void changeTab(int newIndex) {
    setState(() {
      index = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: pages[index]),
      extendBody: true,

      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          elevation: 4,
          backgroundColor: const Color(0xFFF28C28),
          shape: const CircleBorder(),
          onPressed: () => changeTab(2),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: index == 2 ? const Color(0xFFD96F00) : const Color(0xFFF28C28),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                'assets/images/paw.png',
                width: 40,
                height: 40,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: const Color(0xFFF6E7DE),
        elevation: 12,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomTabItem(
                icon: Icons.home_filled,
                label: '홈',
                selected: index == 0,
                onTap: () => changeTab(0),
              ),
              _BottomTabItem(
                icon: Icons.search,
                label: '검색',
                selected: index == 1,
                onTap: () => changeTab(1),
              ),
              const SizedBox(width: 56), // 가운데 발바닥 버튼 자리
              _BottomTabItem(
                icon: Icons.groups_outlined,
                label: '커뮤니티',
                selected: index == 3,
                onTap: () => changeTab(3),
              ),
              _BottomTabItem(
                icon: Icons.person_outline,
                label: '프로필',
                selected: index == 4,
                onTap: () => changeTab(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int currentPage = 0;

  List<Map<String, dynamic>> trendingRecipes = [];
  List<Map<String, dynamic>> mealPhotos = [];
  bool _mealLoading = false;

  String _tipText = '오늘의 건강 팁을 불러오는 중...';
  String _tipDetail = '';
  bool _tipLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
    _fetchTip();
    _fetchMealRecords();
    _autoSlide();
  }

  Future<void> _fetchMealRecords() async {
    setState(() => _mealLoading = true);
    try {
      final res = await ApiClient.get('/api/meal-records');
      final List<dynamic> items = res is List ? (res as List<dynamic>) : ((res as Map)['data'] as List? ?? []);
      if (!mounted) return;
      setState(() {
        mealPhotos = items.take(4).map<Map<String, dynamic>>((m) => {
          'mealId': m['mealId'],
          'image': m['imageUrl'] ?? '',
          'title': m['mealTitle'] ?? '',
          'date': () { final d = m['mealDate'] as String? ?? (m['createdAt'] as String? ?? ''); return d.length >= 10 ? d.substring(0, 10) : d; }(),
          'petName': m['petName'] ?? '',
        }).toList();
        _mealLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _mealLoading = false);
    }
  }

  Future<void> _fetchTip() async {
    try {
      final res = await ApiClient.get('/api/llm/tip', timeout: const Duration(seconds: 12));
      if (!mounted) return;
      setState(() {
        _tipText = (res['tip'] as String?) ?? _tipText;
        _tipDetail = (res['detail'] as String?) ?? '';
        _tipLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tipText = '반려동물에게 신선한 물을 매일 충분히 제공하세요.';
        _tipDetail = '물은 반려동물의 소화, 체온 조절, 신진대사에 필수적입니다.';
        _tipLoading = false;
      });
    }
  }

  Future<void> _fetchRecipes() async {
    try {
      final res = await ApiClient.get('/api/v1/recipes?size=8');
      final List<dynamic> items = (res['data'] as List?) ?? [];
      final List<Map<String, dynamic>> fetched = items.map((r) {
        final createdAt = (r['createdAt'] as String? ?? '').replaceAll('-', '.').substring(0, 10 < (r['createdAt'] as String? ?? '').length ? 10 : (r['createdAt'] as String? ?? '').length);
        return {
          'id': r['recipeId'],
          'image': r['imageUrl'] ?? '',
          'title': r['recipeTitle'] ?? '',
          'tags': r['recipePurpose'] != null ? ['#${r['recipePurpose']}'] : <String>[],
          'date': createdAt,
          'likes': 0,
        };
      }).toList();
      if (!mounted) return;
      setState(() {
        trendingRecipes = fetched.take(4).toList();
      });
    } catch (_) {
      // 서버 미연결 시 빈 목록 유지
    }
  }

  void _autoSlide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || !_pageController.hasClients || trendingRecipes.isEmpty) return;
      final nextPage = (currentPage + 1) % trendingRecipes.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      if (mounted) setState(() => currentPage = nextPage);
      _autoSlide();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '펫푸드 레시피',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF97316),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFACC15),
                            Color(0xFFEAB308),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.white,
                            child: Text(
                              'C',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFEAB308),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '1,250',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Stack(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.notifications_none,
                            color: Color(0xFF374151),
                            size: 28,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF97316),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Trending recipes
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text(
              '트렌드 레시피',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          SizedBox(
            height: 240,
            child: PageView.builder(
              controller: _pageController,
              itemCount: trendingRecipes.length,
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final recipe = trendingRecipes[index];
                final tags = recipe['tags'] as List<dynamic>;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          (recipe['image'] as String?)?.isNotEmpty == true
                              ? Image.network(
                                  recipe['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFE5E7EB),
                                    child: const Center(
                                      child: Icon(Icons.restaurant, size: 48, color: Color(0xFF9CA3AF)),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: const Color(0xFFE5E7EB),
                                  child: const Center(
                                    child: Icon(Icons.restaurant, size: 48, color: Color(0xFF9CA3AF)),
                                  ),
                                ),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Color(0xB3000000),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe['title'],
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: tags.map((tag) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        tag.toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(trendingRecipes.length, (index) {
              final selected = currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: selected ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFF97316)
                      : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),

          const SizedBox(height: 18),

          // AI section
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DietGeneratePage()),
              );
            },
            child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFB923C),
                  Color(0xFFF97316),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0x33FFFFFF),
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'AI 셰프',
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        '우리 아이 맞춤 식단을\nAI가 추천해드려요',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '반려동물의 건강 상태, 알러지, 선호도를 고려한 맞춤 레시피',
                        style: TextStyle(
                          color: Color(0xFFFDEFE7),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 16),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          child: Text(
                            'AI 상담 시작하기',
                            style: TextStyle(
                              color: Color(0xFFF97316),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 58,
                  color: Color(0x55FFFFFF),
                ),
              ],
            ),
          ),
          ),

          const SizedBox(height: 26),

          // Meal records
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '나의 식단 기록',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    '전체보기',
                    style: TextStyle(color: Color(0xFFF97316)),
                  ),
                ),
              ],
            ),
          ),

          if (_mealLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (mealPhotos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.photo_library_outlined, size: 36, color: Color(0xFF9CA3AF)),
                    SizedBox(height: 8),
                    Text('아직 기록된 식단이 없어요', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mealPhotos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, index) {
                  final meal = mealPhotos[index];
                  final hasImage = (meal['image'] as String?)?.isNotEmpty ?? false;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: hasImage
                                ? Image.network(
                                    meal['image'],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFFF3F4F6),
                                      child: const Icon(Icons.image_not_supported, color: Color(0xFF9CA3AF)),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFFF3F4F6),
                                    child: const Center(
                                      child: Icon(Icons.restaurant, size: 32, color: Color(0xFF9CA3AF)),
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meal['title'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1F2937),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  meal['date'],
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(
                  color: Color(0xFFD1D5DB),
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MealAddPage()),
                );
                _fetchMealRecords();
              },
              child: const Column(
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 32,
                    color: Color(0xFF9CA3AF),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '식단 사진 추가하기',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 28, 16, 12),
            child: Text(
              '오늘의 팁',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ),

          GestureDetector(
            onTap: _tipLoading || _tipDetail.isEmpty
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TipDetailPage(
                          tip: _tipText,
                          detail: _tipDetail,
                        ),
                      ),
                    ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 건강 정보',
                    style: TextStyle(fontSize: 13, color: Color(0xFFE0E7FF)),
                  ),
                  const SizedBox(height: 10),
                  _tipLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _tipText,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                  const SizedBox(height: 12),
                  if (!_tipLoading && _tipDetail.isNotEmpty)
                    const Text(
                      '더 알아보기 →',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFE0E7FF),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFE0E7FF),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  final bool standalone;
  const SearchPage({super.key, this.standalone = false});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  bool isSearchFocused = false;
  bool isLoadingSuggestions = false;
  String? suggestionError;
  List<String> suggestions = [];

  Timer? _debounce;

  List<Map<String, dynamic>> popularSearches = [];

  final List<String> popularCategories = [
    '#트렌드',
    '#저지방',
    '#알러지프리',
    '#시니어',
    '#퍼피/키튼',
    '#다이어트',
    '#치아건강',
    '#면역력',
  ];

  List<Map<String, dynamic>> recipes = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final results = await Future.wait([
        ApiClient.get('/api/v1/search/popular'),
        ApiClient.get('/api/v1/recipes?size=10'),
      ]);

      final popularRaw = results[0]['popular'] as List? ?? [];
      final recipeRaw = results[1]['data'] as List? ?? [];

      if (!mounted) return;
      setState(() {
        popularSearches = List<Map<String, dynamic>>.from(
          popularRaw.asMap().entries.map((e) => {
            'rank': e.key + 1,
            'term': e.value['searchKeyword'] ?? e.value.toString(),
            'isNew': false,
          }),
        );
        recipes = recipeRaw.map<Map<String, dynamic>>((r) => {
          'id': r['recipeId'],
          'title': r['recipeTitle'] ?? '',
          'ingredients': r['recipeDescription'] ?? '',
          'image': r['imageUrl'] ?? '',
          'rating': 0.0,
          'reviews': 0,
          'author': '',
          'tags': r['recipePurpose'] != null ? ['#${r['recipePurpose']}'] : <String>[],
        }).toList();
      });
    } catch (_) {
      // 서버 미연결 시 빈 목록 유지
    }
  }

  String get searchQuery => _searchController.text.trim();

  bool get showPopularSearches =>
      isSearchFocused && searchQuery.isEmpty;

  bool get showAutocomplete =>
      searchQuery.isNotEmpty;

  void onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      fetchSuggestions(value);
    });
  }

  Future<void> fetchSuggestions(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      setState(() {
        suggestions = [];
        isLoadingSuggestions = false;
        suggestionError = null;
      });
      return;
    }

    setState(() {
      isLoadingSuggestions = true;
      suggestionError = null;
    });

    try {
      final res = await ApiClient.get(
        '/api/v1/recipes/search?keyword=${Uri.encodeQueryComponent(trimmed)}&size=5',
      );
      final List<dynamic> data = (res['data'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        suggestions = data.map((r) => r['recipeTitle']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        isLoadingSuggestions = false;
      });
      // 검색 결과도 업데이트
      setState(() {
        recipes = data.map<Map<String, dynamic>>((r) => {
          'id': r['recipeId'],
          'title': r['recipeTitle'] ?? '',
          'ingredients': r['recipeDescription'] ?? '',
          'image': r['imageUrl'] ?? '',
          'rating': 0.0,
          'reviews': 0,
          'author': '',
          'tags': r['recipePurpose'] != null ? ['#${r['recipePurpose']}'] : <String>[],
        }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        suggestions = [];
        isLoadingSuggestions = false;
        suggestionError = '추천 검색어를 불러오지 못했습니다.';
      });
    }
  }

  void clearSearch() {
    _searchController.clear();
    setState(() {
      suggestions = [];
      suggestionError = null;
      isSearchFocused = false;
    });
  }

  void selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    setState(() {
      isSearchFocused = false;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildRecipeImage(String? url, double width, double height) {
    if (url == null || url.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFB923C), Color(0xFFF97316)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.restaurant_menu, color: Color(0x88FFFFFF), size: 32),
        ),
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFB923C), Color(0xFFF97316)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.restaurant_menu, color: Color(0x88FFFFFF), size: 32),
        ),
      ),
    );
  }

  void _openFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _FilterBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          isSearchFocused = false;
        });
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: widget.standalone
            ? AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF111827)),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  '관련 레시피',
                  style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w700, fontSize: 18),
                ),
                centerTitle: true,
              )
            : null,
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.standalone)
                  const Text(
                    '레시피 검색',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onTap: () {
                        setState(() {
                          isSearchFocused = true;
                        });
                      },
                      onChanged: (value) {
                        setState(() {});
                        onSearchChanged(value);
                      },
                      decoration: const InputDecoration(
                        hintText: '레시피 또는 재료를 검색하세요',
                        hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF9CA3AF)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A00),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _openFilterModal,
                      icon: const Icon(Icons.tune, color: Colors.white),
                      label: const Text(
                        '우리 아이 맞춤 필터',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (showPopularSearches) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '인기 검색어',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isSearchFocused = false;
                        });
                      },
                      child: const Text('닫기'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: popularSearches.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.8,
                  ),
                  itemBuilder: (context, index) {
                    final item = popularSearches[index];
                    final rank = item['rank'] as int;
                    final term = item['term'] as String;
                    final isNew = item['isNew'] as bool;

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        _searchController.text = term;
                        setState(() {
                          isSearchFocused = false;
                        });
                        onSearchChanged(term);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$rank',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: rank <= 3
                                    ? const Color(0xFFFF7A00)
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                term,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            if (isNew)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ] else if (showAutocomplete) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '추천 검색어',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    TextButton(
                      onPressed: clearSearch,
                      child: const Text('초기화'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: isLoadingSuggestions
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : suggestionError != null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              suggestionError!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          )
                        : suggestions.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  '추천 검색어가 없습니다.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              )
                            : Column(
                                children: suggestions.map((suggestion) {
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => selectSuggestion(suggestion),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      margin: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.search,
                                            size: 18,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            suggestion,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF374151),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '인기 카테고리',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: popularCategories.map((category) {
                        return OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF9FAFB),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: () {},
                          child: Text(
                            category,
                            style: const TextStyle(color: Color(0xFF374151)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '총 ${recipes.length}개의 레시피',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const Row(
                      children: [
                        Text(
                          '인기순',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFFF7A00),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('|', style: TextStyle(color: Color(0xFFD1D5DB))),
                        SizedBox(width: 8),
                        Text(
                          '최신순',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: recipes.map((recipe) {
                    final tags = recipe['tags'] as List<dynamic>;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: _buildRecipeImage(recipe['image'] as String?, 96, 96),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recipe['title'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    recipe['ingredients'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: tags.map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF3E0),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          tag.toString(),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFFFF7A00),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 16, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${recipe['rating']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        ' (${recipe['reviews']})',
                                        style: const TextStyle(
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '👤 ${recipe['author']}',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatelessWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '맞춤 필터',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                '반려동물 종류',
                style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['강아지', '고양이', '기타'].map((item) {
                  return _FilterChip(label: item);
                }).toList(),
              ),

              const SizedBox(height: 20),
              const Text(
                '식단 목적',
                style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['다이어트', '알러지', '시니어', '성장기', '면역력', '피부/털']
                    .map((item) => _FilterChip(label: item))
                    .toList(),
              ),

              const SizedBox(height: 20),
              const Text(
                '주재료',
                style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['닭고기', '소고기', '연어', '참치', '오리', '양고기']
                    .map((item) => _FilterChip(label: item))
                    .toList(),
              ),

              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('초기화'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A00),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('적용하기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: () {},
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF374151)),
      ),
    );
  }
}

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  int selectedTabIndex = 0;

  List<Map<String, dynamic>> communityPosts = [];

  final List<Map<String, dynamic>> trendingTopics = [
    {'name': '저지방 레시피', 'count': 234},
    {'name': '알러지 프리', 'count': 189},
    {'name': '다이어트 식단', 'count': 156},
    {'name': '시니어 케어', 'count': 142},
  ];

  final List<String> tabs = ['전체', '레시피', '질문', '후기'];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final res = await ApiClient.get('/api/community/posts?size=20');
      final List<dynamic> content = (res['content'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        communityPosts = content.map<Map<String, dynamic>>((p) {
          final createdAt = p['createdAt'] as String? ?? '';
          return {
            'id': p['postId'],
            'author': p['authorNickname'] ?? p['authorName'] ?? '익명',
            'avatar': '🐾',
            'timeAgo': createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt,
            'content': p['postContent'] ?? p['content'] ?? '',
            'image': p['imageUrl'] ?? '',
            'likes': p['likeCount'] ?? 0,
            'comments': p['commentCount'] ?? 0,
            'views': p['viewCount'] ?? 0,
            'tags': (p['tags'] as List?)?.map((t) => '#$t').toList() ?? <String>[],
          };
        }).toList();
      });
    } catch (_) {
      // 서버 미연결 시 빈 목록 유지
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF7A00),
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '커뮤니티',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '반려동물 식단에 대한 이야기를 나눠보세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          // Trending Topics
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.trending_up, color: Color(0xFFFF7A00), size: 22),
                    SizedBox(width: 8),
                    Text(
                      '인기 토픽',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: trendingTopics.map((topic) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFF3E0),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: () {},
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                topic['name'],
                                style: const TextStyle(
                                  color: Color(0xFFFF7A00),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${topic['count']})',
                                style: const TextStyle(
                                  color: Color(0xFFFB923C),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Filter Tabs
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(tabs.length, (index) {
                  final selected = selectedTabIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tabs[index]),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          selectedTabIndex = index;
                        });
                      },
                      selectedColor: const Color(0xFFFF7A00),
                      backgroundColor: const Color(0xFFF3F4F6),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF4B5563),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: BorderSide.none,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Posts
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: communityPosts.map((post) {
                final tags = post['tags'] as List<dynamic>;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // post header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFEDD5),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  post['avatar'],
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post['author'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    post['timeAgo'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.more_vert, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                      ),

                      // content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          post['content'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: tags.map((tag) {
                            return Text(
                              tag.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFF7A00),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: Image.network(
                          post['image'],
                          width: double.infinity,
                          height: 280,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // actions
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _PostAction(
                                  icon: Icons.favorite_border,
                                  label: '${post['likes']}',
                                  onTap: () {},
                                ),
                                const SizedBox(width: 14),
                                _PostAction(
                                  icon: Icons.mode_comment_outlined,
                                  label: '${post['comments']}',
                                  onTap: () {},
                                ),
                                const SizedBox(width: 14),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.remove_red_eye_outlined,
                                      size: 20,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${post['views']}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.share_outlined,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  const _PostAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4B5563)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = '';
  String userEmail = '';
  List<Map<String, dynamic>> userPets = [];

  final List<Map<String, dynamic>> stats = [
    {'label': '저장한 레시피', 'value': 0, 'icon': Icons.favorite},
    {'label': '조리 완료', 'value': 0, 'icon': Icons.emoji_events},
    {'label': '작성한 리뷰', 'value': 0, 'icon': Icons.menu_book},
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final results = await Future.wait([
        ApiClient.get('/api/users/me'),
        ApiClient.get('/api/pets/'),
      ]);

      final user = results[0];
      final petsRaw = results[1]['data'] as List? ?? (results[1] is List ? results[1] : []);

      if (!mounted) return;
      setState(() {
        userName = user['userNickname'] ?? user['userName'] ?? '';
        userEmail = user['authEmail'] ?? '';
        userPets = (petsRaw as List).map<Map<String, dynamic>>((p) {
          final birthdate = p['petBirthdate'] as String? ?? '';
          String age = '';
          if (birthdate.isNotEmpty) {
            final birth = DateTime.tryParse(birthdate);
            if (birth != null) {
              final years = DateTime.now().year - birth.year;
              age = '$years살';
            }
          }
          return {
            'id': p['petId'],
            'name': p['petName'] ?? '',
            'type': p['petType'] ?? '',
            'breed': p['breedName'] ?? '',
            'age': age,
            'weight': '${p['petWeight'] ?? ''}kg',
            'allergies': <String>[],
            'image': p['petProfileImg'] ?? '',
          };
        }).toList();
      });
    } catch (_) {
      // 서버 미연결 시 기본값 유지
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuSections = [
      {
        'title': '계정',
        'items': [
          {'label': '알림 설정', 'icon': Icons.notifications_none, 'badge': '3'},
          {'label': '개인정보 보호', 'icon': Icons.shield_outlined},
          {'label': '앱 설정', 'icon': Icons.settings},
        ],
      },
      {
        'title': '지원',
        'items': [
          {'label': '도움말 & FAQ', 'icon': Icons.help_outline},
          {'label': '고객 지원', 'icon': Icons.support_agent},
        ],
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF97316),
                  Color(0xFFFB923C),
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '👤',
                          style: TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName.isNotEmpty ? userName : '로딩 중...',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail.isNotEmpty ? userEmail : '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFFDEFE7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: stats.map((stat) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                stat['icon'] as IconData,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${stat['value']}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stat['label'] as String,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFFDEFE7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          Transform.translate(
            offset: const Offset(0, -18),
            child: Column(
              children: [
                // My pets
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '우리 아이들',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PetAddPage()),
                              );
                              _fetchProfileData();
                            },
                            child: const Text(
                              '+ 추가하기',
                              style: TextStyle(color: Color(0xFFF97316)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...userPets.map((pet) {
                        final allergies = (pet['allergies'] as List).join(', ');
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      pet['image'],
                                      width: 82,
                                      height: 82,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: -4,
                                    bottom: -4,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF97316),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pet['name'],
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF1F2937),
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${pet['breed']} • ${pet['age']}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Text(
                                          '체중: ${pet['weight']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF4B5563),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            '알러지: $allergies',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFF97316),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 2),

                ...menuSections.map((section) {
                  final items = section['items'] as List<dynamic>;

                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section['title'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...items.map((item) {
                          final badge = item['badge'];
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    item['icon'] as IconData,
                                    color: const Color(0xFF4B5563),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item['label'] as String,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ),
                                  if (badge != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF97316),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        badge.toString(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),

                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '펫푸드 레시피 v1.0.0',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: const Text('이용약관'),
                          ),
                          const Text('|', style: TextStyle(color: Color(0xFFD1D5DB))),
                          TextButton(
                            onPressed: () {},
                            child: const Text('개인정보처리방침'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      backgroundColor: const Color(0xFFFEF2F2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.logout),
                    label: const Text('로그아웃'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PetTile extends StatelessWidget {
  const _PetTile({
    required this.name,
    required this.desc,
    required this.allergy,
  });

  final String name;
  final String desc;
  final String allergy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            'https://images.unsplash.com/photo-1517849845537-4d257902454a?auto=format&fit=crop&w=200&q=80',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$desc\n$allergy'),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }
}


class _BottomTabItem extends StatelessWidget {
  const _BottomTabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Color(0xFFF28C28);
    const Color inactiveColor = Color(0xFF8C8C8C);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? activeColor : inactiveColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CharacterPage extends StatelessWidget {
  const CharacterPage({super.key});

  @override
  Widget build(BuildContext context) {
    const int level = 12;
    const int exp = 750;
    const int maxExp = 1000;
    const int health = 85;
    const int happiness = 92;
    const int hunger = 45;

    const double expValue = exp / maxExp;

    final activities = [
      {
        'icon': Icons.restaurant,
        'label': '밥주기',
        'cost': 0,
        'color': const Color(0xFFFF7A00),
      },
      {
        'icon': Icons.favorite,
        'label': '쓰다듬기',
        'cost': 0,
        'color': const Color(0xFFEC4899),
      },
      {
        'icon': Icons.fitness_center,
        'label': '운동하기',
        'cost': 50,
        'color': const Color(0xFF3B82F6),
      },
      {
        'icon': Icons.auto_awesome,
        'label': '목욕시키기',
        'cost': 100,
        'color': const Color(0xFF8B5CF6),
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFEDD5),
            Color(0xFFFFF7ED),
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // Header
          const Text(
            '캐릭터 키우기',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '우리 아이와 함께 성장해요',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 20),

          // Character card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Color(0xFFFF7A00),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '레벨 12',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFFF7A00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                Container(
                  width: 190,
                  height: 190,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFED7AA),
                        Color(0xFFFDBA74),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '🐶',
                      style: TextStyle(fontSize: 88),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  '초코',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '건강한 골든 리트리버',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 20),

                // exp
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '경험치',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '750 / 1000',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1F2937),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    value: expValue,
                    minHeight: 10,
                    backgroundColor: Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation(Color(0xFFFF7A00)),
                  ),
                ),

                const SizedBox(height: 22),

                const _StatBar(
                  icon: Icons.favorite,
                  iconBgColor: Color(0xFFFEE2E2),
                  iconColor: Color(0xFFEF4444),
                  label: '건강',
                  value: health,
                  progressColor: Color(0xFFEF4444),
                ),
                const SizedBox(height: 14),
                const _StatBar(
                  icon: Icons.auto_awesome,
                  iconBgColor: Color(0xFFFEF3C7),
                  iconColor: Color(0xFFF59E0B),
                  label: '행복',
                  value: happiness,
                  progressColor: Color(0xFFF59E0B),
                ),
                const SizedBox(height: 14),
                const _StatBar(
                  icon: Icons.restaurant,
                  iconBgColor: Color(0xFFFFEDD5),
                  iconColor: Color(0xFFFF7A00),
                  label: '배고픔',
                  value: hunger,
                  progressColor: Color(0xFFFF7A00),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Activities
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '활동',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  itemCount: activities.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    final int cost = activity['cost'] as int;

                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {},
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: activity['color'] as Color,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                activity['icon'] as IconData,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              activity['label'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cost > 0 ? '🪙 $cost' : '무료',
                              style: TextStyle(
                                fontSize: 12,
                                color: cost > 0
                                    ? const Color(0xFFFF7A00)
                                    : const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Achievements
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '최근 업적',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 16),
                _AchievementTile(
                  emoji: '🏆',
                  title: '첫 식단 완료',
                  date: '2026.03.20',
                  bgColor: Color(0xFFFFF3E0),
                  iconBgColor: Color(0xFFFF7A00),
                ),
                SizedBox(height: 12),
                _AchievementTile(
                  emoji: '⭐',
                  title: '7일 연속 접속',
                  date: '2026.03.18',
                  bgColor: Color(0xFFEFF6FF),
                  iconBgColor: Color(0xFF3B82F6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.progressColor,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String label;
  final int value;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 42,
          child: Text(
            '$value%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.emoji,
    required this.title,
    required this.date,
    required this.bgColor,
    required this.iconBgColor,
  });

  final String emoji;
  final String title;
  final String date;
  final Color bgColor;
  final Color iconBgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 22),
              ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FindIdPage extends StatefulWidget {
  const FindIdPage({super.key});

  @override
  State<FindIdPage> createState() => _FindIdPageState();
}

class _FindIdPageState extends State<FindIdPage> {
  String step = 'input';

  final TextEditingController nameController = TextEditingController();
  String year = '';
  String month = '';
  String day = '';

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController verificationCodeController = TextEditingController();

  bool verificationSent = false;
  bool isVerified = false;
  String foundEmail = '';

  late final List<int> years;
  final List<int> months = List.generate(12, (i) => i + 1);
  final List<int> days = List.generate(31, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    years = List.generate(currentYear - 1949, (i) => currentYear - i);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    verificationCodeController.dispose();
    super.dispose();
  }

  void handleSendVerification() {
    setState(() {
      verificationSent = true;
    });
  }

  void handleVerifyCode() {
    if (verificationCodeController.text.length == 6) {
      setState(() {
        isVerified = true;
      });
    }
  }

  void handleFindId() {
    const mockEmail = 'petlover1234@gmail.com';
    final parts = mockEmail.split('@');
    final localPart = parts[0];
    final domain = parts[1];

    final blurredLocal =
        localPart.substring(0, 3) + ('*' * (localPart.length - 3));
    final blurredEmail = '$blurredLocal@$domain';

    setState(() {
      foundEmail = blurredEmail;
      step = 'result';
    });
  }

  bool get canFindId {
    return nameController.text.trim().isNotEmpty &&
        year.isNotEmpty &&
        month.isNotEmpty &&
        day.isNotEmpty &&
        isVerified;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF7ED),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const Text(
                          '아이디 찾기',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (step == 'input') ...[
                      Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFB923C),
                                  Color(0xFFF97316),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/paw.png',
                                width: 32,
                                height: 32,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '가입 시 등록한 정보를 입력해주세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        '이름',
                        style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: '이름을 입력하세요',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFF97316),
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        '생년월일',
                        style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _DateDropdown(
                              value: year.isEmpty ? null : year,
                              hint: '년도',
                              items: years.map((y) => y.toString()).toList(),
                              onChanged: (value) {
                                setState(() {
                                  year = value ?? '';
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DateDropdown(
                              value: month.isEmpty ? null : month,
                              hint: '월',
                              items: months.map((m) => m.toString()).toList(),
                              onChanged: (value) {
                                setState(() {
                                  month = value ?? '';
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DateDropdown(
                              value: day.isEmpty ? null : day,
                              hint: '일',
                              items: days.map((d) => d.toString()).toList(),
                              onChanged: (value) {
                                setState(() {
                                  day = value ?? '';
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        '전화번호',
                        style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              enabled: !isVerified,
                              keyboardType: TextInputType.phone,
                              onChanged: (value) {
                                final filtered = value.replaceAll(RegExp(r'[^0-9]'), '');
                                if (filtered != value) {
                                  phoneController.value = TextEditingValue(
                                    text: filtered,
                                    selection: TextSelection.collapsed(offset: filtered.length),
                                  );
                                }
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                hintText: '010-0000-0000',
                                filled: true,
                                fillColor: isVerified ? const Color(0xFFF3F4F6) : Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF97316),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 56,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFF97316),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: (phoneController.text.length < 10 || isVerified)
                                  ? null
                                  : handleSendVerification,
                              child: Text(verificationSent ? '재전송' : '인증번호'),
                            ),
                          ),
                        ],
                      ),

                      if (verificationSent && !isVerified) ...[
                        const SizedBox(height: 16),
                        const Text(
                          '인증번호',
                          style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: verificationCodeController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                onChanged: (value) {
                                  final filtered = value.replaceAll(RegExp(r'[^0-9]'), '');
                                  if (filtered != value) {
                                    verificationCodeController.value = TextEditingValue(
                                      text: filtered,
                                      selection: TextSelection.collapsed(offset: filtered.length),
                                    );
                                  }
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: '인증번호 6자리 입력',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFF97316),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 56,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF22C55E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: verificationCodeController.text.length == 6
                                    ? handleVerifyCode
                                    : null,
                                child: const Text('확인'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '⏱️ 인증번호는 5분간 유효합니다',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],

                      if (isVerified) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                              SizedBox(width: 8),
                              Text(
                                '전화번호 인증이 완료되었습니다',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: canFindId ? handleFindId : null,
                          child: const Text(
                            '아이디 찾기',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('로그인'),
                          ),
                          const Text('|', style: TextStyle(color: Color(0xFFD1D5DB))),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const FindPasswordPage()),
                              );
                            },
                            child: const Text('비밀번호 찾기'),
                          ),
                          const Text('|', style: TextStyle(color: Color(0xFFD1D5DB))),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SignupPage()),
                              );
                            },
                            child: const Text('회원가입'),
                          ),
                        ],
                      ),
                    ] else ...[
                      Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 40,
                              color: Color(0xFF22C55E),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '아이디를 찾았습니다',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '회원님의 정보와 일치하는 아이디입니다',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              border: Border.all(color: const Color(0xFFFED7AA)),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '가입된 이메일 (아이디)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  foundEmail,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFF97316),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('로그인하기'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFD1D5DB)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const FindPasswordPage()),
                                );
                              },
                              child: const Text(
                                '비밀번호 찾기',
                                style: TextStyle(color: Color(0xFF374151)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 28),
                    const Center(
                      child: Text(
                        '© 2026 펫푸드 레시피. All rights reserved.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
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

class _DateDropdown extends StatelessWidget {
  const _DateDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFF97316),
            width: 2,
          ),
        ),
      ),
      hint: Text(hint),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class FindPasswordPage extends StatefulWidget {
  const FindPasswordPage({super.key});

  @override
  State<FindPasswordPage> createState() => _FindPasswordPageState();
}

class _FindPasswordPageState extends State<FindPasswordPage> {
  String step = 'verify';

  final TextEditingController emailController = TextEditingController();
  final TextEditingController verificationCodeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool verificationSent = false;
  bool showPassword = false;
  bool showPasswordConfirm = false;

  @override
  void dispose() {
    emailController.dispose();
    verificationCodeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void handleSendVerification() {
    setState(() {
      verificationSent = true;
    });
  }

  void handleVerifyCode() {
    if (verificationCodeController.text.length == 6) {
      setState(() {
        step = 'reset';
      });
    }
  }

  void handleResetPassword() {
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (newPassword == confirmPassword && newPassword.length >= 8) {
      setState(() {
        step = 'complete';
      });
    }
  }

  bool get canSendVerification {
    return emailController.text.trim().isNotEmpty && !verificationSent;
  }

  bool get canVerifyCode {
    return verificationCodeController.text.length == 6;
  }

  bool get passwordsMatch {
    return confirmPasswordController.text.isNotEmpty &&
        newPasswordController.text == confirmPasswordController.text;
  }

  bool get passwordsNotMatch {
    return confirmPasswordController.text.isNotEmpty &&
        newPasswordController.text != confirmPasswordController.text;
  }

  bool get canResetPassword {
    return newPasswordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty &&
        newPasswordController.text == confirmPasswordController.text &&
        newPasswordController.text.length >= 8;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF7ED),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const Text(
                          '비밀번호 찾기',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (step == 'verify') ...[
                      Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFB923C),
                                  Color(0xFFF97316),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/paw.png',
                                width: 32,
                                height: 32,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '가입 시 등록한 이메일로 인증번호를 전송합니다',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        '이메일 (아이디)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: emailController,
                              enabled: !verificationSent,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'example@email.com',
                                filled: true,
                                fillColor: verificationSent
                                    ? const Color(0xFFF3F4F6)
                                    : Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF97316),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 56,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFF97316),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: canSendVerification ? handleSendVerification : null,
                              child: Text(verificationSent ? '재전송' : '인증번호'),
                            ),
                          ),
                        ],
                      ),

                      if (verificationSent) ...[
                        const SizedBox(height: 16),
                        const Text(
                          '인증번호',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: verificationCodeController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                onChanged: (value) {
                                  final filtered = value.replaceAll(RegExp(r'[^0-9]'), '');
                                  if (filtered != value) {
                                    verificationCodeController.value = TextEditingValue(
                                      text: filtered,
                                      selection: TextSelection.collapsed(offset: filtered.length),
                                    );
                                  }
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: '인증번호 6자리 입력',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFF97316),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 56,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF22C55E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: canVerifyCode ? handleVerifyCode : null,
                                child: const Text('확인'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '⏱️ 인증번호는 5분간 유효합니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const FindIdPage()),
                              );
                            },
                            child: const Text('아이디 찾기'),
                          ),
                          const Text('|', style: TextStyle(color: Color(0xFFD1D5DB))),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SignupPage()),
                              );
                            },
                            child: const Text('회원가입'),
                          ),
                        ],
                      ),
                    ] else if (step == 'reset') ...[
                      Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFB923C),
                                  Color(0xFFF97316),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/paw.png',
                                width: 32,
                                height: 32,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '새 비밀번호 설정',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '안전한 비밀번호로 변경해주세요',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        '새 비밀번호',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: newPasswordController,
                        obscureText: !showPassword,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: '비밀번호를 입력하세요 (8자 이상)',
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                showPassword = !showPassword;
                              });
                            },
                            icon: Icon(
                              showPassword ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFF97316),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '영문, 숫자, 특수문자 조합 8자 이상',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        '새 비밀번호 확인',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: !showPasswordConfirm,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: '비밀번호를 다시 입력하세요',
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                showPasswordConfirm = !showPasswordConfirm;
                              });
                            },
                            icon: Icon(
                              showPasswordConfirm ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFF97316),
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      if (passwordsNotMatch) ...[
                        const SizedBox(height: 6),
                        const Text(
                          '비밀번호가 일치하지 않습니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ],

                      if (passwordsMatch) ...[
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.check, size: 16, color: Color(0xFF22C55E)),
                            SizedBox(width: 4),
                            Text(
                              '비밀번호가 일치합니다',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),

                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: canResetPassword ? handleResetPassword : null,
                          child: const Text(
                            '비밀번호 변경',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ] else ...[
                      Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 40,
                              color: Color(0xFF22C55E),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '비밀번호 변경 완료',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '비밀번호가 성공적으로 변경되었습니다\n새 비밀번호로 로그인해주세요',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFF97316),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('로그인하기'),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 28),
                    const Center(
                      child: Text(
                        '© 2026 펫푸드 레시피. All rights reserved.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
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

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController verificationCodeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool showPassword = false;
  bool showPasswordConfirm = false;
  bool emailVerified = false;
  bool verificationSent = false;
  bool _isCheckingVerified = false;

  bool agreeAll = false;
  bool agreeTerms = false;
  bool agreePrivacy = false;
  bool agreeMarketing = false;

  String year = '';
  String month = '';
  String day = '';

  late final List<int> years;
  final List<int> months = List.generate(12, (i) => i + 1);
  final List<int> days = List.generate(31, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    years = List.generate(currentYear - 1949, (i) => currentYear - i);
    // onChanged 대신 addListener 사용 — 한글 IME 조합 중 rebuild 방지
    nameController.addListener(_rebuild);
    nicknameController.addListener(_onNicknameChanged);
    passwordController.addListener(_rebuild);
    passwordConfirmController.addListener(_rebuild);
    phoneController.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  void _onNicknameChanged() {
    setState(() {
      nicknameAvailable = false;
      _nicknameCheckMessage = null;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    verificationCodeController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    nicknameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  bool _isCheckingEmail = false;
  String? _emailCheckError;

  bool _isCheckingNickname = false;
  bool nicknameAvailable = false;
  String? _nicknameCheckMessage;

  Future<void> handleSendVerification() async {
    final email = emailController.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _isCheckingEmail = true;
      _emailCheckError = null;
    });
    try {
      await ApiClient.post(
        '/api/auth/send-email-verify',
        {'email': email},
        auth: false,
      );
      if (!mounted) return;
      setState(() {
        verificationSent = true;
        _emailCheckError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      String msg = '이메일 발송에 실패했습니다.';
      try {
        final body = jsonDecode(e.body) as Map<String, dynamic>;
        if (body['message'] != null) msg = body['message'] as String;
      } catch (_) {}
      setState(() => _emailCheckError = msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _emailCheckError = '서버에 연결할 수 없습니다.');
    } finally {
      if (mounted) setState(() => _isCheckingEmail = false);
    }
  }

  Future<void> handleConfirmVerified() async {
    final email = emailController.text.trim();
    setState(() => _isCheckingVerified = true);
    try {
      final res = await ApiClient.get(
        '/api/auth/check-pre-verified?email=${Uri.encodeQueryComponent(email)}',
        auth: false,
      );
      if (!mounted) return;
      final verified = res['verified'] as bool? ?? false;
      if (verified) {
        setState(() {
          emailVerified = true;
          _emailCheckError = null;
        });
      } else {
        setState(() => _emailCheckError = '아직 이메일 인증이 완료되지 않았습니다. 메일함을 확인해주세요.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _emailCheckError = '서버에 연결할 수 없습니다.');
    } finally {
      if (mounted) setState(() => _isCheckingVerified = false);
    }
  }

  Future<void> handleCheckNickname() async {
    final nickname = nicknameController.text.trim();
    if (nickname.isEmpty) return;
    setState(() {
      _isCheckingNickname = true;
      _nicknameCheckMessage = null;
    });
    try {
      final res = await ApiClient.get(
        '/api/auth/check-nickname?nickname=${Uri.encodeQueryComponent(nickname)}',
        auth: false,
      );
      if (!mounted) return;
      final available = res['available'] as bool? ?? false;
      setState(() {
        nicknameAvailable = available;
        _nicknameCheckMessage = res['message'] as String? ?? (available ? '사용 가능한 닉네임입니다.' : '이미 사용 중인 닉네임입니다.');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _nicknameCheckMessage = '서버에 연결할 수 없습니다.');
    } finally {
      if (mounted) setState(() => _isCheckingNickname = false);
    }
  }

  void handleAgreeAll(bool? value) {
    final checked = value ?? false;
    setState(() {
      agreeAll = checked;
      agreeTerms = checked;
      agreePrivacy = checked;
      agreeMarketing = checked;
    });
  }

  void updateAgreeAll() {
    setState(() {
      agreeAll = agreeTerms && agreePrivacy && agreeMarketing;
    });
  }

  bool get passwordsMatch {
    return passwordConfirmController.text.isNotEmpty &&
        passwordController.text == passwordConfirmController.text;
  }

  bool get passwordsNotMatch {
    return passwordConfirmController.text.isNotEmpty &&
        passwordController.text != passwordConfirmController.text;
  }

  bool get canSignUp {
    return nameController.text.trim().isNotEmpty &&
        year.isNotEmpty &&
        month.isNotEmpty &&
        day.isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        emailVerified &&
        passwordController.text.length >= 8 &&
        passwordController.text == passwordConfirmController.text &&
        nicknameAvailable &&
        agreeTerms &&
        agreePrivacy;
  }

  bool _isSignupLoading = false;

  Future<void> handleSignup() async {
    if (!canSignUp || _isSignupLoading) return;
    setState(() => _isSignupLoading = true);
    try {
      final birthdateStr = (year.isNotEmpty && month.isNotEmpty && day.isNotEmpty)
          ? '$year-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}'
          : null;
      await ApiClient.post(
        '/api/auth/signup',
        {
          'email': emailController.text.trim(),
          'password': passwordController.text,
          'userName': nameController.text.trim(),
          'nickname': nicknameController.text.trim(),
          'birthdate': birthdateStr,
        },
        auth: false,
      );
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('회원가입 완료'),
          content: const Text('회원가입이 완료됐습니다.\n로그인해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      String msg = '회원가입에 실패했습니다.';
      try {
        final body = jsonDecode(e.body) as Map<String, dynamic>;
        if (body['message'] != null) msg = body['message'] as String;
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버에 연결할 수 없습니다.')),
      );
    } finally {
      if (mounted) setState(() => _isSignupLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF7ED),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFB923C),
                                Color(0xFFF97316),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/paw.png',
                              width: 40,
                              height: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '회원가입',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF97316),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '펫푸드 레시피와 함께하세요',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      '이름 *',
                      style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: _inputDecoration('이름을 입력하세요'),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      '생년월일 *',
                      style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _DateDropdown(
                            value: year.isEmpty ? null : year,
                            hint: '년도',
                            items: years.map((y) => y.toString()).toList(),
                            onChanged: (value) {
                              setState(() {
                                year = value ?? '';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DateDropdown(
                            value: month.isEmpty ? null : month,
                            hint: '월',
                            items: months.map((m) => m.toString()).toList(),
                            onChanged: (value) {
                              setState(() {
                                month = value ?? '';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DateDropdown(
                            value: day.isEmpty ? null : day,
                            hint: '일',
                            items: days.map((d) => d.toString()).toList(),
                            onChanged: (value) {
                              setState(() {
                                day = value ?? '';
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      '이메일 *',
                      style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: emailController,
                            enabled: !emailVerified,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) => setState(() {}),
                            decoration: _inputDecoration(
                              'example@email.com',
                              fillColor: emailVerified
                                  ? const Color(0xFFF3F4F6)
                                  : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 56,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF97316),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: (emailVerified || _isCheckingEmail) ? null : handleSendVerification,
                            child: _isCheckingEmail
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(emailVerified ? '확인됨' : '이메일 확인'),
                          ),
                        ),
                      ],
                    ),

                    if (_emailCheckError != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.error_outline, size: 14, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Text(
                            _emailCheckError!,
                            style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ],

                    if (verificationSent && !emailVerified) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.mail_outline, size: 15, color: Color(0xFFF97316)),
                                SizedBox(width: 6),
                                Text(
                                  '인증 메일을 발송했습니다.',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFC2410C)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '메일함에서 인증 링크를 클릭한 후\n아래 [인증 완료] 버튼을 눌러주세요.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _isCheckingVerified ? null : handleConfirmVerified,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFF97316)),
                                  foregroundColor: const Color(0xFFF97316),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: _isCheckingVerified
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF97316)))
                                    : const Text('인증 완료'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (emailVerified) ...[
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
                          SizedBox(width: 6),
                          Text(
                            '이메일 인증이 완료됐습니다.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    const Text(
                      '비밀번호 *',
                      style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      decoration: _inputDecoration(
                        '비밀번호를 입력하세요 (8자 이상)',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              showPassword = !showPassword;
                            });
                          },
                          icon: Icon(
                            showPassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '영문, 숫자, 특수문자 조합 8자 이상',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      '비밀번호 확인 *',
                      style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordConfirmController,
                      obscureText: !showPasswordConfirm,
                      decoration: _inputDecoration(
                        '비밀번호를 다시 입력하세요',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              showPasswordConfirm = !showPasswordConfirm;
                            });
                          },
                          icon: Icon(
                            showPasswordConfirm ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),

                    if (passwordsNotMatch) ...[
                      const SizedBox(height: 6),
                      const Text(
                        '비밀번호가 일치하지 않습니다',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],

                    if (passwordsMatch) ...[
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(Icons.check, size: 16, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text(
                            '비밀번호가 일치합니다',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    const Text(
                      '닉네임 *',
                      style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nicknameController,
                            decoration: _inputDecoration('닉네임을 입력하세요'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFF3F4F6),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _isCheckingNickname ? null : handleCheckNickname,
                            child: _isCheckingNickname
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text(
                                    '중복확인',
                                    style: TextStyle(color: Color(0xFF374151)),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    if (_nicknameCheckMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _nicknameCheckMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: nicknameAvailable ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    const Text(
                      '전화번호 *',
                      style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        final filtered = value.replaceAll(RegExp(r'[^0-9-]'), '');
                        if (filtered != value) {
                          phoneController.value = TextEditingValue(
                            text: filtered,
                            selection: TextSelection.collapsed(offset: filtered.length),
                          );
                        }
                      },
                      decoration: _inputDecoration('010-0000-0000'),
                    ),

                    const SizedBox(height: 24),

                    CheckboxListTile(
                      value: agreeAll,
                      onChanged: handleAgreeAll,
                      activeColor: const Color(0xFFF97316),
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        '전체 동의',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const Divider(height: 1),

                    CheckboxListTile(
                      value: agreeTerms,
                      onChanged: (value) {
                        setState(() {
                          agreeTerms = value ?? false;
                        });
                        updateAgreeAll();
                      },
                      activeColor: const Color(0xFFF97316),
                      contentPadding: const EdgeInsets.only(left: 12),
                      title: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '[필수] ',
                              style: TextStyle(color: Color(0xFFF97316)),
                            ),
                            TextSpan(
                              text: '이용약관 동의',
                              style: TextStyle(color: Color(0xFF374151)),
                            ),
                          ],
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    CheckboxListTile(
                      value: agreePrivacy,
                      onChanged: (value) {
                        setState(() {
                          agreePrivacy = value ?? false;
                        });
                        updateAgreeAll();
                      },
                      activeColor: const Color(0xFFF97316),
                      contentPadding: const EdgeInsets.only(left: 12),
                      title: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '[필수] ',
                              style: TextStyle(color: Color(0xFFF97316)),
                            ),
                            TextSpan(
                              text: '개인정보 수집 및 이용 동의',
                              style: TextStyle(color: Color(0xFF374151)),
                            ),
                          ],
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    CheckboxListTile(
                      value: agreeMarketing,
                      onChanged: (value) {
                        setState(() {
                          agreeMarketing = value ?? false;
                        });
                        updateAgreeAll();
                      },
                      activeColor: const Color(0xFFF97316),
                      contentPadding: const EdgeInsets.only(left: 12),
                      title: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '[선택] ',
                              style: TextStyle(color: Color(0xFF9CA3AF)),
                            ),
                            TextSpan(
                              text: '마케팅 정보 수신 동의',
                              style: TextStyle(color: Color(0xFF374151)),
                            ),
                          ],
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: (canSignUp && !_isSignupLoading) ? handleSignup : null,
                        child: _isSignupLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '회원가입',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '이미 계정이 있으신가요? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            '로그인',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFF97316),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    const Center(
                      child: Text(
                        '© 2026 펫푸드 레시피. All rights reserved.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hintText, {
    Widget? suffixIcon,
    Color fillColor = Colors.white,
    String? counterText,
  }) {
    return InputDecoration(
      hintText: hintText,
      counterText: counterText,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFF97316),
          width: 2,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// AI 채팅 페이지
// ────────────────────────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  static const String _systemPrompt =
      '당신은 반려동물 식단 전문 AI 셰프입니다. '
      '강아지와 고양이의 건강, 알러지, 영양 균형을 고려한 맞춤 레시피와 식단 조언을 제공합니다. '
      '친절하고 전문적인 어조로 답변하며, 필요하면 수의사 상담을 권장합니다.';

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final response = await ApiClient.post(
        '/api/llm/chat',
        {'prompt': text, 'systemPrompt': _systemPrompt},
      );
      final answer = response['answer'] as String? ?? '답변을 받아오지 못했습니다.';
      setState(() {
        _messages.add(_ChatMessage(text: answer, isUser: false));
      });
    } on ApiException catch (e) {
      String msg = '오류가 발생했습니다. (${e.statusCode})';
      if (e.statusCode == 401) msg = '로그인이 필요합니다. 다시 로그인해주세요.';
      setState(() {
        _messages.add(_ChatMessage(text: msg, isUser: false));
      });
    } catch (_) {
      setState(() {
        _messages.add(_ChatMessage(text: '서버에 연결할 수 없습니다.', isUser: false));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFB923C), Color(0xFFF97316)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 셰프',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  '반려동물 식단 전문가',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) return _buildTypingIndicator();
                      return _buildBubble(_messages[index]);
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFB923C), Color(0xFFF97316)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'AI 셰프에게 물어보세요!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '반려동물 맞춤 식단, 레시피, 영양 정보를\n무엇이든 질문해보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              '강아지 다이어트 식단 추천',
              '고양이 알러지 식재료',
              '홈메이드 강아지 간식 레시피',
            ].map((hint) => GestureDetector(
              onTap: () {
                _inputController.text = hint;
                _sendMessage();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(
                  hint,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFC2410C)),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFB923C), Color(0xFFF97316)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFF97316) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : const Color(0xFF1F2937),
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFFB923C), Color(0xFFF97316)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: const SizedBox(
              width: 40,
              height: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DotIndicator(delay: 0),
                  _DotIndicator(delay: 150),
                  _DotIndicator(delay: 300),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: '반려동물 식단에 대해 질문하세요...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFFB923C), Color(0xFFF97316)]),
                  shape: BoxShape.circle,
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotIndicator extends StatefulWidget {
  final int delay;
  const _DotIndicator({required this.delay});

  @override
  State<_DotIndicator> createState() => _DotIndicatorState();
}

class _DotIndicatorState extends State<_DotIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 6,
        height: 6 + _anim.value * 4,
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xFFD1D5DB), const Color(0xFFF97316), _anim.value),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// DietGeneratePage — 반려동물 선택 후 AI 식단 생성
// ────────────────────────────────────────────────────────────

class DietGeneratePage extends StatefulWidget {
  const DietGeneratePage({super.key});

  @override
  State<DietGeneratePage> createState() => _DietGeneratePageState();
}

class _DietGeneratePageState extends State<DietGeneratePage> {
  List<Map<String, dynamic>> _pets = [];
  Map<String, dynamic>? _selectedPet;
  final TextEditingController _notesController = TextEditingController();
  bool _loadingPets = true;
  bool _generating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    setState(() => _loadingPets = true);
    try {
      final res = await ApiClient.get('/api/pets');
      if (!mounted) return;
      final raw = res['data'] as List? ?? (res is List ? res as List : []);
      final list = raw.cast<Map<String, dynamic>>();
      setState(() {
        _pets = list;
        _selectedPet = list.isNotEmpty ? list.first : null;
        _loadingPets = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingPets = false;
        _errorMessage = '반려동물 정보를 불러오지 못했습니다.';
      });
    }
  }

  Future<void> _generate() async {
    if (_selectedPet == null || _generating) return;
    setState(() {
      _generating = true;
      _errorMessage = null;
    });
    try {
      final result = await ApiClient.post(
        '/api/ai/diet/recommend-and-save?generateImage=true',
        {
          'petId': _selectedPet!['petId'],
          if (_notesController.text.trim().isNotEmpty)
            'userNotes': _notesController.text.trim(),
        },
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DietResultPage(result: result),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      String msg = '식단 생성에 실패했습니다.';
      try {
        final body = jsonDecode(e.body) as Map<String, dynamic>;
        if (body['message'] != null) msg = body['message'] as String;
      } catch (_) {}
      setState(() => _errorMessage = msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = '서버에 연결할 수 없습니다.');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI 식단 생성',
          style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _loadingPets
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)))
              : _pets.isEmpty
                  ? _buildNoPets()
                  : _buildForm(),
          if (_generating) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildNoPets() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pets, size: 64, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            const Text(
              '등록된 반려동물이 없습니다',
              style: TextStyle(fontSize: 16, color: Color(0xFF374151), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              '먼저 반려동물을 등록해주세요.',
              style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('반려동물 등록하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PetAddPage()),
                );
                _loadPets();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFB923C), Color(0xFFF97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.restaurant_menu, color: Colors.white, size: 32),
                SizedBox(height: 10),
                Text(
                  '맞춤 AI 식단 생성',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  '반려동물의 건강 상태와 알러지를 분석해\n최적의 홈메이드 레시피를 추천해드려요.',
                  style: TextStyle(color: Color(0xFFFDE9D6), fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Pet selector
          const Text(
            '반려동물 선택',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _pets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final pet = _pets[i];
                final selected = _selectedPet?['petId'] == pet['petId'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedPet = pet),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFFFF7ED) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? const Color(0xFFF97316) : const Color(0xFFE5E7EB),
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected
                          ? [const BoxShadow(color: Color(0x22F97316), blurRadius: 8, offset: Offset(0, 2))]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFFD0AA), width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(Icons.pets, size: 22, color: Color(0xFFF97316)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pet['petName'] as String? ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? const Color(0xFFF97316) : const Color(0xFF374151),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Notes field
          const Text(
            '특별 요청사항 (선택)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '예) 저단백 식단으로 해주세요, 닭고기 포함해주세요...',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Generate button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _selectedPet == null ? null : _generate,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'AI 식단 생성하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Center(
            child: Text(
              '생성에 약 20~40초 소요될 수 있습니다.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: const Color(0xCC000000),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  color: Color(0xFFF97316),
                  strokeWidth: 4,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'AI가 식단을 생성하는 중...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              SizedBox(height: 10),
              Text(
                '반려동물의 건강 정보를 분석하고\n최적의 레시피를 만들고 있어요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// DietResultPage — AI가 생성한 레시피 결과 표시
// ────────────────────────────────────────────────────────────

class DietResultPage extends StatelessWidget {
  final Map<String, dynamic> result;

  const DietResultPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final title = result['title'] as String? ?? '생성된 레시피';
    final description = result['description'] as String? ?? '';
    final imageUrl = result['imageUrl'] as String?;
    final feedingAmount = result['feedingAmount'] as String?;
    final ingredients = (result['ingredients'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final steps = (result['steps'] as List?)?.cast<String>() ?? [];
    final stepImages = (result['stepImages'] as List?)?.map((e) => e as String?).toList() ?? [];
    final warnings = (result['warnings'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI 생성 레시피',
          style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF374151)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchPage(standalone: true)),
              );
            },
            tooltip: '관련 레시피 보기',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(),
              )
            else
              _imagePlaceholder(),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: Color(0xFFF97316)),
                        SizedBox(width: 4),
                        Text(
                          'AI 생성 레시피',
                          style: TextStyle(fontSize: 12, color: Color(0xFFF97316), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827), height: 1.3),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Ingredients
                  _sectionTitle('재료'),
                  const SizedBox(height: 12),
                  ...ingredients.map((ing) {
                    final name = ing['name'] as String? ?? '';
                    final amount = ing['amount'] as String? ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF97316),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(name, style: const TextStyle(fontSize: 15, color: Color(0xFF111827))),
                          ),
                          Text(amount, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Steps
                  _sectionTitle('조리 방법'),
                  const SizedBox(height: 12),
                  ...steps.asMap().entries.map((e) {
                    final stepImg = e.key < stepImages.length ? stepImages[e.key] : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF97316),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${e.key + 1}',
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(e.value, style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.5)),
                                ),
                              ),
                            ],
                          ),
                          if (stepImg != null && stepImg.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                stepImg,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                  // Feeding amount
                  if (feedingAmount != null && feedingAmount.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionTitle('급여량 안내'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFF16A34A), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feedingAmount,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF15803D), height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Warnings
                  if (warnings.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionTitle('주의사항'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: warnings
                            .map((w) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(w, style: const TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.4)),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Related recipes button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF97316),
                        side: const BorderSide(color: Color(0xFFF97316)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.search, size: 20),
                      label: const Text(
                        '관련 레시피 더 보기',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SearchPage(standalone: true)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFB923C), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.restaurant_menu, size: 72, color: Color(0x88FFFFFF)),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFF97316),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// PetAddPage — 반려동물 등록
// ────────────────────────────────────────────────────────────

class PetAddPage extends StatefulWidget {
  const PetAddPage({super.key});

  @override
  State<PetAddPage> createState() => _PetAddPageState();
}

class _PetAddPageState extends State<PetAddPage> {
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();

  String _petType = 'DOG'; // DOG | CAT
  String? _gender;         // MALE | FEMALE | null
  bool? _isNeutered;
  String _birthYear = '';
  String _birthMonth = '';
  String _birthDay = '';

  bool _isLoading = false;
  String? _errorMessage;

  late final List<int> _years;
  final List<int> _months = List.generate(12, (i) => i + 1);
  final List<int> _days = List.generate(31, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().year;
    _years = List.generate(now - 1999, (i) => now - i);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = '반려동물 이름을 입력해주세요.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      String? birthdateStr;
      if (_birthYear.isNotEmpty && _birthMonth.isNotEmpty && _birthDay.isNotEmpty) {
        birthdateStr =
            '$_birthYear-${_birthMonth.padLeft(2, '0')}-${_birthDay.padLeft(2, '0')}';
      }
      double? weight;
      if (_weightController.text.trim().isNotEmpty) {
        weight = double.tryParse(_weightController.text.trim());
      }

      await ApiClient.post('/api/pets', {
        'petName': name,
        'petType': _petType,
        if (_gender != null) 'petGender': _gender,
        if (_isNeutered != null) 'isNeutered': _isNeutered,
        if (birthdateStr != null) 'petBirthdate': birthdateStr,
        if (weight != null) 'petWeight': weight,
      });
      if (!mounted) return;
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      String msg = '등록에 실패했습니다.';
      try {
        final body = jsonDecode(e.body) as Map<String, dynamic>;
        if (body['message'] != null) msg = body['message'] as String;
      } catch (_) {}
      setState(() => _errorMessage = msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = '서버에 연결할 수 없습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '반려동물 등록',
          style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 종류 선택 ──
            _label('종류 *'),
            const SizedBox(height: 10),
            Row(
              children: [
                _typeButton('강아지', 'DOG', Icons.pets),
                const SizedBox(width: 12),
                _typeButton('고양이', 'CAT', Icons.cruelty_free),
              ],
            ),

            const SizedBox(height: 20),

            // ── 이름 ──
            _label('이름 *'),
            const SizedBox(height: 10),
            _textField(_nameController, '반려동물 이름을 입력하세요'),

            const SizedBox(height: 20),

            // ── 성별 ──
            _label('성별'),
            const SizedBox(height: 10),
            Row(
              children: [
                _selectChip('수컷', 'MALE', _gender),
                const SizedBox(width: 10),
                _selectChip('암컷', 'FEMALE', _gender),
                const SizedBox(width: 10),
                _selectChip('모름', null, _gender, nullValue: true),
              ],
            ),

            const SizedBox(height: 20),

            // ── 중성화 ──
            _label('중성화'),
            const SizedBox(height: 10),
            Row(
              children: [
                _neuterChip('했음', true),
                const SizedBox(width: 10),
                _neuterChip('안했음', false),
                const SizedBox(width: 10),
                _neuterChip('모름', null, nullValue: true),
              ],
            ),

            const SizedBox(height: 20),

            // ── 생년월일 ──
            _label('생년월일'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _dropdown<int>(
                  value: _birthYear.isEmpty ? null : int.parse(_birthYear),
                  items: _years,
                  hint: '년',
                  onChanged: (v) => setState(() => _birthYear = v?.toString() ?? ''),
                )),
                const SizedBox(width: 8),
                Expanded(child: _dropdown<int>(
                  value: _birthMonth.isEmpty ? null : int.parse(_birthMonth),
                  items: _months,
                  hint: '월',
                  onChanged: (v) => setState(() => _birthMonth = v?.toString() ?? ''),
                )),
                const SizedBox(width: 8),
                Expanded(child: _dropdown<int>(
                  value: _birthDay.isEmpty ? null : int.parse(_birthDay),
                  items: _days,
                  hint: '일',
                  onChanged: (v) => setState(() => _birthDay = v?.toString() ?? ''),
                )),
              ],
            ),

            const SizedBox(height: 20),

            // ── 체중 ──
            _label('체중 (kg)'),
            const SizedBox(height: 10),
            _textField(
              _weightController,
              '예) 3.5',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('등록 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
      );

  Widget _textField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _typeButton(String label, String value, IconData icon) {
    final selected = _petType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _petType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF7ED) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFFF97316) : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? const Color(0xFFF97316) : const Color(0xFF9CA3AF), size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? const Color(0xFFF97316) : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectChip(String label, String? value, String? current, {bool nullValue = false}) {
    final selected = nullValue ? current == null : current == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = nullValue ? null : value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFF97316) : const Color(0xFFE5E7EB),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? const Color(0xFFF97316) : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _neuterChip(String label, bool? value, {bool nullValue = false}) {
    final selected = nullValue ? _isNeutered == null : _isNeutered == value;
    return GestureDetector(
      onTap: () => setState(() => _isNeutered = nullValue ? null : value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFF97316) : const Color(0xFFE5E7EB),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? const Color(0xFFF97316) : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required List<T> items,
    required String hint,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF), size: 20),
          items: items
              .map((e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text(e.toString(),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF111827))),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class TipDetailPage extends StatelessWidget {
  final String tip;
  final String detail;

  const TipDetailPage({super.key, required this.tip, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '오늘의 팁',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 오늘의 건강 팁',
                    style: TextStyle(fontSize: 13, color: Color(0xFFE0E7FF)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tip,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '상세 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                detail,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF374151),
                  height: 1.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class MealAddPage extends StatefulWidget {
  const MealAddPage({super.key});

  @override
  State<MealAddPage> createState() => _MealAddPageState();
}

class _MealAddPageState extends State<MealAddPage> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  XFile? _pickedImage;
  List<Map<String, dynamic>> _pets = [];
  int? _selectedPetId;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    try {
      final res = await ApiClient.get('/api/pets');
      final List<dynamic> items = res['data'] as List? ?? (res is List ? res as List : []);
      if (!mounted) return;
      setState(() {
        _pets = items.map<Map<String, dynamic>>((p) => {
          'petId': p['petId'],
          'petName': p['petName'] ?? '',
        }).toList();
        if (_pets.isNotEmpty) _selectedPetId = _pets[0]['petId'];
      });
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    setState(() => _pickedImage = file);
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('식단 이름을 입력해주세요.')),
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      String? imageUrl;
      if (_pickedImage != null) {
        final res = await ApiClient.uploadFile(
          '/api/meal-records/upload-photo',
          _pickedImage!.path,
        );
        imageUrl = res['imageUrl'] as String?;
      }

      await ApiClient.post('/api/meal-records', {
        if (_selectedPetId != null) 'petId': _selectedPetId,
        'mealTitle': _titleController.text.trim(),
        'mealNote': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        if (imageUrl != null) 'imageUrl': imageUrl,
        'mealDate': DateTime.now().toIso8601String().substring(0, 10),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '식단 기록 추가',
          style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _uploading ? null : _submit,
            child: const Text('저장', style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사진 선택
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
                ),
                child: _pickedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 40, color: Color(0xFF9CA3AF)),
                          SizedBox(height: 8),
                          Text('사진 추가', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // 반려동물 선택
            if (_pets.isNotEmpty) ...[
              const Text('반려동물', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _pets.map((pet) {
                  final selected = pet['petId'] == _selectedPetId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPetId = pet['petId']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFF97316) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? const Color(0xFFF97316) : const Color(0xFFD1D5DB),
                        ),
                      ),
                      child: Text(
                        pet['petName'],
                        style: TextStyle(
                          color: selected ? Colors.white : const Color(0xFF374151),
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // 식단 이름
            const Text('식단 이름', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: '예) 닭가슴살 야채밥',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF97316)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 메모
            const Text('메모 (선택)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '재료, 먹은 양 등 메모를 남겨보세요',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF97316)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _uploading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _uploading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('저장하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
