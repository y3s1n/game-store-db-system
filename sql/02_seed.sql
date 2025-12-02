-- ============================================
-- Game Store Database - Sample Data
-- File: 02_seed.sql
-- Description: Inserts sample data for testing and demonstration
-- ============================================

-- ============================================
-- Reference Data
-- ============================================

-- Platforms
INSERT INTO platforms (platform_name, manufacturer, release_year, is_active) VALUES
('PlayStation 5', 'Sony', 2020, true),
('Xbox Series X', 'Microsoft', 2020, true),
('Nintendo Switch', 'Nintendo', 2017, true),
('PC', 'Various', NULL, true),
('PlayStation 4', 'Sony', 2013, true),
('Xbox One', 'Microsoft', 2013, true);

-- Genres
INSERT INTO genres (genre_name, description) VALUES
('Action', 'Fast-paced gameplay with physical challenges'),
('RPG', 'Role-playing games with character development'),
('Sports', 'Sports simulation and arcade games'),
('Adventure', 'Story-driven exploration games'),
('FPS', 'First-person shooter games'),
('Strategy', 'Tactical and strategic gameplay'),
('Racing', 'Racing and driving simulation'),
('Fighting', 'One-on-one combat games'),
('Platformer', 'Jump and run platform games'),
('Puzzle', 'Brain-teasing puzzle games');

-- Publishers
INSERT INTO publishers (publisher_name, country, website) VALUES
('Sony Interactive Entertainment', 'Japan', 'www.sie.com'),
('Microsoft Game Studios', 'USA', 'www.xbox.com'),
('Nintendo', 'Japan', 'www.nintendo.com'),
('Electronic Arts', 'USA', 'www.ea.com'),
('Activision Blizzard', 'USA', 'www.activisionblizzard.com'),
('Ubisoft', 'France', 'www.ubisoft.com'),
('Rockstar Games', 'USA', 'www.rockstargames.com'),
('Square Enix', 'Japan', 'www.square-enix.com');

-- Vendors
INSERT INTO vendors (vendor_name, contact_name, contact_email, contact_phone, is_active) VALUES
('Game Distributors Inc', 'John Smith', 'john@gamedist.com', '555-0101', true),
('Console Wholesale', 'Jane Doe', 'jane@consolewholesale.com', '555-0102', true),
('Accessory World', 'Bob Johnson', 'bob@accessoryworld.com', '555-0103', true);

-- Product Categories
INSERT INTO product_categories (category_name, category_type, description) VALUES
('Home Consoles', 'console', 'Full-sized gaming consoles'),
('Handheld Consoles', 'console', 'Portable gaming devices'),
('Controllers', 'accessory', 'Game controllers and gamepads'),
('Headsets', 'accessory', 'Gaming headsets and audio'),
('Cables & Adapters', 'accessory', 'Connection cables and adapters'),
('Storage', 'accessory', 'Memory cards and external drives');

-- ============================================
-- Store Data
-- ============================================

-- Stores (create stores first without managers)
INSERT INTO stores (store_name, address, city, state, zip_code, phone, opened_date, is_active) VALUES
('Downtown Gaming Center', '123 Main St', 'Seattle', 'WA', '98101', '206-555-0001', '2020-01-15', true),
('Westside Game Shop', '456 West Ave', 'Portland', 'OR', '97201', '503-555-0002', '2020-06-20', true),
('Eastside Games', '789 East Blvd', 'San Francisco', 'CA', '94102', '415-555-0003', '2021-03-10', true);

-- Employees
INSERT INTO employees (store_id, first_name, last_name, email, phone, role, hire_date, salary, is_active) VALUES
(1, 'Alice', 'Johnson', 'alice.johnson@gamestore.com', '206-555-1001', 'store_manager', '2020-01-15', 55000, true),
(1, 'Bob', 'Smith', 'bob.smith@gamestore.com', '206-555-1002', 'sales_associate', '2020-02-01', 35000, true),
(1, 'Carol', 'Davis', 'carol.davis@gamestore.com', '206-555-1003', 'cashier', '2020-03-15', 32000, true),
(2, 'David', 'Wilson', 'david.wilson@gamestore.com', '503-555-2001', 'store_manager', '2020-06-20', 55000, true),
(2, 'Emma', 'Brown', 'emma.brown@gamestore.com', '503-555-2002', 'inventory_clerk', '2020-07-01', 33000, true),
(3, 'Frank', 'Miller', 'frank.miller@gamestore.com', '415-555-3001', 'store_manager', '2021-03-10', 55000, true),
(3, 'Grace', 'Taylor', 'grace.taylor@gamestore.com', '415-555-3002', 'sales_associate', '2021-04-01', 35000, true);

-- Update store managers
UPDATE stores SET manager_id = 1 WHERE store_id = 1;
UPDATE stores SET manager_id = 4 WHERE store_id = 2;
UPDATE stores SET manager_id = 6 WHERE store_id = 3;

-- ============================================
-- Customer Data
-- ============================================

INSERT INTO customers (email, first_name, last_name, phone, date_of_birth, address, city, state, zip_code, loyalty_points, join_date, age_verified) VALUES
('john.gamer@email.com', 'John', 'Gamer', '555-1001', '1995-05-15', '100 Gamer St', 'Seattle', 'WA', '98101', 250, '2021-01-10', true),
('sarah.player@email.com', 'Sarah', 'Player', '555-1002', '1998-08-22', '200 Player Ave', 'Portland', 'OR', '97201', 180, '2021-03-20', true),
('mike.console@email.com', 'Mike', 'Console', '1990-12-05', '555-1003', '300 Console Rd', 'San Francisco', 'CA', '94102', 420, '2020-11-15', true),
('emily.switch@email.com', 'Emily', 'Switch', '2000-03-30', '555-1004', '400 Switch Ln', 'Seattle', 'WA', '98102', 95, '2022-01-05', true),
('alex.rpg@email.com', 'Alex', 'RPG', '1993-07-18', '555-1005', '500 RPG Blvd', 'Portland', 'OR', '97202', 310, '2020-09-30', true);

-- ============================================
-- Game Data
-- ============================================

-- Games
INSERT INTO games (sku, title, platform_id, publisher_id, release_date, esrb_rating, description, base_price, is_digital_only) VALUES
('PS5-001', 'Spider-Man 2', 1, 1, '2023-10-20', 'T', 'Epic superhero adventure in New York', 69.99, false),
('XSX-001', 'Halo Infinite', 2, 2, '2021-12-08', 'T', 'Iconic FPS returns with Master Chief', 59.99, false),
('NSW-001', 'The Legend of Zelda: Tears of the Kingdom', 3, 3, '2023-05-12', 'E10+', 'Epic adventure in Hyrule', 69.99, false),
('PC-001', 'Cyberpunk 2077', 4, 5, '2020-12-10', 'M', 'Futuristic open-world RPG', 49.99, false),
('PS5-002', 'God of War Ragnarök', 1, 1, '2022-11-09', 'M', 'Norse mythology action adventure', 69.99, false),
('XSX-002', 'Forza Horizon 5', 2, 2, '2021-11-09', 'E', 'Open-world racing in Mexico', 59.99, false),
('NSW-002', 'Mario Kart 8 Deluxe', 3, 3, '2017-04-28', 'E', 'Kart racing with Mario characters', 59.99, false),
('PC-002', 'Elden Ring', 4, 7, '2022-02-25', 'M', 'Dark fantasy action RPG', 59.99, false),
('PS4-001', 'The Last of Us Part II', 5, 1, '2020-06-19', 'M', 'Post-apocalyptic action adventure', 39.99, false),
('XBO-001', 'Gears 5', 6, 2, '2019-09-10', 'M', 'Third-person shooter', 29.99, false);

-- Game-Genre relationships
INSERT INTO game_genres (game_id, genre_id) VALUES
(1, 1), (1, 4),  -- Spider-Man: Action, Adventure
(2, 5), (2, 1),  -- Halo: FPS, Action
(3, 4), (3, 2),  -- Zelda: Adventure, RPG
(4, 2), (4, 1),  -- Cyberpunk: RPG, Action
(5, 1), (5, 4),  -- God of War: Action, Adventure
(6, 7),          -- Forza: Racing
(7, 7),          -- Mario Kart: Racing
(8, 2), (8, 1),  -- Elden Ring: RPG, Action
(9, 1), (9, 4),  -- Last of Us: Action, Adventure
(10, 1), (10, 5); -- Gears: Action, FPS

-- Products (Consoles and Accessories)
INSERT INTO products (sku, product_name, category_id, platform_id, description, base_price) VALUES
('CON-PS5-001', 'PlayStation 5 Console', 1, 1, 'Latest Sony gaming console', 499.99),
('CON-XSX-001', 'Xbox Series X Console', 1, 2, 'Microsoft next-gen console', 499.99),
('CON-NSW-001', 'Nintendo Switch OLED', 2, 3, 'Enhanced Switch with OLED screen', 349.99),
('ACC-PS5-001', 'DualSense Wireless Controller', 3, 1, 'PS5 wireless controller', 69.99),
('ACC-XSX-001', 'Xbox Wireless Controller', 3, 2, 'Xbox Series X/S controller', 59.99),
('ACC-NSW-001', 'Switch Pro Controller', 3, 3, 'Premium Nintendo controller', 69.99),
('ACC-HST-001', 'Gaming Headset Universal', 4, NULL, 'Multi-platform gaming headset', 79.99),
('ACC-CAB-001', 'HDMI 2.1 Cable 6ft', 5, NULL, 'High-speed HDMI cable', 19.99),
('ACC-STR-001', '1TB External SSD', 6, NULL, 'Fast external storage', 129.99);

-- ============================================
-- Inventory Data
-- ============================================

-- Inventory for Store 1 (Downtown Gaming Center)
INSERT INTO inventory (store_id, game_id, quantity, reorder_level, last_restocked) VALUES
(1, 1, 15, 5, '2024-11-15'),
(1, 2, 12, 5, '2024-11-15'),
(1, 3, 20, 5, '2024-11-10'),
(1, 4, 8, 5, '2024-11-01'),
(1, 5, 10, 5, '2024-11-12'),
(1, 6, 7, 5, '2024-11-15'),
(1, 7, 18, 5, '2024-11-08'),
(1, 8, 9, 5, '2024-11-15'),
(1, 9, 6, 5, '2024-10-20'),
(1, 10, 5, 5, '2024-10-15');

INSERT INTO inventory (store_id, product_id, quantity, reorder_level, last_restocked) VALUES
(1, 1, 8, 3, '2024-11-01'),
(1, 2, 7, 3, '2024-11-01'),
(1, 3, 12, 3, '2024-11-05'),
(1, 4, 25, 10, '2024-11-15'),
(1, 5, 20, 10, '2024-11-15'),
(1, 6, 15, 10, '2024-11-10'),
(1, 7, 30, 10, '2024-11-12'),
(1, 8, 50, 20, '2024-11-01'),
(1, 9, 10, 5, '2024-11-08');

-- Inventory for Store 2 (Westside Game Shop)
INSERT INTO inventory (store_id, game_id, quantity, reorder_level, last_restocked) VALUES
(2, 1, 10, 5, '2024-11-12'),
(2, 2, 15, 5, '2024-11-10'),
(2, 3, 18, 5, '2024-11-08'),
(2, 4, 6, 5, '2024-10-28'),
(2, 5, 8, 5, '2024-11-10');

INSERT INTO inventory (store_id, product_id, quantity, reorder_level, last_restocked) VALUES
(2, 1, 5, 3, '2024-10-25'),
(2, 2, 6, 3, '2024-10-25'),
(2, 3, 10, 3, '2024-11-01'),
(2, 4, 20, 10, '2024-11-12'),
(2, 5, 18, 10, '2024-11-12');

-- Inventory for Store 3 (Eastside Games)
INSERT INTO inventory (store_id, game_id, quantity, reorder_level, last_restocked) VALUES
(3, 1, 12, 5, '2024-11-14'),
(3, 3, 22, 5, '2024-11-12'),
(3, 7, 20, 5, '2024-11-10'),
(3, 8, 11, 5, '2024-11-15');

INSERT INTO inventory (store_id, product_id, quantity, reorder_level, last_restocked) VALUES
(3, 3, 15, 3, '2024-11-05'),
(3, 6, 18, 10, '2024-11-12'),
(3, 7, 25, 10, '2024-11-10');

-- ============================================
-- Promotion Data
-- ============================================

INSERT INTO promotions (promotion_name, description, discount_percentage, start_date, end_date, is_active) VALUES
('Black Friday 2024', '20% off all games', 20.00, '2024-11-24', '2024-11-30', true),
('Holiday Sale', '15% off consoles and accessories', 15.00, '2024-12-15', '2024-12-31', true),
('New Release Bundle', '10% off when buying 2+ new releases', 10.00, '2024-11-01', '2024-12-31', true);

-- ============================================
-- Order Data
-- ============================================

-- Orders
INSERT INTO orders (customer_id, store_id, employee_id, order_date, status, subtotal, tax_amount, discount_amount, total_amount, payment_method, is_online) VALUES
(1, 1, 2, '2024-11-20 14:30:00', 'delivered', 139.98, 12.60, 0.00, 152.58, 'credit_card', false),
(2, 2, 5, '2024-11-21 10:15:00', 'delivered', 69.99, 6.30, 0.00, 76.29, 'debit_card', false),
(3, NULL, NULL, '2024-11-22 16:45:00', 'shipped', 499.99, 45.00, 0.00, 544.99, 'credit_card', true),
(4, 1, 3, '2024-11-23 11:20:00', 'delivered', 129.98, 11.70, 0.00, 141.68, 'cash', false),
(5, NULL, NULL, '2024-11-24 09:00:00', 'processing', 179.97, 16.20, 35.99, 160.18, 'credit_card', true);

-- Order Items
INSERT INTO order_items (order_id, game_id, quantity, unit_price, discount_amount, line_total) VALUES
(1, 1, 1, 69.99, 0.00, 69.99),
(1, 2, 1, 59.99, 0.00, 59.99);

INSERT INTO order_items (order_id, game_id, quantity, unit_price, discount_amount, line_total) VALUES
(2, 3, 1, 69.99, 0.00, 69.99);

INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount_amount, line_total) VALUES
(3, 1, 1, 499.99, 0.00, 499.99);

INSERT INTO order_items (order_id, game_id, quantity, unit_price, discount_amount, line_total) VALUES
(4, 7, 2, 59.99, 0.00, 119.98);

INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount_amount, line_total) VALUES
(4, 8, 1, 19.99, 0.00, 19.99);

INSERT INTO order_items (order_id, game_id, quantity, unit_price, discount_amount, line_total) VALUES
(5, 4, 1, 49.99, 10.00, 39.99),
(5, 5, 1, 69.99, 14.00, 55.99),
(5, 8, 1, 59.99, 11.99, 47.99);

-- ============================================
-- Pre-Order Data
-- ============================================

-- Note: You would insert pre-orders for games with future release dates
-- This is a placeholder as sample data uses past dates

-- ============================================
-- Loyalty Transaction Data
-- ============================================

INSERT INTO loyalty_transactions (customer_id, order_id, points_earned, points_redeemed, transaction_date, description) VALUES
(1, 1, 15, 0, '2024-11-20 14:30:00', 'Points earned from order'),
(2, 2, 7, 0, '2024-11-21 10:15:00', 'Points earned from order'),
(3, 3, 50, 0, '2024-11-22 16:45:00', 'Points earned from order'),
(4, 4, 14, 0, '2024-11-23 11:20:00', 'Points earned from order'),
(5, 5, 18, 0, '2024-11-24 09:00:00', 'Points earned from order');

-- ============================================
-- Review Data
-- ============================================

INSERT INTO reviews (game_id, customer_id, rating, review_text, review_date, is_verified_purchase) VALUES
(1, 1, 5, 'Amazing game! Best Spider-Man game yet. Graphics are incredible.', '2024-11-22 18:00:00', true),
(3, 2, 5, 'Absolutely loved this Zelda game. So many hours of fun!', '2024-11-23 12:00:00', true),
(7, 4, 4, 'Great kart racing game. Kids love it!', '2024-11-25 15:30:00', true),
(4, 5, 3, 'Good game but had some bugs at launch. Better now after patches.', '2024-11-20 20:00:00', false);

-- ============================================
-- Purchase Order Data (from vendors)
-- ============================================

INSERT INTO purchase_orders (vendor_id, store_id, order_date, expected_delivery_date, status, total_amount) VALUES
(1, 1, '2024-11-01', '2024-11-08', 'delivered', 5000.00),
(2, 1, '2024-10-15', '2024-10-25', 'delivered', 15000.00),
(1, 2, '2024-11-05', '2024-11-12', 'delivered', 3500.00);

INSERT INTO purchase_order_items (po_id, game_id, quantity, unit_cost, line_total) VALUES
(1, 1, 50, 45.00, 2250.00),
(1, 2, 50, 38.00, 1900.00);

INSERT INTO purchase_order_items (po_id, product_id, quantity, unit_cost, line_total) VALUES
(2, 1, 10, 400.00, 4000.00),
(2, 2, 10, 400.00, 4000.00);

INSERT INTO purchase_order_items (po_id, game_id, quantity, unit_cost, line_total) VALUES
(3, 3, 60, 45.00, 2700.00);

-- Data seeding complete
SELECT 'Sample data inserted successfully!' AS status;
