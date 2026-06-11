import 'package:flutter/material.dart';

class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> newsItem;

  const NewsDetailScreen({super.key, required this.newsItem});

  @override
  Widget build(BuildContext context) {
    final title = newsItem['title'] ?? 'News Article';
    final content = newsItem['content'] ?? newsItem['description'] ?? 'No content available.';
    final date = (newsItem['published_at'] ?? '').toString();
    final shortDate = date.length >= 10 ? date.substring(0, 10) : date;
    final author = newsItem['author'] ?? 'Department of Education';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1D4ED8).withValues(alpha: 0.2) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'NEWS UPDATE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  title.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                // Meta info
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(shortDate, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    const SizedBox(width: 16),
                    const Icon(Icons.person_rounded, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        author.toString(),
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                const SizedBox(height: 24),
                // Body Content
                Text(
                  content.toString().replaceAll('\\n', '\n'),
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
