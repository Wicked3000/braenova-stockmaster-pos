import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'pdf_viewer_screen.dart';

class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  bool _isLoading = true;
  List<dynamic> _documents = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final result = await ApiService.fetchCurriculum();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _documents = result['data'] ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Curriculum')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? _buildEmptyState()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _documents.length,
                      itemBuilder: (context, index) {
                        final doc = _documents[index];
                        final title = doc['title'] ?? doc['name'] ?? '';
                        final url = doc['url'] ?? doc['file_url'] ?? '';
                        final date = doc['published_at'] ?? doc['created_at'] ?? '';

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
                                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.bookmark_rounded, color: Color(0xFF6366F1)),
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
          Icon(Icons.bookmark_border_rounded, size: 64, color: Colors.black12),
          SizedBox(height: 16),
          Text(
            'No curriculum documents available',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
