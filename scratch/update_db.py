import database
conn = database.get_db_connection()
cursor = conn.cursor()
try:
    cursor.execute("ALTER TABLE sales ADD COLUMN is_closed TINYINT(1) DEFAULT 0")
    print("Column added successfully")
except Exception as e:
    print(f"Error or already exists: {e}")
conn.commit()
cursor.close()
conn.close()
