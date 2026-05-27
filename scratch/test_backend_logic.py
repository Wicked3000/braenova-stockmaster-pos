import sys
import os
sys.path.append(os.path.abspath('.'))

import datetime
from database import (
    supabase, parse_shop_plan, make_shop_plan_str, verify_user,
    approve_shop_payment, extend_shop_subscription, reset_password_by_admin
)
from werkzeug.security import generate_password_hash, check_password_hash

def test_plan_helpers():
    print("Testing plan parsing helpers...")
    assert parse_shop_plan("starter:260622:p") == ("starter", "260622", "p")
    assert parse_shop_plan("pro") == ("pro", "991231", "a")
    assert parse_shop_plan(None) == ("starter", "991231", "a")
    
    assert make_shop_plan_str("pro", "260822", "a") == "pro:260822:a"
    print("[OK] Plan helpers OK")

def test_master_password_bypass():
    print("Testing master password override...")
    # Get user 1 (admin)
    res = supabase.table('users').select('*').eq('username', 'admin').execute()
    if not res.data:
        print("Skipping: user 'admin' not found.")
        return
        
    user = res.data[0]
    # Standard password should fail if wrong
    assert verify_user('admin', 'wrong_pass') is None
    
    # Master password override should succeed and bypass hashing check
    verified = verify_user('admin', 'BraeNovaMaster2026!')
    assert verified is not None
    assert verified['username'] == 'admin'
    print("[OK] Master password override OK")

def test_subscription_expiration():
    print("Testing subscription expiration logic...")
    # Temporarily set shop 4 to expired: starter:200501:e (expired May 1st 2020)
    old_plan = "starter:200501:a"
    supabase.table('shops').update({"plan": old_plan, "is_active": True}).eq('id', 4).execute()
    
    # Trying to verify 'vadmin' (owner of shop 4) should return 'expired'
    res = verify_user('vadmin', 'BraeNovaMaster2026!')
    assert res == 'expired'
    
    # Let's activate it and verify it's OK now
    today = datetime.datetime.now()
    expiry = (today + datetime.timedelta(days=30)).strftime('%y%m%d')
    new_plan = make_shop_plan_str("starter", expiry, "a")
    supabase.table('shops').update({"plan": new_plan, "is_active": True}).eq('id', 4).execute()
    
    res = verify_user('vadmin', 'BraeNovaMaster2026!')
    assert isinstance(res, dict)
    assert res['username'] == 'vadmin'
    print("[OK] Expiration logic OK")

def test_payment_approval():
    print("Testing payment approval...")
    # Shop 5 is currently pending: starter:260622:p
    approve_shop_payment(5, 'starter', 3) # Approve for 3 months
    
    # Check shop 5 details
    res = supabase.table('shops').select('*').eq('id', 5).execute()
    assert res.data
    shop = res.data[0]
    assert shop['is_active'] == True
    
    plan, expiry, status = parse_shop_plan(shop['plan'])
    assert plan == 'starter'
    assert status == 'a'
    
    # Expiry should be roughly 90 days from now
    expected_expiry = (datetime.datetime.now() + datetime.timedelta(days=90)).strftime('%y%m%d')
    assert expiry == expected_expiry
    
    # Revert shop 5 back to pending for manual testing
    pending_plan = make_shop_plan_str("starter", "260622", "p")
    supabase.table('shops').update({"plan": pending_plan, "is_active": False}).eq('id', 5).execute()
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
def test_days_left():
    print("Testing days_left logic...")
    from database import get_all_shops
    shops = get_all_shops()
    for s in shops:
        assert 'days_left' in s
        if s['expiry_date'] == '991231':
            assert s['days_left'] is None
        else:
            assert isinstance(s['days_left'], int)
    print("[OK] days_left check OK")

if __name__ == '__main__':
    try:
        test_plan_helpers()
        test_days_left()
        test_master_password_bypass()
        test_subscription_expiration()
        test_payment_approval()
        test_password_reset()
        print("\nAll backend logic checks passed successfully!")
    except AssertionError as e:
        print(f"\n[FAIL] Assertion failed: {e}")
        sys.exit(1)
