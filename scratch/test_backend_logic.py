import sys
import os
sys.path.append(os.path.abspath('.'))

import datetime
from database import (
    supabase, parse_shop_plan, make_shop_plan_str, verify_user,
    approve_shop_payment, extend_shop_subscription, reset_password_by_admin
)
from werkzeug.security import generate_password_hash, check_password_hash

# Setup temporary shop and user for testing
temp_shop_id = None
temp_user_id = None

def setup_test_data():
    global temp_shop_id, temp_user_id
    print("Setting up temporary test shop and user...")
    # Insert a dummy shop
    # Status 'p' (pending)
    plan_str = make_shop_plan_str("starter", "260622", "p", "monthly")
    shop_res = supabase.table('shops').insert({
        "name": "Temp Test Shop",
        "is_active": False,
        "plan": plan_str
    }).execute()
    if shop_res.data:
        temp_shop_id = shop_res.data[0]['id']
        
        # Insert a dummy user
        hashed = generate_password_hash("password123")
        user_res = supabase.table('users').insert({
            "username": "temp_test_user",
            "password_hash": hashed,
            "role": "owner",
            "is_active": 1,
            "shop_id": temp_shop_id
        }).execute()
        if user_res.data:
            temp_user_id = user_res.data[0]['id']
            # Link owner back to the shop's owner_id
            supabase.table('shops').update({"owner_id": temp_user_id}).eq('id', temp_shop_id).execute()
    print(f"Setup complete. Temp Shop ID: {temp_shop_id}, Temp User ID: {temp_user_id}")

def cleanup_test_data():
    global temp_shop_id, temp_user_id
    print("Cleaning up temporary test shop and user...")
    if temp_shop_id:
        try:
            # Step 1: Unlink owner_id in shops to allow deleting user
            supabase.table('shops').update({"owner_id": None}).eq('id', temp_shop_id).execute()
        except Exception as e:
            print(f"Error unlinking temp shop owner: {e}")
            
    if temp_user_id:
        try:
            # Step 2: Delete user who references the shop
            supabase.table('users').delete().eq('id', temp_user_id).execute()
        except Exception as e:
            print(f"Error deleting temp user: {e}")
            
    if temp_shop_id:
        try:
            # Step 3: Delete shop
            supabase.table('shops').delete().eq('id', temp_shop_id).execute()
        except Exception as e:
            print(f"Error deleting temp shop: {e}")
            
    print("Cleanup complete.")

def test_plan_helpers():
    print("Testing plan parsing helpers...")
    assert parse_shop_plan("starter:260622:p") == ("starter", "260622", "p", "monthly")
    assert parse_shop_plan("pro") == ("pro", "991231", "a", "monthly")
    assert parse_shop_plan(None) == ("starter", "991231", "a", "monthly")
    
    assert make_shop_plan_str("pro", "260822", "a") == "pro:260822:a:m"
    print("[OK] Plan helpers OK")

def test_master_password_bypass():
    print("Testing master password override...")
    # Get user 10 (braenova_admin)
    res = supabase.table('users').select('*').eq('username', 'braenova_admin').execute()
    if not res.data:
        print("Skipping: user 'braenova_admin' not found.")
        return
        
    user = res.data[0]
    # Standard password should fail if wrong
    assert verify_user('braenova_admin', 'wrong_pass') is None
    
    # Master password override should succeed and bypass hashing check
    verified = verify_user('braenova_admin', 'StockMastaMaster2026!')
    assert verified is not None
    assert verified['username'] == 'braenova_admin'
    print("[OK] Master password override OK")

def test_subscription_expiration():
    print("Testing subscription expiration logic...")
    if not temp_shop_id or not temp_user_id:
        print("Skipping: Temp test data not set up.")
        return
        
    # Temporarily set shop to expired: starter:200501:e (expired May 1st 2020)
    old_plan = "starter:200501:a:m"
    supabase.table('shops').update({"plan": old_plan, "is_active": True}).eq('id', temp_shop_id).execute()
    
    # Trying to verify 'temp_test_user' should return 'expired'
    res = verify_user('temp_test_user', 'StockMastaMaster2026!')
    assert res == 'expired'
    
    # Let's activate it and verify it's OK now
    today = datetime.datetime.now()
    expiry = (today + datetime.timedelta(days=30)).strftime('%y%m%d')
    new_plan = make_shop_plan_str("starter", expiry, "a")
    supabase.table('shops').update({"plan": new_plan, "is_active": True}).eq('id', temp_shop_id).execute()
    
    res = verify_user('temp_test_user', 'StockMastaMaster2026!')
    assert isinstance(res, dict)
    assert res['username'] == 'temp_test_user'
    print("[OK] Expiration logic OK")

def test_payment_approval():
    print("Testing payment approval...")
    if not temp_shop_id:
        print("Skipping: Temp shop not set up.")
        return
        
    # Set back to pending
    pending_plan = make_shop_plan_str("starter", "260622", "p", "monthly")
    supabase.table('shops').update({"plan": pending_plan, "is_active": False}).eq('id', temp_shop_id).execute()
    
    # Approve payment
    approve_shop_payment(temp_shop_id, 'starter', 3) # Approve for 3 months
    
    # Check shop details
    res = supabase.table('shops').select('*').eq('id', temp_shop_id).execute()
    assert res.data
    shop = res.data[0]
    assert shop['is_active'] == True
    
    plan, expiry, status, cycle = parse_shop_plan(shop['plan'])
    assert plan == 'starter'
    assert status == 'a'
    
    # Expiry should be roughly 90 days from now
    expected_expiry = (datetime.datetime.now() + datetime.timedelta(days=90)).strftime('%y%m%d')
    assert expiry == expected_expiry
    print("[OK] Payment approval OK")

def test_password_reset():
    print("Testing admin password reset...")
    # Get user 10 (braenova_admin)
    res = supabase.table('users').select('*').eq('id', 10).execute()
    if not res.data:
        print("Skipping: user 10 not found.")
        return
        
    original_hash = res.data[0]['password_hash']
    
    # Reset password
    new_hash = generate_password_hash("TestNewPassword123!")
    reset_password_by_admin(10, new_hash)
    
    # Check that new hash is set and works
    res2 = supabase.table('users').select('password_hash').eq('id', 10).execute()
    assert res2.data
    assert check_password_hash(res2.data[0]['password_hash'], "TestNewPassword123!")
    
    # Revert hash
    reset_password_by_admin(10, original_hash)
    print("[OK] Password reset OK")

def test_days_left():
    print("Testing days_left logic...")
    from database import get_all_shops
    shops = get_all_shops()
    for s in shops:
        assert 'days_left' in s
        if s['expiry_date'] == '991231':
            assert s['days_left'] is None
        else:
            assert isinstance(s['days_left'], int) or s['days_left'] is None
    print("[OK] days_left check OK")

if __name__ == '__main__':
    try:
        setup_test_data()
        test_plan_helpers()
        test_days_left()
        test_master_password_bypass()
        test_subscription_expiration()
        test_payment_approval()
        test_password_reset()
        print("\nAll backend logic checks passed successfully!")
    except AssertionError as e:
        print(f"\n[FAIL] Assertion failed: {e}")
        import traceback
        traceback.print_exc()
        cleanup_test_data()
        sys.exit(1)
    except Exception as e:
        print(f"\n[ERROR] Test run encountered error: {e}")
        import traceback
        traceback.print_exc()
        cleanup_test_data()
        sys.exit(1)
    
    cleanup_test_data()
