import database

def migrate():
    conn = database.get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # Tables to migrate
    tables = ['users', 'categories', 'inventory', 'dinau_records', 'sales', 'daily_reports']
    
    all_sql = []
    for table in tables:
        cursor.execute(f"SELECT * FROM {table}")
        rows = cursor.fetchall()
        if not rows: continue
        
        cols = ", ".join(rows[0].keys())
        all_sql.append(f"-- DATA FOR {table}")
        for row in rows:
            vals = []
            for v in row.values():
                if v is None: vals.append("NULL")
                elif isinstance(v, (int, float)): vals.append(str(v))
                else: vals.append("'" + str(v).replace("'", "''") + "'")
            all_sql.append(f"INSERT INTO {table} ({cols}) VALUES ({', '.join(vals)});")
            
    with open('migration_data.sql', 'w') as f:
        f.write("\n".join(all_sql))
    
    cursor.close()
    conn.close()

if __name__ == "__main__":
    migrate()
