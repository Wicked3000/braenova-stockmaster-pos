import sys
import os
sys.path.append(os.path.abspath('.'))

from database import supabase, get_all_shops

print("=== SHOPS ===")
shops = get_all_shops()
for s in shops:
    print(f"ID: {s['id']}, Name: {s['name']}, Active: {s['is_active']}, Plan: {s.get('plan')}, Owner: {s.get('owner_username')}")

print("\n=== USERS ===")
users_res = supabase.table('users').select('id, username, role, is_active, shop_id').execute()
for u in users_res.data:
    print(f"ID: {u['id']}, Username: {u['username']}, Role: {u['role']}, Active: {u['is_active']}, Shop ID: {u['shop_id']}")
