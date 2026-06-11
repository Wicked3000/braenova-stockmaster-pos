// lib/screens/home_screen.dart
// DoE PNG Mobile App — Public Home Screen

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';
import 'news_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<dynamic> _news = [];
  bool _loadingNews = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    final result = await ApiService.fetchNews(limit: 3);
    if (!mounted) return;
    setState(() {
      _loadingNews = false;
      if (result['success'] == true) {
        _news = (result['data'] as List?)?.take(3).toList() ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildHero()),
              SliverToBoxAdapter(child: _buildQuickAccess()),
              SliverToBoxAdapter(child: _buildLatestNews()),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      // Respect dark/light theme
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          // ── DoE Logo in a white pill so it works in both themes ──
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              // Subtle shadow so the white circle doesn't disappear on white bg
              boxShadow: [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: Image.asset(
              'assets/images/logo/DoE Logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DoE PNG',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'Papua New Guinea',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.themeNotifier,
          builder: (context, mode, _) {
            final isDark = mode == ThemeMode.dark;
            return IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: const Color(0xFF1D4ED8),
              ),
              onPressed: ThemeService.toggleTheme,
              tooltip: 'Toggle Theme',
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.person_outline_rounded, color: Color(0xFF1D4ED8)),
          onPressed: () => Navigator.pushNamed(context, '/login'),
          tooltip: 'Staff Login',
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.all(12),
      height: 150,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Welcome',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Education for\nEvery Child',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.account_balance_rounded, size: 72, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildQuickAccess() {
    final items = [
      const _QuickItem(icon: Icons.newspaper_rounded,    label: 'News',         route: '/news',         color: Color(0xFF1D4ED8)),
      const _QuickItem(icon: Icons.bookmark_rounded,     label: 'Curriculum',   route: '/curriculum',   color: Color(0xFF6366F1)),
      const _QuickItem(icon: Icons.menu_book_rounded,    label: 'Publications', route: '/publications', color: Color(0xFF0EA5E9)),
      const _QuickItem(icon: Icons.description_rounded,  label: 'Forms',        route: '/forms',        color: Color(0xFFF59E0B)),
      const _QuickItem(icon: Icons.info_outline_rounded, label: 'About',        route: '/about',        color: Color(0xFF8B5CF6)),
      const _QuickItem(icon: Icons.chat_bubble_outline,  label: 'Contact',      route: '/contact',      color: Color(0xFFEF4444)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int cols = 3;
          if (constraints.maxWidth >= 600) {
            cols = 6;
          } else if (constraints.maxWidth <= 350) {
            cols = 2;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'QUICK ACCESS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 1),
                ),
              ),
              GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.1,
                children: items.map((item) => _buildQuickCard(item)).toList(),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildQuickCard(_QuickItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, item.route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestNews() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LATEST NEWS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 1),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/news'),
                child: const Text('See all', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (_loadingNews) ...[
            _buildSkeletonCard(),
            _buildSkeletonCard(),
          ] else if (_news.isEmpty)
            _buildNewsPlaceholders()
          else
            ..._news.map((item) => _buildNewsCard(item)),
        ],
      ),
    );
  }

  Widget _buildNewsCard(dynamic item) {
    final title = item['title'] ?? item['name'] ?? '';
    final date = item['published_at'] ?? item['created_at'] ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.newspaper_rounded, color: Colors.white, size: 22),
        ),
        title: Text(
          title.toString(),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: date.isNotEmpty
            ? Text(date.toString().substring(0, 10), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))
            : null,
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(newsItem: item as Map<String, dynamic>),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsPlaceholders() {
    const items = [
      {'title': 'National Curriculum Review 2025', 'date': '2025-06-10'},
      {'title': 'New School Term Announcement', 'date': '2025-06-08'},
      {'title': 'Teacher Training Program Open', 'date': '2025-06-05'},
    ];
    return Column(
      children: items.map((item) => _buildNewsCard(item)).toList(),
    );
  }

  Widget _buildSkeletonCard() {
    final cardColor = Theme.of(context).cardColor;
    return Container(
      height: 70,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return NavigationBar(
      selectedIndex: _selectedIndex,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      indicatorColor: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
      onDestinationSelected: (i) {
        setState(() => _selectedIndex = i);
        if (i == 0) { /* already home */ }
        if (i == 1) Navigator.pushNamed(context, '/news');
        if (i == 2) Navigator.pushNamed(context, '/public-inbox');
        if (i == 3) Navigator.pushNamed(context, '/contact');
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.newspaper_outlined), selectedIcon: Icon(Icons.newspaper_rounded), label: 'News'),
        NavigationDestination(icon: Icon(Icons.mail_outline_rounded), selectedIcon: Icon(Icons.mail_rounded), label: 'Inbox'),
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble_rounded), label: 'Contact'),
      ],
    );
  }
}

class _QuickItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _QuickItem({required this.icon, required this.label, required this.route, required this.color});
}
