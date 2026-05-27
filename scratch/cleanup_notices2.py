import os
from supabase import create_client, Client

SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://iuzlrtkhwkcfvnvvlshm.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1emxydGtod2tjZnZudnZsc2htIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyMTYwOTAsImV4cCI6MjA5MTc5MjA5MH0.EuGx7tRk8-x2fF3huD8w5Fr8ahw2_LyJbAhlNyUzl5A")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def cleanup_more_notices():
    supabase.table('notices').delete().eq('id', 1).execute()
    supabase.table('notices').delete().eq('id', 2).execute()
    print("Deleted notices 1 and 2.")

if __name__ == '__main__':
    cleanup_more_notices()
