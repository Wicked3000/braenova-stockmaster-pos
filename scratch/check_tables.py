import sys
import os
import requests
sys.path.append(os.path.abspath('.'))
from database import SUPABASE_URL, SUPABASE_KEY

def get_tables():
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}"
    }
    # Trying to hit the openapi spec to get table names
    res = requests.get(f"{SUPABASE_URL}/rest/v1/?apikey={SUPABASE_KEY}", headers=headers)
    if res.ok:
        data = res.json()
        if 'paths' in data:
            tables = [path.strip('/') for path in data['paths'].keys() if path != '/']
            print("Tables found:", tables)
        else:
            print("Paths not found in openapi spec")
    else:
        print("Failed to get openapi spec:", res.status_code, res.text)

if __name__ == '__main__':
    get_tables()
