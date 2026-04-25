import mysql.connector

def migrate():
    conn = mysql.connector.connect(
        host='localhost',
        user='root',
        password='',
        database='stocksweep'
    )
    cursor = conn.cursor()
    
    # 1. Create Users Table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        role ENUM('owner', 'cashier') NOT NULL DEFAULT 'cashier'
    )
    """)
    
    # 2. Create Daily Reports Table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS daily_reports (
        id INT AUTO_INCREMENT PRIMARY KEY,
        report_date DATE UNIQUE NOT NULL,
        total_sales DECIMAL(10, 2) NOT NULL,
        total_unpaid DECIMAL(10, 2) NOT NULL,
        expected_cash DECIMAL(10, 2) NOT NULL,
        closed_by INT,
        FOREIGN KEY (closed_by) REFERENCES users(id)
    )
    """)
    
    # 3. Alter Sales Table (Add cashier_id)
    try:
        cursor.execute("ALTER TABLE sales ADD COLUMN cashier_id INT, ADD FOREIGN KEY (cashier_id) REFERENCES users(id)")
    except Exception as e:
        print(f"Sales table already has cashier_id or error: {e}")

    # 4. Add Default Users (Admin: admin123, Cashier: cashier123)
    # In a real app we'd use werkzeug.security.generate_password_hash
    # For now, let's just use plain text or a simple placeholder if we don't have werkzeug yet
    from werkzeug.security import generate_password_hash
    
    admin_pw = generate_password_hash('admin123')
    cashier_pw = generate_password_hash('cashier123')
    
    try:
        cursor.execute("INSERT IGNORE INTO users (username, password_hash, role) VALUES ('admin', %s, 'owner')", (admin_pw,))
        cursor.execute("INSERT IGNORE INTO users (username, password_hash, role) VALUES ('staff', %s, 'cashier')", (cashier_pw,))
    except Exception as e:
        print(f"Error inserting users: {e}")

    conn.commit()
    cursor.close()
    conn.close()
    print("Migration successful!")

if __name__ == "__main__":
    migrate()
