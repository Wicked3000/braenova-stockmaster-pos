import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'pdf_viewer_screen.dart';

class PublicationsScreen extends StatefulWidget {
  const PublicationsScreen({super.key});

  @override
  State<PublicationsScreen> createState() => _PublicationsScreenState();
}

class _PublicationsScreenState extends State<PublicationsScreen> {
  bool _isLoading = true;
  List<dynamic> _publications = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final result = await ApiService.fetchPublications();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _publications = result['data'] ?? [];
      } else {
        // Fallback or empty state will be shown
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _publications.isEmpty
              ? _buildEmptyState()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _publications.length,
                      itemBuilder: (context, index) {
                        final pub = _publications[index];
                        final title = pub['title'] ?? pub['name'] ?? '';
                        final url = pub['url'] ?? pub['file_url'] ?? '';
                        final date = pub['published_at'] ?? pub['created_at'] ?? '';

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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF0EA5E9)),
                            ),
                            title: Text(
                              title.toString(),
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor),
                            ),
                            subtitle: date.toString().isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('Published: ${date.toString().substring(0, 10)}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  )
                                : null,
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                            onTap: () {
                              if (url.toString().isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PdfViewerScreen(
                                      pdfUrl: url.toString(),
                                      title: title.toString(),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: 64, color: Colors.black12),
          SizedBox(height: 16),
          Text(
            'No publications available',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
