// lib/screens/reply_screen.dart
// DoE PNG Mobile App — Send Email Reply Screen

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReplyScreen extends StatefulWidget {
  final int enquiryId;
  const ReplyScreen({super.key, required this.enquiryId});

  @override
  State<ReplyScreen> createState() => _ReplyScreenState();
}

class _ReplyScreenState extends State<ReplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _msgCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await ApiService.sendReply(widget.enquiryId, _msgCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reply sent: ${result['message'] ?? 'Success'}'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() => _error = result['error']?.toString() ?? 'Failed to send reply.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Reply')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Replying to" info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.reply_rounded, color: Color(0xFF1D4ED8), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Enquiry #${widget.enquiryId} — Reply will be sent via email.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Error
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      border: Border.all(color: const Color(0xFFFECACA)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                ],

                const Text('Reply Message', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _msgCtrl,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'Type your reply here…',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Reply message is required' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _send,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_loading ? 'Sending…' : 'Send Email Reply'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'The reply will be sent to the enquirer\'s email address on behalf of the Department of Education.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
