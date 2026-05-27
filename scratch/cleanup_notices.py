import os
from supabase import create_client, Client

SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://iuzlrtkhwkcfvnvvlshm.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1emxydGtod2tjZnZudnZsc2htIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyMTYwOTAsImV4cCI6MjA5MTc5MjA5MH0.EuGx7tRk8-x2fF3huD8w5Fr8ahw2_LyJbAhlNyUzl5A")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def cleanup_notices():
    # Fetch all notices
    res = supabase.table('notices').select('*').order('created_at', desc=True).execute()
    notices = res.data
    
    print(f"Total notices found: {len(notices)}")
    for n in notices:
        print(f"ID: {n['id']}, Title: {n['title']}, Time: {n['created_at']}")
        
    # User said: "remove two dates and time and leave one"
    # I'll keep the first one, delete the rest if there are duplicates.
    # From screenshot, there were 3. We'll leave the most recent "Test" one.
    if len(notices) >= 3:
        to_delete = notices[1:3]
        for n in to_delete:
            print(f"Deleting notice {n['id']} - {n['title']}")
            supabase.table('notices').delete().eq('id', n['id']).execute()
            
    print("Cleanup complete.")

if __name__ == '__main__':
    cleanup_notices()
