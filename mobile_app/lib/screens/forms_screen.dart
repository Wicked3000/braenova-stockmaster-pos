import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class FormsScreen extends StatefulWidget {
  const FormsScreen({super.key});

  @override
  State<FormsScreen> createState() => _FormsScreenState();
}

class _FormsScreenState extends State<FormsScreen> {
  bool _isLoading = true;
  List<dynamic> _forms = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final result = await ApiService.fetchForms();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _forms = result['data'] ?? [];
      }
    });
  }

  Future<void> _downloadForm(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Public Forms')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _forms.isEmpty
              ? _buildEmptyState()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _forms.length,
                      itemBuilder: (context, index) {
                        final form = _forms[index];
                        final title = form['title'] ?? form['name'] ?? '';
                        final desc = form['description'] ?? '';
                        final url = form['url'] ?? form['file_url'] ?? '';
                        final date = form['published_at'] ?? form['created_at'] ?? '';

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
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.description_rounded, color: Color(0xFFF59E0B)),
                            ),
                            title: Text(
                              title.toString(),
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor),
                            ),
                            subtitle: desc.toString().isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(desc.toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  )
                                : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.download_rounded, color: Color(0xFFF59E0B)),
                              onPressed: () {
                                if (url.toString().isNotEmpty) {
                                  _downloadForm(url.toString());
                                }
                              },
                            ),
                            onTap: () {
                              if (url.toString().isNotEmpty) {
                                _downloadForm(url.toString());
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
          Icon(Icons.folder_open_rounded, size: 64, color: Colors.black12),
          SizedBox(height: 16),
          Text(
            'No forms available',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
