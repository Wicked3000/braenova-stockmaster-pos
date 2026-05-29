import sys
import os
sys.path.append(os.path.abspath('.'))
from database import supabase, parse_shop_plan, make_shop_plan_str
from datetime import datetime, timedelta

def fix_lifetime_plans():
    res = supabase.table('shops').select('id, name, plan').execute()
    shops = res.data
    
    for shop in shops:
        plan_str = shop.get('plan')
        if not plan_str:
            continue
            
        plan_name, expiry_yymmdd, status_char = parse_shop_plan(plan_str)
        
        # If it's a lifetime plan (991231) and NOT StockMasta Base Shop
        if expiry_yymmdd == '991231' and shop['name'] != 'StockMasta Base Shop':
            print(f"Fixing lifetime plan for shop: {shop['name']} (ID: {shop['id']})")
            
            # Set to a monthly plan, expiring 30 days from today
            new_expiry = (datetime.now() + timedelta(days=30)).strftime('%y%m%d')
            new_plan_str = make_shop_plan_str(plan_name, new_expiry, status_char)
            
            # Update the database
            supabase.table('shops').update({"plan": new_plan_str}).eq('id', shop['id']).execute()
            print(f"  -> Updated from {plan_str} to {new_plan_str}")
            
    print("Done checking and fixing plans.")

if __name__ == '__main__':
    fix_lifetime_plans()
