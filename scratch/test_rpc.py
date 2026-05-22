import database

rpc_names = ["exec_sql", "run_sql", "execute_sql", "sql", "query"]
for name in rpc_names:
    try:
        # Try running with sql parameter
        res = database.supabase.rpc(name, {"sql": "SELECT 1"}).execute()
        print(f"Success with {name} (sql):", res.data)
        break
    except Exception as e:
        print(f"Failed with {name} (sql):", e)
        
    try:
        # Try running with query parameter
        res = database.supabase.rpc(name, {"query": "SELECT 1"}).execute()
        print(f"Success with {name} (query):", res.data)
        break
    except Exception as e:
        print(f"Failed with {name} (query):", e)
