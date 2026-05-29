import sys
import os
sys.path.append(os.path.abspath('.'))
from database import verify_user

print("Verifying testowner:")
res = verify_user('testowner', 'StockMastaMaster2026!')
print(res)
