// lib/screens/inbox_screen.dart
// DoE PNG Mobile App — Enquiries Inbox

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/enquiry.dart';
import 'enquiry_detail_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _statuses = ['', 'new', 'read', 'replied', 'resolved'];
  final _labels = ['All', 'New', 'Read', 'Replied', 'Resolved'];

  final Map<String, List<Enquiry>> _cache = {};
  final Map<String, bool> _loading = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _statuses.length, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        _loadTab(_statuses[_tabs.index]);
      }
    });
    _loadTab(''); // Load first tab
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadTab(String status, {bool force = false}) async {
    if (_loading[status] == true) return;
    if (!force && _cache.containsKey(status)) return;

    setState(() => _loading[status] = true);

    final result =
        await ApiService.fetchEnquiries(status: status.isEmpty ? null : status);
    if (!mounted) return;

    setState(() {
      _loading[status] = false;
      if (result['success'] == true) {
        final items = (result['data'] as List?) ?? [];
        _cache[status] = items
            .map((e) => Enquiry.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _cache[status] = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enquiries Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              final s = _statuses[_tabs.index];
              _cache.remove(s);
              _loadTab(s, force: true);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _labels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: _statuses.map((status) => _buildTab(status)).toList(),
      ),
    );
  }

  Widget _buildTab(String status) {
    final isLoading = _loading[status] == true;
    final items = _cache[status];

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items == null) {
      _loadTab(status);
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mail_outlined, size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              'No ${status.isEmpty ? '' : status} enquiries',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _cache.remove(status);
        await _loadTab(status, force: true);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildCard(items[i]),
      ),
    );
  }

  Widget _buildCard(Enquiry item) {
    final statusColors = {
      'new': const Color(0xFF1D4ED8),
      'read': const Color(0xFF8B5CF6),
      'replied': const Color(0xFF10B981),
      'resolved': const Color(0xFFF59E0B),
    };
    final color = statusColors[item.appStatus] ?? const Color(0xFF64748B);
    final date =
        item.submittedAt.isNotEmpty ? item.submittedAt.substring(0, 10) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EnquiryDetailScreen(enquiryId: item.id)),
          );
          // Refresh after returning (status may have changed)
          final s = _statuses[_tabs.index];
          _cache.remove(s);
          _loadTab(s, force: true);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1E293B))),
                  Text(date,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ),
              const SizedBox(height: 3),
              Text(item.subject,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 3),
              Text(
                item.message.length > 80
                    ? '${item.message.substring(0, 80)}…'
                    : item.message,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(item.appStatus,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color)),
                  ),
                  Text(item.email,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
