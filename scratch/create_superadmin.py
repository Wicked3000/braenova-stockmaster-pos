import os
import sys
from werkzeug.security import generate_password_hash

# Add parent directory to path to import database
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from database import supabase

def setup_superadmins():
    password = "BraeNovaAdmin2026!"
    password_hash = generate_password_hash(password)
    
    print("=== SETTING UP SUPERADMINS ===")
    
    # 1. Reset the existing 'superadmin' password
    try:
        res = supabase.table('users').update({
            "password_hash": password_hash,
            "is_active": 1
        }).eq('username', 'superadmin').execute()
        if res.data:
            print("Successfully updated password for existing user 'superadmin'.")
        else:
            print("User 'superadmin' not found in database.")
    except Exception as e:
        print(f"Error updating 'superadmin': {e}")
        
    # 2. Create a new 'braenova_admin' superadmin
    try:
        # Check if it already exists
        check = supabase.table('users').select('*').eq('username', 'braenova_admin').execute()
        if check.data:
            res = supabase.table('users').update({
                "password_hash": password_hash,
                "role": "superadmin",
                "is_active": 1,
                "shop_id": None
            }).eq('username', 'braenova_admin').execute()
            print("Successfully updated existing 'braenova_admin' user.")
        else:
            res = supabase.table('users').insert({
                "username": "braenova_admin",
                "password_hash": password_hash,
                "role": "superadmin",
                "is_active": 1,
                "shop_id": None
            }).execute()
            print("Successfully created new superadmin user 'braenova_admin'.")
    except Exception as e:
        print(f"Error setting up 'braenova_admin': {e}")
        
    print(f"\nLogin Details:\n- Username: braenova_admin (or superadmin)\n- Password: {password}\n- Role: superadmin")

if __name__ == "__main__":
    setup_superadmins()
