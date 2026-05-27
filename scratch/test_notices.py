import sys
import os
sys.path.append(os.path.abspath('.'))
from database import create_notice, get_notices

def test_notices():
    print("Testing specific user notices...")
    create_notice("Specific User Notice", "This is a test notice for user 12.", "user:12")
    
    print("\n--- User 12 sees: ---")
    print(get_notices('owner', user_id=12))
    
    print("\n--- User 13 sees: ---")
    print(get_notices('owner', user_id=13))
    
    print("\n--- Superadmin sees: ---")
    print(get_notices('superadmin'))

if __name__ == "__main__":
    test_notices()
