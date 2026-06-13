import re

with open('mobile_app/lib/core/api_client.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add register
register_method = '''
  Future<Response> register(Map<String, dynamic> data) async {
    return await dio.post('/auth/register', data: data);
  }
'''
if 'register(' not in content:
    content = content.replace('Future<Response> login(String username, String password) async {', register_method + '  Future<Response> login(String username, String password) async {')

# Add resetCashierPassword
reset_method = '''
  Future<Response> resetCashierPassword(int cashierId, String newPassword) async {
    return await dio.put('/cashiers/\/reset', data: {'password': newPassword});
  }
'''
if 'resetCashierPassword' not in content:
    content = content.replace('Future<Response> deleteCashier(int cashierId) async {', reset_method + '  Future<Response> deleteCashier(int cashierId) async {')

with open('mobile_app/lib/core/api_client.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched api_client.dart')
