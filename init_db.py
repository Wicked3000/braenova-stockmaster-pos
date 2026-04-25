import mysql.connector

# Connect without specifying database to create it first
conn = mysql.connector.connect(
    host='localhost',
    user='root',
    password=''
)

cursor = conn.cursor()

with open('schema.sql', 'r') as f:
    sql_file = f.read()

sql_commands = sql_file.split(';')

for command in sql_commands:
    if command.strip():
        cursor.execute(command)

conn.commit()
cursor.close()
conn.close()

# Add some dummy inventory
import database
conn = database.get_db_connection()
cursor = conn.cursor()
cursor.execute("INSERT INTO inventory (item_name, quantity, min_threshold, unit_price) VALUES ('Coke 330ml', 24, 10, 3.50), ('Paradise Biscuit', 50, 15, 1.20), ('Ox & Palm', 12, 5, 5.00)")
conn.commit()
cursor.close()
conn.close()

print("Database initialized and dummy data added!")
