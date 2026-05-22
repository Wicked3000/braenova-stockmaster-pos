import sys
import os

# Add parent directory to path to import database
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from database import supabase, SUPABASE_URL, SUPABASE_KEY
import requests

def clear_data():
    print("Clearing sales...")
    supabase.table('sales').delete().neq('id', 0).execute()
    print("Clearing daily_reports...")
    supabase.table('daily_reports').delete().neq('id', 0).execute()
    print("Clearing dinau_records...")
    supabase.table('dinau_records').delete().neq('id', 0).execute()
    print("Clearing inventory...")
    supabase.table('inventory').delete().neq('id', 0).execute()
    print("All test data cleared!")

def setup_bucket():
    print("Setting up 'products' bucket...")
    url = f"{SUPABASE_URL}/storage/v1/bucket"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json"
    }
    payload = {
        "id": "products",
        "name": "products",
        "public": True
    }
    resp = requests.post(url, json=payload, headers=headers)
    if resp.status_code in [200, 201]:
        print("Bucket 'products' created successfully.")
    elif resp.status_code == 400 and "already exists" in resp.text:
        print("Bucket 'products' already exists. Making sure it is public...")
        requests.put(f"{url}/products", json={"public": True}, headers=headers)
    else:
        print(f"Failed to create bucket: {resp.status_code} - {resp.text}")

if __name__ == "__main__":
    clear_data()
    setup_bucket()
