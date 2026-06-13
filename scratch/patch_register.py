import re

with open('mobile_app/lib/screens/register_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add imports
content = content.replace("import '../services/api_service.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../core/api_client.dart';")
content = content.replace("class RegisterScreen extends StatefulWidget {", "class RegisterScreen extends ConsumerStatefulWidget {")
content = content.replace("State<RegisterScreen> createState() => _RegisterScreenState();", "ConsumerState<RegisterScreen> createState() => _RegisterScreenState();")
content = content.replace("class _RegisterScreenState extends State<RegisterScreen> {", "class _RegisterScreenState extends ConsumerState<RegisterScreen> {")

# Update logic
new_logic = '''  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      final res = await client.register({
        'shop_name': _nameController.text.trim(),
        'username': _emailController.text.trim(),
        'password': _passwordController.text,
      });
      
      if (res.data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please sign in.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        setState(() => _errorMessage = res.data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }'''
content = re.sub(r'''  Future<void> _register\(\) async \{\n    setState\(\(\) \{\n      _isLoading = true;\n      _errorMessage = null;\n    \}\);\n\n    try \{\n      final res = await ApiService\.registerPublic\(\n        _nameController\.text,\n        _emailController\.text,\n        _passwordController\.text,\n      \);\n      if \(res\['success'\] == true\) \{\n        if \(!mounted\) return;\n        ScaffoldMessenger\.of\(context\)\.showSnackBar\(\n          const SnackBar\(content: Text\('Registration successful! Please sign in\.'\)\),\n        \);\n        Navigator\.pushReplacement\(\n          context,\n          MaterialPageRoute\(builder: \(context\) => const LoginScreen\(\)\),\n        \);\n      \} else \{\n        setState\(\(\) => _errorMessage = res\['error'\] \?\? 'Registration failed'\);\n      \}\n    \} catch \(e\) \{\n      setState\(\(\) => _errorMessage = e\.toString\(\)\.replaceAll\('Exception: ', ''\)\);\n    \} finally \{\n      setState\(\(\) => _isLoading = false\);\n    \}\n  \}''', new_logic, content)

content = content.replace("labelText: 'Full Name',", "labelText: 'Shop Name',")
content = content.replace("labelText: 'Email Address',", "labelText: 'Username',")

with open('mobile_app/lib/screens/register_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched register_screen.dart')
