// lib/screens/public_inbox_screen.dart
// Private inbox — shows only messages tied to the logged-in public user.

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class PublicInboxScreen extends StatefulWidget {
  const PublicInboxScreen({super.key});

  @override
  State<PublicInboxScreen> createState() => _PublicInboxScreenState();
}

class _PublicInboxScreenState extends State<PublicInboxScreen> {
  bool _checkingAuth = true;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  List<dynamic> _messages = [];
  bool _loadingMessages = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await ApiService.isLoggedIn();
    final user = await ApiService.getCurrentUser();
    setState(() {
      _isLoggedIn = loggedIn && (user?['role'] == 'public');
      _user = user;
      _checkingAuth = false;
    });
    if (_isLoggedIn) _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _loadingMessages = true;
      _error = null;
    });
    try {
      final msgs = await ApiService.getMyInbox();
      setState(() => _messages = msgs);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loadingMessages = false);
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    setState(() {
      _isLoggedIn = false;
      _user = null;
      _messages = [];
    });
  }

  Future<void> _openLogin() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (result == true) _checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    if (_checkingAuth) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Inbox'),
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sign Out',
              onPressed: _logout,
            ),
        ],
      ),
      body: _isLoggedIn ? _buildInbox(isDark, cardColor, textColor) : _buildLoginPrompt(isDark, textColor),
    );
  }

  // ── LOGGED-IN VIEW ───────────────────────────────────────────────────
  Widget _buildInbox(bool isDark, Color cardColor, Color textColor) {
    if (_loadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Could not load messages', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _fetchMessages, child: const Text('Try Again')),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 72, color: isDark ? Colors.grey[700] : Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Your inbox is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Text(
              'When you submit an enquiry and the Department\nreplies, it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMessages,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
                      child: Text(
                        (_user?['full_name'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_user?['full_name'] ?? 'User', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                        Text(_user?['email'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final status = (msg['app_status'] ?? 'new').toString();
                    final hasReply = (msg['reply_message'] ?? '').toString().isNotEmpty;
                    final isNew = status == 'new';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: isNew ? Border.all(color: const Color(0xFF1D4ED8), width: 1.5) : null,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    msg['subject']?.toString() ?? 'Enquiry',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isNew ? FontWeight.w800 : FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                _StatusBadge(status: status),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Your message
                            Text(
                              'Your message:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg['message']?.toString() ?? '',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (hasReply) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF1D4ED8).withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.school_rounded, size: 14, color: Color(0xFF1D4ED8)),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Reply from enquiries@education.gov.pg',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      msg['reply_message'].toString(),
                                      style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B), height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              'Submitted: ${(msg['submitted_at'] ?? '').toString().substring(0, 10)}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── NOT LOGGED IN VIEW ───────────────────────────────────────────────
  Widget _buildLoginPrompt(bool isDark, Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_person_rounded,
                size: 80,
                color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8),
              ),
              const SizedBox(height: 24),
              Text(
                'Private Inbox',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to see your private messages and track your enquiries sent to the Department of Education.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[500], height: 1.5),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openLogin,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                    _checkAuth();
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'new':      [const Color(0xFF1D4ED8), const Color(0xFFEFF6FF)],
      'read':     [const Color(0xFF64748B), const Color(0xFFF1F5F9)],
      'replied':  [const Color(0xFF16A34A), const Color(0xFFDCFCE7)],
      'resolved': [const Color(0xFF9333EA), const Color(0xFFF3E8FF)],
    };
    final labels = {'new': 'New', 'read': 'Sent', 'replied': 'Replied', 'resolved': 'Resolved'};
    final pair = colors[status] ?? [const Color(0xFF64748B), const Color(0xFFF1F5F9)];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: pair[1],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        labels[status] ?? status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pair[0]),
      ),
    );
  }
}
