import app
from database import supabase

def test_routes():
    client = app.app.test_client()
    with client.session_transaction() as sess:
        sess['user_id'] = 1
        sess['shop_id'] = 1
        sess['username'] = 'admin'
        sess['role'] = 'owner'
        sess['plan'] = 'multi'

    endpoints = [
        '/', '/dashboard', '/pos', '/inventory', '/sales-log', '/reports', '/shops/profile', '/dinau', '/inventory/centralized'
    ]
    for ep in endpoints:
        resp = client.get(ep)
        print(f"[{resp.status_code}] GET {ep}")
        if resp.status_code == 500:
            print("ERROR on", ep)
            try:
                app.app.config['TESTING'] = True
                client.get(ep)
            except Exception as e:
                import traceback
                traceback.print_exc()

test_routes()
