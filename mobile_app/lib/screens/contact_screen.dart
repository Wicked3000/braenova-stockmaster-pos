// lib/screens/contact_screen.dart
// DoE PNG Mobile App — Public Contact / Enquiry Submission Form

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _loading = false;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _loggedInUser;

  @override
  void initState() {
    super.initState();
    _loadUserIfLoggedIn();
  }

  Future<void> _loadUserIfLoggedIn() async {
    final user = await ApiService.getCurrentUser();
    if (user != null && user['role'] == 'public') {
      setState(() {
        _isLoggedIn = true;
        _loggedInUser = user;
        _nameCtrl.text = user['full_name'] ?? '';
        _emailCtrl.text = user['email'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _subjectCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final result = await ApiService.submitContact(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      subject: _subjectCtrl.text.trim(),
      message: _msgCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      _formKey.currentState!.reset();
      _nameCtrl.clear();
      _emailCtrl.clear();
      _phoneCtrl.clear();
      _subjectCtrl.clear();
      _msgCtrl.clear();
      // Reload user if logged in
      if (_isLoggedIn && _loggedInUser != null) _loadUserIfLoggedIn();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Enquiry Submitted'),
          content: Text(
            _isLoggedIn
                ? 'Thank you! Your enquiry has been submitted and linked to your account. You can track replies in your Inbox.'
                : 'Thank you for contacting the Department of Education. Our staff will review your enquiry and respond via email.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']?.toString() ??
              'Submission failed. Please try again.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Intro card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          color: Color(0xFF1D4ED8), size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Send us an enquiry and our staff will respond as soon as possible.',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1D4ED8),
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _field(_nameCtrl, 'Full Name', Icons.person_outline_rounded,
                    required: true, readOnly: _isLoggedIn),
                const SizedBox(height: 12),
                _field(_emailCtrl, 'Email Address', Icons.email_outlined,
                    type: TextInputType.emailAddress,
                    required: true, readOnly: _isLoggedIn, validator: (v) {
                  if (v == null || v.isEmpty) return 'Email required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                }),
                const SizedBox(height: 12),
                if (!_isLoggedIn) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Sign in to track replies to your enquiry in your private Inbox.',
                            style: TextStyle(fontSize: 12, color: Colors.amber),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()));
                            _loadUserIfLoggedIn();
                          },
                          child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _field(_phoneCtrl, 'Phone (optional)', Icons.phone_outlined,
                    type: TextInputType.phone),
                const SizedBox(height: 12),
                _field(_subjectCtrl, 'Subject', Icons.subject_rounded,
                    required: true),
                const SizedBox(height: 12),
                const Text('Message',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _msgCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                      hintText: 'Write your message here…'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Message required'
                      : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_loading ? 'Submitting…' : 'Send Enquiry'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    bool readOnly = false,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          readOnly: readOnly,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            hintText: label,
            filled: readOnly,
            fillColor: readOnly
                ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                : null,
            suffixIcon: readOnly
                ? const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF94A3B8))
                : null,
          ),
          validator: validator ??
              (required
                  ? (v) => (v == null || v.isEmpty) ? '$label required' : null
                  : null),
        ),
      ],
    );
  }
}

