import mysql.connector
from werkzeug.security import generate_password_hash

def apply():
    db_config = {
        'host': 'localhost',
        'user': 'root',
        'password': '',
        'database': 'stocksweep'
    }
    
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()
        
        print("Connected to database...")

        # Create users table
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            role ENUM('owner', 'cashier') NOT NULL DEFAULT 'cashier'
        )
        """)
        print("Users table checked/created.")

        # Create daily_reports table
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
        print("Reports table checked/created.")

        # Alter sales
        try:
            cursor.execute("ALTER TABLE sales ADD COLUMN cashier_id INT")
            cursor.execute("ALTER TABLE sales ADD FOREIGN KEY (cashier_id) REFERENCES users(id)")
            print("Sales table altered.")
        except:
            print("Sales table already has cashier_id.")

        # Add default users
        admin_hash = generate_password_hash('admin123')
        staff_hash = generate_password_hash('staff123')
        
        cursor.execute("INSERT IGNORE INTO users (username, password_hash, role) VALUES ('admin', %s, 'owner')", (admin_hash,))
        cursor.execute("INSERT IGNORE INTO users (username, password_hash, role) VALUES ('staff', %s, 'cashier')", (staff_hash,))
        
        conn.commit()
        print("Default users initialized.")
        
        cursor.close()
        conn.close()
        print("Migration complete!")
        
    except Exception as e:
        print(f"Error during migration: {e}")

if __name__ == "__main__":
    apply()
