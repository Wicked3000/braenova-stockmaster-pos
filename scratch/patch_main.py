import re

with open('mobile_app/lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

imports = '''import 'screens/sales_history_screen.dart';
import 'screens/cashiers_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/register_screen.dart';'''
content = content.replace("import 'screens/sales_history_screen.dart';\nimport 'screens/cashiers_screen.dart';", imports)

routes = '''      GoRoute(
        path: '/cashiers',
        builder: (context, state) => const CashiersScreen(),
      ),
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpensesScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),'''
content = content.replace('''      GoRoute(
        path: '/cashiers',
        builder: (context, state) => const CashiersScreen(),
      ),''', routes)

with open('mobile_app/lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched main.dart')
