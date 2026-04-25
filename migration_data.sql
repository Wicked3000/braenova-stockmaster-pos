-- DATA FOR users
INSERT INTO users (id, username, password_hash, role, is_active) VALUES (1, 'admin', 'scrypt:32768:8:1$77srEiDRrG3iiVm8$56f71b11b61092a1857983b038fc379022420ff4e262f9130f56086a67202c2e355d4adf9dbc072b39a8b20e911b8c8df9f40cd2492622871c508e697d1e1af0', 'owner', 1);
INSERT INTO users (id, username, password_hash, role, is_active) VALUES (2, 'staff', 'scrypt:32768:8:1$3t7Q9zWEa15dRHFO$bd01156790aacbb7bbc403130c5d0fbdccd1c10eebb79646b27da3ae60550f6edf9ee504c92495e67b90e32e44fe3525a310dd2b60e1854995f7b75f62948805', 'cashier', 1);
INSERT INTO users (id, username, password_hash, role, is_active) VALUES (3, 'test', 'scrypt:32768:8:1$9DQpxqLtP6Dm3bqv$57cebe96ea97434fe7d7036387b03542f4a569b0ff975a016c952f34713d1daa988da16b8479c18d5969a180ac5fd6449773d5118fb8ae58d06f4558d81a8d62', 'cashier', 1);
-- DATA FOR categories
INSERT INTO categories (id, name) VALUES (2, 'Drinks');
INSERT INTO categories (id, name) VALUES (5, 'Essentials');
INSERT INTO categories (id, name) VALUES (1, 'General');
INSERT INTO categories (id, name) VALUES (4, 'Smokes');
INSERT INTO categories (id, name) VALUES (3, 'Snacks');
INSERT INTO categories (id, name) VALUES (6, 'Toys');
-- DATA FOR inventory
INSERT INTO inventory (id, item_name, quantity, min_threshold, unit_price, image_url, cost_price, category, expiry_date, is_active) VALUES (1, 'Coke 330ml', 54, 10, '3.50', '/static/uploads/66618-cover.jpg', '0.00', 'General', NULL, 1);
INSERT INTO inventory (id, item_name, quantity, min_threshold, unit_price, image_url, cost_price, category, expiry_date, is_active) VALUES (2, 'Paradise Biscuit', 40, 15, '1.20', '/static/uploads/R.jpg', '0.00', 'General', NULL, 1);
INSERT INTO inventory (id, item_name, quantity, min_threshold, unit_price, image_url, cost_price, category, expiry_date, is_active) VALUES (3, 'Ox & Palm', 45, 5, '5.00', '/static/uploads/Screenshot_2026-04-21_181945.png', '0.00', 'General', NULL, 1);
INSERT INTO inventory (id, item_name, quantity, min_threshold, unit_price, image_url, cost_price, category, expiry_date, is_active) VALUES (5, 'Sprite 330 ML', 46, 5, '3.00', '/static/uploads/spritecan.jpg', '0.00', 'General', NULL, 1);
INSERT INTO inventory (id, item_name, quantity, min_threshold, unit_price, image_url, cost_price, category, expiry_date, is_active) VALUES (6, 'test', 0, 5, '3.00', '/static/uploads/Untitled_Project_-_Mockup_2.png', '32.00', 'Drinks', NULL, 0);
-- DATA FOR dinau_records
INSERT INTO dinau_records (id, customer_name, amount, status, record_date) VALUES (6, 'Peter Nau', '13.50', 'unpaid', '2026-04-21 18:00:29');
-- DATA FOR sales
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (1, 1, 2, '3.50', '2026-04-21 11:39:35', NULL, 0, NULL, '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (2, 1, 2, '3.50', '2026-04-21 11:39:41', NULL, 0, NULL, '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (3, 1, 1, '3.50', '2026-04-21 11:39:45', NULL, 0, NULL, '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (4, 1, 2, '7.00', '2026-04-21 15:25:14', 1, 0, '', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (5, 2, 1, '1.20', '2026-04-21 15:25:14', 1, 0, '', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (6, 5, 1, '3.00', '2026-04-21 15:25:14', 1, 0, '', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (7, 3, 1, '5.00', '2026-04-21 15:27:13', 1, 0, '', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (8, 5, 1, '3.00', '2026-04-21 16:00:01', 1, 1, 'Paul Peter', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (9, 3, 1, '5.00', '2026-04-21 16:00:01', 1, 1, 'Paul Peter', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (10, 2, 1, '1.20', '2026-04-21 16:00:01', 1, 1, 'Paul Peter', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (11, 2, 2, '2.40', '2026-04-21 16:03:15', 1, 1, 'Peter Sala', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (12, 3, 2, '10.00', '2026-04-21 16:03:15', 1, 1, 'Peter Sala', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (13, 1, 1, '3.50', '2026-04-21 18:00:29', 3, 1, 'Peter Nau', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (14, 3, 2, '10.00', '2026-04-21 18:00:29', 3, 1, 'Peter Nau', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (15, 3, 3, '15.00', '2026-04-21 18:43:38', 1, 0, '', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (16, 3, 3, '15.00', '2026-04-21 18:43:49', 1, 0, '', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (17, 3, 3, '15.00', '2026-04-21 18:43:54', 1, 0, '', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (18, 1, 1, '3.50', '2026-04-21 18:46:19', 1, 0, '', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (19, 1, 1, '3.50', '2026-04-21 18:46:28', 1, 0, '', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (20, 1, 2, '7.00', '2026-04-21 18:49:13', 1, 0, '', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (21, 1, 3, '10.50', '2026-04-21 18:51:51', 1, 0, '', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (22, 2, 1, '1.20', '2026-04-21 18:51:51', 1, 0, '', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (23, 1, 2, '7.00', '2026-04-21 18:53:51', 1, 0, '', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (24, 2, 2, '2.40', '2026-04-21 18:54:30', 1, 0, '', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (25, 1, 1, '3.50', '2026-04-21 18:54:30', 1, 0, '', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (26, 2, 3, '3.60', '2026-04-21 18:54:45', 1, 0, '', '0.00', 'cash', 1);
INSERT INTO sales (id, inventory_id, qty_sold, total_price, sale_date, cashier_id, is_dinau, customer_name, cost_at_sale, payment_method, is_closed) VALUES (27, 6, 5, '15.00', '2026-04-22 08:11:40', 1, 0, '', '160.00', 'cash', 1);
-- DATA FOR daily_reports
INSERT INTO daily_reports (id, report_date, total_sales, total_unpaid, expected_cash, closed_by, actual_cash, difference, total_profit, restock_notes) VALUES (1, '2026-04-22 00:00:00', '15.00', '0.00', '15.00', NULL, '15.00', '0.00', '-145.00', 'This is a test');
INSERT INTO daily_reports (id, report_date, total_sales, total_unpaid, expected_cash, closed_by, actual_cash, difference, total_profit, restock_notes) VALUES (3, '2026-04-22 08:26:33', '0.00', '0.00', '0.00', NULL, '0.00', '0.00', '0.00', 'test');