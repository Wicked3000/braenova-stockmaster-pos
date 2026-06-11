import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About DoE')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_rounded, size: 64, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Department of Education\nPapua New Guinea',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Outfit',
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Our Vision',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'To educate and train all Papua New Guineans for the integral human development of our people and nation.',
                    style: TextStyle(fontSize: 15, color: Color(0xFF475569), height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Contact Us',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildContactRow(
                    icon: Icons.location_on_rounded,
                    text: 'Fincorp Haus, Waigani, NCD, Papua New Guinea',
                    onTap: null,
                  ),
                  _buildContactRow(
                    icon: Icons.phone_rounded,
                    text: '+675 301 3333',
                    onTap: () => _launchUrl('tel:+6753013333'),
                  ),
                  _buildContactRow(
                    icon: Icons.email_rounded,
                    text: 'enquiries@education.gov.pg',
                    onTap: () => _launchUrl('mailto:enquiries@education.gov.pg'),
                  ),
                  _buildContactRow(
                    icon: Icons.language_rounded,
                    text: 'www.education.gov.pg',
                    onTap: () => _launchUrl('https://education.gov.pg'),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'App Version 1.0.0',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow({required IconData icon, required String text, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: const Color(0xFF1D4ED8)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    color: onTap != null ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                    decoration: onTap != null ? TextDecoration.underline : null,
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
