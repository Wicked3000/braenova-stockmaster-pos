// lib/screens/news_screen.dart
// DoE PNG Mobile App — News & Announcements

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;



  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.fetchNews();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _items = result['data'] ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('News & Announcements')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (_, i) => _buildCard(_items[i], i),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCard(dynamic item, int index) {
    final title = item['title'] ?? item['name'] ?? 'News Item';
    final desc = item['description'] ?? item['content'] ?? item['body'] ?? '';
    final date = (item['published_at'] ?? item['created_at'] ?? '').toString();
    final shortDate = date.length >= 10 ? date.substring(0, 10) : date;
    final icons = ['📰', '📢', '🏫', '📚', '🎓', '📝', '🌏'];
    final emoji = icons[index % icons.length];

    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(newsItem: item as Map<String, dynamic>),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toString(),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              height: 1.3),
                        ),
                        const SizedBox(height: 2),
                        Text(shortDate,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ],
              ),
              if (desc.toString().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  desc.toString(),
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF475569), height: 1.55),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Read More',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D4ED8))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
