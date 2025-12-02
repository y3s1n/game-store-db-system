-- ============================================
-- Game Store Database - Indexes
-- File: 06_indexes.sql
-- Description: Performance indexes with optimization rationale
-- ============================================

-- ============================================
-- Games Table Indexes
-- ============================================

-- Index: Games by platform and price (for catalog browsing)
CREATE INDEX idx_games_platform_price ON games(platform_id, base_price);
COMMENT ON INDEX idx_games_platform_price IS 
'Optimizes queries filtering games by platform and sorting by price';

-- Index: Games by release date (for new releases, upcoming games)
CREATE INDEX idx_games_release_date ON games(release_date DESC);
COMMENT ON INDEX idx_games_release_date IS 
'Speeds up queries for recently released or upcoming games';

-- Index: Games by rating (for age-appropriate browsing)
CREATE INDEX idx_games_esrb_rating ON games(esrb_rating);
COMMENT ON INDEX idx_games_esrb_rating IS 
'Helps filter games by age rating (E, T, M, etc.)';

-- Index: Games SKU lookup (unique business key)
-- Already created via UNIQUE constraint, but explicitly noting it
COMMENT ON INDEX games_sku_key IS 
'Unique index for fast SKU lookups in product searches';

-- Index: Active games only (excludes discontinued)
CREATE INDEX idx_games_active ON games(is_active) WHERE is_active = true;
COMMENT ON INDEX idx_games_active IS 
'Partial index for active games to speed up catalog queries';

-- Index: Games by publisher (for publisher-specific queries)
CREATE INDEX idx_games_publisher ON games(publisher_id);
COMMENT ON INDEX idx_games_publisher IS 
'Optimizes queries filtering by publisher or developer';

-- ============================================
-- Game Genres Junction Table Indexes
-- ============================================

-- Index: Lookup games by genre
CREATE INDEX idx_game_genres_genre ON game_genres(genre_id, game_id);
COMMENT ON INDEX idx_game_genres_genre IS 
'Enables fast retrieval of all games in a specific genre';

-- Note: Primary key already creates index on (game_id, genre_id)

-- ============================================
-- Products Table Indexes
-- ============================================

-- Index: Products by category
CREATE INDEX idx_products_category ON products(category_id, base_price);
COMMENT ON INDEX idx_products_category IS 
'Optimizes browsing products by category (consoles, accessories, etc.)';

-- Index: Products by platform (for platform-specific accessories)
CREATE INDEX idx_products_platform ON products(platform_id) WHERE platform_id IS NOT NULL;
COMMENT ON INDEX idx_products_platform IS 
'Partial index for platform-specific products, excludes universal items';

-- Index: Active products
CREATE INDEX idx_products_active ON products(is_active) WHERE is_active = true;
COMMENT ON INDEX idx_products_active IS 
'Partial index for active products only';

-- ============================================
-- Inventory Table Indexes
-- ============================================

-- Index: Inventory by store (for store-specific stock checks)
CREATE INDEX idx_inventory_store ON inventory(store_id, quantity);
COMMENT ON INDEX idx_inventory_store IS 
'Speeds up inventory lookups by store location';

-- Index: Low stock items (for reorder alerts)
CREATE INDEX idx_inventory_low_stock ON inventory(store_id, reorder_level, quantity) 
WHERE quantity <= reorder_level;
COMMENT ON INDEX idx_inventory_low_stock IS 
'Partial index identifying items below reorder threshold for automated alerts';

-- Index: Inventory by game
CREATE INDEX idx_inventory_game ON inventory(game_id) WHERE game_id IS NOT NULL;
COMMENT ON INDEX idx_inventory_game IS 
'Fast lookups of which stores carry a specific game';

-- Index: Inventory by product
CREATE INDEX idx_inventory_product ON inventory(product_id) WHERE product_id IS NOT NULL;
COMMENT ON INDEX idx_inventory_product IS 
'Fast lookups of which stores carry a specific product';

-- ============================================
-- Orders Table Indexes
-- ============================================

-- Index: Orders by customer (for order history)
CREATE INDEX idx_orders_customer ON orders(customer_id, order_date DESC);
COMMENT ON INDEX idx_orders_customer IS 
'Optimizes customer order history queries, most recent first';

-- Index: Orders by store and date (for store sales reports)
CREATE INDEX idx_orders_store_date ON orders(store_id, order_date DESC) WHERE store_id IS NOT NULL;
COMMENT ON INDEX idx_orders_store_date IS 
'Partial index for in-store orders, used in store performance reports';

-- Index: Orders by status (for order management)
CREATE INDEX idx_orders_status ON orders(status, order_date DESC);
COMMENT ON INDEX idx_orders_status IS 
'Helps filter orders by status (pending, shipped, delivered, etc.)';

-- Index: Orders by date (for sales reports by time period)
CREATE INDEX idx_orders_date ON orders(order_date DESC);
COMMENT ON INDEX idx_orders_date IS 
'Range queries for daily, weekly, monthly sales reports';

-- Index: Online vs in-store orders
CREATE INDEX idx_orders_channel ON orders(is_online, order_date DESC);
COMMENT ON INDEX idx_orders_channel IS 
'Separates online and in-store orders for channel analysis';

-- Index: Orders by employee (for employee performance tracking)
CREATE INDEX idx_orders_employee ON orders(employee_id, order_date DESC) WHERE employee_id IS NOT NULL;
COMMENT ON INDEX idx_orders_employee IS 
'Tracks orders processed by each employee';

-- ============================================
-- Order Items Table Indexes
-- ============================================

-- Index: Order items by order (for order details lookup)
-- Already has FK index, but ensuring coverage
CREATE INDEX idx_order_items_order ON order_items(order_id);
COMMENT ON INDEX idx_order_items_order IS 
'Fast retrieval of all items in a specific order';

-- Index: Order items by game (for game sales analytics)
CREATE INDEX idx_order_items_game ON order_items(game_id, order_id) WHERE game_id IS NOT NULL;
COMMENT ON INDEX idx_order_items_game IS 
'Analyzes sales performance of specific games';

-- Index: Order items by product (for product sales analytics)
CREATE INDEX idx_order_items_product ON order_items(product_id, order_id) WHERE product_id IS NOT NULL;
COMMENT ON INDEX idx_order_items_product IS 
'Analyzes sales performance of specific products';

-- ============================================
-- Customers Table Indexes
-- ============================================

-- Index: Customer email lookup (for login/authentication)
-- Already created via UNIQUE constraint on email

-- Index: Customers by loyalty points (for VIP identification)
CREATE INDEX idx_customers_loyalty ON customers(loyalty_points DESC) WHERE loyalty_points > 0;
COMMENT ON INDEX idx_customers_loyalty IS 
'Identifies top loyalty members for rewards and marketing';

-- Index: Customers by join date (for cohort analysis)
CREATE INDEX idx_customers_join_date ON customers(join_date);
COMMENT ON INDEX idx_customers_join_date IS 
'Supports customer acquisition and retention analysis';

-- Index: Active customers with age verification
CREATE INDEX idx_customers_active_verified ON customers(is_active, age_verified) WHERE is_active = true;
COMMENT ON INDEX idx_customers_active_verified IS 
'Filters active, age-verified customers for mature content purchases';

-- Index: Customers by location (for regional marketing)
CREATE INDEX idx_customers_location ON customers(state, city) WHERE is_active = true;
COMMENT ON INDEX idx_customers_location IS 
'Geographic customer distribution for regional promotions';

-- ============================================
-- Reviews Table Indexes
-- ============================================

-- Index: Reviews by game (for product page display)
CREATE INDEX idx_reviews_game ON reviews(game_id, review_date DESC);
COMMENT ON INDEX idx_reviews_game IS 
'Retrieves all reviews for a game, most recent first';

-- Index: Reviews by customer (for customer review history)
CREATE INDEX idx_reviews_customer ON reviews(customer_id, review_date DESC);
COMMENT ON INDEX idx_reviews_customer IS 
'Shows all reviews written by a customer';

-- Index: Reviews by rating (for filtering high/low ratings)
CREATE INDEX idx_reviews_rating ON reviews(game_id, rating DESC);
COMMENT ON INDEX idx_reviews_rating IS 
'Filters reviews by star rating for sorting options';

-- Index: Verified purchase reviews only
CREATE INDEX idx_reviews_verified ON reviews(game_id, is_verified_purchase) 
WHERE is_verified_purchase = true;
COMMENT ON INDEX idx_reviews_verified IS 
'Partial index for verified purchase reviews only';

-- ============================================
-- Pre-Orders Table Indexes
-- ============================================

-- Index: Pre-orders by customer
CREATE INDEX idx_preorders_customer ON pre_orders(customer_id, pre_order_date DESC);
COMMENT ON INDEX idx_preorders_customer IS 
'Customer pre-order history and management';

-- Index: Pre-orders by game
CREATE INDEX idx_preorders_game ON pre_orders(game_id, expected_release_date);
COMMENT ON INDEX idx_preorders_game IS 
'Tracks pre-order demand for upcoming releases';

-- Index: Unfulfilled pre-orders
CREATE INDEX idx_preorders_unfulfilled ON pre_orders(is_fulfilled, expected_release_date) 
WHERE is_fulfilled = false;
COMMENT ON INDEX idx_preorders_unfulfilled IS 
'Partial index for pending pre-orders by release date';

-- Index: Pre-orders by store
CREATE INDEX idx_preorders_store ON pre_orders(store_id, expected_release_date) 
WHERE store_id IS NOT NULL;
COMMENT ON INDEX idx_preorders_store IS 
'Store-specific pre-order allocation and fulfillment';

-- ============================================
-- Loyalty Transactions Table Indexes
-- ============================================

-- Index: Loyalty transactions by customer
CREATE INDEX idx_loyalty_trans_customer ON loyalty_transactions(customer_id, transaction_date DESC);
COMMENT ON INDEX idx_loyalty_trans_customer IS 
'Customer loyalty points history';

-- Index: Loyalty transactions by order
CREATE INDEX idx_loyalty_trans_order ON loyalty_transactions(order_id) WHERE order_id IS NOT NULL;
COMMENT ON INDEX idx_loyalty_trans_order IS 
'Links loyalty points to specific orders';

-- ============================================
-- Returns Table Indexes
-- ============================================

-- Index: Returns by customer
CREATE INDEX idx_returns_customer ON returns(customer_id, return_date DESC);
COMMENT ON INDEX idx_returns_customer IS 
'Customer return history for pattern analysis';

-- Index: Returns by order
CREATE INDEX idx_returns_order ON returns(order_id);
COMMENT ON INDEX idx_returns_order IS 
'Links returns to original orders';

-- Index: Pending returns
CREATE INDEX idx_returns_pending ON returns(status, return_date) WHERE status = 'pending';
COMMENT ON INDEX idx_returns_pending IS 
'Partial index for returns awaiting approval';

-- ============================================
-- Employees Table Indexes
-- ============================================

-- Index: Employees by store
CREATE INDEX idx_employees_store ON employees(store_id, role) WHERE is_active = true;
COMMENT ON INDEX idx_employees_store IS 
'Lists active employees per store by role';

-- Index: Employees by role
CREATE INDEX idx_employees_role ON employees(role) WHERE is_active = true;
COMMENT ON INDEX idx_employees_role IS 
'Groups employees by job function';

-- ============================================
-- Stores Table Indexes
-- ============================================

-- Index: Active stores by location
CREATE INDEX idx_stores_location ON stores(state, city) WHERE is_active = true;
COMMENT ON INDEX idx_stores_location IS 
'Geographic store distribution';

-- ============================================
-- Promotions Table Indexes
-- ============================================

-- Index: Active promotions by date range
CREATE INDEX idx_promotions_active ON promotions(start_date, end_date, is_active) 
WHERE is_active = true;
COMMENT ON INDEX idx_promotions_active IS 
'Finds currently valid promotions';

-- Index: Promotions by end date (for expiration alerts)
CREATE INDEX idx_promotions_ending ON promotions(end_date) 
WHERE is_active = true AND end_date >= CURRENT_DATE;
COMMENT ON INDEX idx_promotions_ending IS 
'Partial index for active promotions by expiration date';

-- ============================================
-- Purchase Orders Table Indexes
-- ============================================

-- Index: Purchase orders by vendor
CREATE INDEX idx_purchase_orders_vendor ON purchase_orders(vendor_id, order_date DESC);
COMMENT ON INDEX idx_purchase_orders_vendor IS 
'Vendor order history and relationship management';

-- Index: Purchase orders by store
CREATE INDEX idx_purchase_orders_store ON purchase_orders(store_id, status);
COMMENT ON INDEX idx_purchase_orders_store IS 
'Store restocking orders and pending deliveries';

-- Index: Purchase orders by status
CREATE INDEX idx_purchase_orders_status ON purchase_orders(status, expected_delivery_date);
COMMENT ON INDEX idx_purchase_orders_status IS 
'Tracks pending, delivered, and cancelled purchase orders';

-- ============================================
-- Full-Text Search Indexes (Optional but Recommended)
-- ============================================

-- Full-text search on game titles
CREATE INDEX idx_games_title_fts ON games USING gin(to_tsvector('english', title));
COMMENT ON INDEX idx_games_title_fts IS 
'Full-text search index for game title searches';

-- Full-text search on product names
CREATE INDEX idx_products_name_fts ON products USING gin(to_tsvector('english', product_name));
COMMENT ON INDEX idx_products_name_fts IS 
'Full-text search index for product name searches';

-- ============================================
-- Composite Indexes for Complex Queries
-- ============================================

-- Index: Games by platform, genre, and rating (for catalog filtering)
CREATE INDEX idx_games_catalog_filter ON games(platform_id, esrb_rating, base_price) 
WHERE is_active = true;
COMMENT ON INDEX idx_games_catalog_filter IS 
'Supports complex catalog queries with multiple filters';

-- Index: Order value analysis
CREATE INDEX idx_orders_value_analysis ON orders(order_date, total_amount, status) 
WHERE status NOT IN ('cancelled', 'refunded');
COMMENT ON INDEX idx_orders_value_analysis IS 
'Optimizes revenue reporting and sales analytics';

-- Indexes creation complete
SELECT 'All indexes created successfully!' AS status;

-- ============================================
-- Index Usage Monitoring
-- ============================================

-- Query to check index usage (run periodically for optimization)
COMMENT ON DATABASE game_store IS 
'Run this query to monitor index effectiveness:
SELECT 
    schemaname, tablename, indexname, 
    idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes 
ORDER BY idx_scan ASC;

Low idx_scan values may indicate unused indexes that can be dropped.';
