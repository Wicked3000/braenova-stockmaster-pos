import re

with open('mobile_app/lib/core/api_client.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("return await dio.put('/cashiers/\/reset', data: {'password': newPassword});", "return await dio.put('/cashiers/\/reset', data: {'password': newPassword});")

with open('mobile_app/lib/core/api_client.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched api_client.dart again')
