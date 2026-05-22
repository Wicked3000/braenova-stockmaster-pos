import httpx
import json
import os

SUPABASE_URL = "https://iuzlrtkhwkcfvnvvlshm.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1emxydGtod2tjZnZudnZsc2htIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyMTYwOTAsImV4cCI6MjA5MTc5MjA5MH0.EuGx7tRk8-x2fF3huD8w5Fr8ahw2_LyJbAhlNyUzl5A"

headers = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}"
}

try:
    response = httpx.get(f"{SUPABASE_URL}/rest/v1/", headers=headers)
    schema = response.json()
    with open("scratch/supabase_schema.json", "w") as f:
        json.dump(schema, f, indent=2)
    print("Schema fetched successfully!")
    print("Paths/RPCs:")
    for path in schema.get("paths", {}).keys():
        print(path)
except Exception as e:
    print(f"Error fetching schema: {e}")
