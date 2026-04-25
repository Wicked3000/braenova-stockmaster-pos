import database
conn = database.get_db_connection()
cursor = conn.cursor()
try:
    # Add restock_notes if not exists
    try:
        cursor.execute("ALTER TABLE daily_reports ADD COLUMN restock_notes TEXT")
        print("restock_notes added")
    except:
        print("restock_notes already exists")
    
    # Add total_profit if not exists
    try:
        cursor.execute("ALTER TABLE daily_reports ADD COLUMN total_profit DECIMAL(10,2) DEFAULT 0.00")
        print("total_profit added")
    except:
        print("total_profit already exists")
        
    conn.commit()
except Exception as e:
    print(f"Error: {e}")
cursor.close()
conn.close()
