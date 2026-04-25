CREATE DATABASE IF NOT EXISTS stocksweep;
USE stocksweep;
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('owner', 'cashier') NOT NULL DEFAULT 'cashier'
);
CREATE TABLE IF NOT EXISTS inventory (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) DEFAULT 'General',
    quantity INT NOT NULL,
    min_threshold INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    cost_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    image_url VARCHAR(255)
);
CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);
INSERT IGNORE INTO categories (name)
VALUES ('General'),
    ('Drinks'),
    ('Snacks'),
    ('Smokes'),
    ('Essentials');
CREATE TABLE IF NOT EXISTS sales (
    id INT AUTO_INCREMENT PRIMARY KEY,
    inventory_id INT NOT NULL,
    qty_sold INT NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    cost_at_sale DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    is_dinau BOOLEAN DEFAULT FALSE,
    customer_name VARCHAR(255),
    sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cashier_id INT,
    FOREIGN KEY (inventory_id) REFERENCES inventory(id),
    FOREIGN KEY (cashier_id) REFERENCES users(id)
);
CREATE TABLE IF NOT EXISTS dinau_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    status ENUM('unpaid', 'paid') NOT NULL DEFAULT 'unpaid',
    record_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS daily_reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    report_date DATE UNIQUE NOT NULL,
    total_sales DECIMAL(10, 2) NOT NULL,
    total_unpaid DECIMAL(10, 2) NOT NULL,
    expected_cash DECIMAL(10, 2) NOT NULL,
    actual_cash DECIMAL(10, 2),
    difference DECIMAL(10, 2),
    closed_by INT,
    FOREIGN KEY (closed_by) REFERENCES users(id)
);