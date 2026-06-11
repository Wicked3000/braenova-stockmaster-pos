// lib/screens/enquiry_detail_screen.dart
// DoE PNG Mobile App — Enquiry Detail + Reply

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/enquiry.dart';
import 'reply_screen.dart';

class EnquiryDetailScreen extends StatefulWidget {
  final int enquiryId;
  const EnquiryDetailScreen({super.key, required this.enquiryId});

  @override
  State<EnquiryDetailScreen> createState() => _EnquiryDetailScreenState();
}

class _EnquiryDetailScreenState extends State<EnquiryDetailScreen> {
  Enquiry? _enquiry;
  bool _loading = true;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.getEnquiryDetail(widget.enquiryId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _enquiry = Enquiry.fromJson(result['data'] as Map<String, dynamic>);
      }
    });
  }

  Future<void> _markResolved() async {
    if (_enquiry == null) return;
    setState(() => _resolving = true);
    final result = await ApiService.markResolved(widget.enquiryId);
    if (!mounted) return;
    setState(() => _resolving = false);
    if (result['success'] == true) {
      _load();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enquiry marked as resolved ✅'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enquiry Detail'),
        actions: [
          if (_enquiry != null && !_enquiry!.isResolved)
            _resolving
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        color: Color(0xFF10B981)),
                    onPressed: _markResolved,
                    tooltip: 'Mark Resolved',
                  ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _enquiry == null
              ? const Center(child: Text('Could not load enquiry.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 10),
                      _buildMessageCard(),
                      if (_enquiry!.replyMessage != null) ...[
                        const SizedBox(height: 10),
                        _buildReplyCard(),
                      ],
                      if (!_enquiry!.isResolved) ...[
                        const SizedBox(height: 16),
                        _buildActions(),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard() {
    final e = _enquiry!;
    final statusColors = {
      'new': const Color(0xFF1D4ED8),
      'read': const Color(0xFF8B5CF6),
      'replied': const Color(0xFF10B981),
      'resolved': const Color(0xFFF59E0B),
    };
    final color = statusColors[e.appStatus] ?? const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(e.name,
              style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text('✉️  ${e.email}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF1D4ED8))),
          if (e.phone != null && e.phone!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('📞  ${e.phone}',
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            ),
          const Divider(height: 20),
          Text(e.subject,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(e.appStatus,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ),
              Text(
                'Submitted: ${e.submittedAt.isNotEmpty ? e.submittedAt.substring(0, 10) : ""}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              if (e.repliedAt != null)
                Text(
                  'Replied: ${e.repliedAt!.substring(0, 10)} by ${e.repliedBy ?? ""}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MESSAGE',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          Text(_enquiry!.message,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF1E293B), height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildReplyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            const Border(left: BorderSide(color: Color(0xFF10B981), width: 3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OUR REPLY',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          Text(_enquiry!.replyMessage!,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF1E293B), height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ReplyScreen(enquiryId: widget.enquiryId)),
              );
              _load();
            },
            icon: const Icon(Icons.reply_rounded, size: 18),
            label: const Text('Reply via Email'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _resolving ? null : _markResolved,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Resolve'),
          ),
        ),
      ],
    );
  }
}
