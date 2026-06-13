import re

with open('mobile_app/lib/screens/main_layout.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Cashiers should only see POS and Menu in bottom nav
content = content.replace('''
    // Bottom Nav: Max 5 items (Dashboard, POS, Inventory, Dinau, Menu)
    List<Map<String, dynamic>> bottomNav = [
      {'route': '/dashboard', 'label': 'Dashboard', 'icon': 'assets/icons/dashboard.svg'},
      {'route': '/pos', 'label': 'POS', 'icon': 'assets/icons/pos.svg'},
      {'route': '/inventory', 'label': 'Inventory', 'icon': 'assets/icons/inventory.svg'},
      {'route': '/dinau', 'label': 'Dinau', 'icon': 'assets/icons/dinau.svg'},
      {'route': '/menu', 'label': 'Menu', 'icon': Icons.menu_rounded},
    ];
''', '''
    // Bottom Nav: Max 5 items (Dashboard, POS, Inventory, Dinau, Menu)
    List<Map<String, dynamic>> bottomNav = [];
    if (role == 'owner' || role == 'superadmin') {
      bottomNav = [
        {'route': '/dashboard', 'label': 'Dashboard', 'icon': 'assets/icons/dashboard.svg'},
        {'route': '/pos', 'label': 'POS', 'icon': 'assets/icons/pos.svg'},
        {'route': '/inventory', 'label': 'Inventory', 'icon': 'assets/icons/inventory.svg'},
        {'route': '/dinau', 'label': 'Dinau', 'icon': 'assets/icons/dinau.svg'},
        {'route': '/menu', 'label': 'Menu', 'icon': Icons.menu_rounded},
      ];
    } else {
      bottomNav = [
        {'route': '/pos', 'label': 'POS', 'icon': 'assets/icons/pos.svg'},
        {'route': '/menu', 'label': 'Menu', 'icon': Icons.menu_rounded},
      ];
    }
''')

# Initial route
content = content.replace("String currentRoute = widget.initialRoute ?? '/dashboard';", "String currentRoute = widget.initialRoute ?? (_role == 'cashier' ? '/pos' : '/dashboard');")

with open('mobile_app/lib/screens/main_layout.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched main_layout.dart')
