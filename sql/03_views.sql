-- ============================================
-- Game Store Database - Views
-- File: 03_views.sql
-- Description: Creates views for common queries and reporting
-- ============================================

-- ============================================
-- Product Catalog Views
-- ============================================

-- View: Complete game catalog with all details
CREATE OR REPLACE VIEW v_game_catalog AS
SELECT 
    g.game_id,
    g.sku,
    g.title,
    p.platform_name,
    pub.publisher_name,
    g.release_date,
    g.esrb_rating,
    g.base_price,
    g.is_digital_only,
    STRING_AGG(gen.genre_name, ', ' ORDER BY gen.genre_name) AS genres,
    COALESCE(AVG(r.rating), 0) AS avg_rating,
    COUNT(DISTINCT r.review_id) AS review_count
FROM games g
JOIN platforms p ON g.platform_id = p.platform_id
JOIN publishers pub ON g.publisher_id = pub.publisher_id
LEFT JOIN game_genres gg ON g.game_id = gg.game_id
LEFT JOIN genres gen ON gg.genre_id = gen.genre_id
LEFT JOIN reviews r ON g.game_id = r.game_id
WHERE g.is_active = true
GROUP BY g.game_id, g.sku, g.title, p.platform_name, pub.publisher_name, 
         g.release_date, g.esrb_rating, g.base_price, g.is_digital_only;

COMMENT ON VIEW v_game_catalog IS 'Complete game catalog with genres, ratings, and reviews';

-- View: Product catalog (consoles and accessories)
CREATE OR REPLACE VIEW v_product_catalog AS
SELECT 
    pr.product_id,
    pr.sku,
    pr.product_name,
    pc.category_name,
    COALESCE(p.platform_name, 'Universal') AS platform,
    pr.description,
    pr.base_price,
    pr.is_active
FROM products pr
JOIN product_categories pc ON pr.category_id = pc.category_id
LEFT JOIN platforms p ON pr.platform_id = p.platform_id
WHERE pr.is_active = true;

COMMENT ON VIEW v_product_catalog IS 'Product catalog for consoles and accessories';

-- ============================================
-- Inventory Views
-- ============================================

-- View: Current inventory levels across all stores
CREATE OR REPLACE VIEW v_inventory_status AS
SELECT 
    s.store_name,
    s.city,
    s.state,
    COALESCE(g.title, pr.product_name) AS item_name,
    COALESCE(g.sku, pr.sku) AS sku,
    CASE 
        WHEN i.game_id IS NOT NULL THEN 'Game'
        ELSE pc.category_name
    END AS item_type,
    i.quantity,
    i.reorder_level,
    CASE 
        WHEN i.quantity <= i.reorder_level THEN 'Low Stock'
        WHEN i.quantity = 0 THEN 'Out of Stock'
        ELSE 'In Stock'
    END AS stock_status,
    i.last_restocked
FROM inventory i
JOIN stores s ON i.store_id = s.store_id
LEFT JOIN games g ON i.game_id = g.game_id
LEFT JOIN products pr ON i.product_id = pr.product_id
LEFT JOIN product_categories pc ON pr.category_id = pc.category_id
ORDER BY s.store_name, item_name;

COMMENT ON VIEW v_inventory_status IS 'Current inventory status with stock alerts';

-- View: Low stock items that need reordering
CREATE OR REPLACE VIEW v_low_stock_items AS
SELECT 
    s.store_name,
    COALESCE(g.title, pr.product_name) AS item_name,
    COALESCE(g.sku, pr.sku) AS sku,
    i.quantity,
    i.reorder_level,
    i.last_restocked,
    COALESCE(g.base_price, pr.base_price) AS price
FROM inventory i
JOIN stores s ON i.store_id = s.store_id
LEFT JOIN games g ON i.game_id = g.game_id
LEFT JOIN products pr ON i.product_id = pr.product_id
WHERE i.quantity <= i.reorder_level
ORDER BY i.quantity ASC, s.store_name;

COMMENT ON VIEW v_low_stock_items IS 'Items below reorder level requiring restocking';

-- ============================================
-- Sales and Order Views
-- ============================================

-- View: Order summary with customer and item details
CREATE OR REPLACE VIEW v_order_summary AS
SELECT 
    o.order_id,
    o.order_date,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email AS customer_email,
    COALESCE(s.store_name, 'Online') AS store,
    COALESCE(e.first_name || ' ' || e.last_name, 'Online') AS employee_name,
    o.status,
    o.subtotal,
    o.tax_amount,
    o.discount_amount,
    o.total_amount,
    o.payment_method,
    o.is_online,
    COUNT(oi.order_item_id) AS item_count
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN stores s ON o.store_id = s.store_id
LEFT JOIN employees e ON o.employee_id = e.employee_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.order_date, c.customer_id, c.first_name, c.last_name, 
         c.email, s.store_name, e.first_name, e.last_name, o.status, 
         o.subtotal, o.tax_amount, o.discount_amount, o.total_amount, 
         o.payment_method, o.is_online;

COMMENT ON VIEW v_order_summary IS 'Comprehensive order information with customer details';

-- View: Sales by product
CREATE OR REPLACE VIEW v_sales_by_product AS
SELECT 
    COALESCE(g.title, pr.product_name) AS product_name,
    COALESCE(g.sku, pr.sku) AS sku,
    CASE 
        WHEN oi.game_id IS NOT NULL THEN 'Game'
        ELSE 'Product'
    END AS product_type,
    COUNT(DISTINCT oi.order_id) AS order_count,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.line_total) AS total_revenue,
    AVG(oi.unit_price) AS avg_price
FROM order_items oi
LEFT JOIN games g ON oi.game_id = g.game_id
LEFT JOIN products pr ON oi.product_id = pr.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status NOT IN ('cancelled', 'refunded')
GROUP BY product_name, sku, product_type
ORDER BY total_revenue DESC;

COMMENT ON VIEW v_sales_by_product IS 'Sales performance metrics by product';

-- View: Sales by store
CREATE OR REPLACE VIEW v_sales_by_store AS
SELECT 
    s.store_id,
    s.store_name,
    s.city,
    s.state,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(o.total_amount) AS total_revenue,
    AVG(o.total_amount) AS avg_order_value,
    COUNT(DISTINCT o.customer_id) AS unique_customers
FROM stores s
LEFT JOIN orders o ON s.store_id = o.store_id
WHERE o.status NOT IN ('cancelled', 'refunded') OR o.order_id IS NULL
GROUP BY s.store_id, s.store_name, s.city, s.state
ORDER BY total_revenue DESC NULLS LAST;

COMMENT ON VIEW v_sales_by_store IS 'Store performance metrics';

-- ============================================
-- Customer Views
-- ============================================

-- View: Customer purchase history summary
CREATE OR REPLACE VIEW v_customer_summary AS
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    c.join_date,
    c.loyalty_points,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0) AS lifetime_value,
    COALESCE(AVG(o.total_amount), 0) AS avg_order_value,
    MAX(o.order_date) AS last_order_date,
    COUNT(DISTINCT r.review_id) AS review_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id 
    AND o.status NOT IN ('cancelled', 'refunded')
LEFT JOIN reviews r ON c.customer_id = r.customer_id
WHERE c.is_active = true
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, 
         c.join_date, c.loyalty_points;

COMMENT ON VIEW v_customer_summary IS 'Customer lifetime value and engagement metrics';

-- View: Top customers by spending
CREATE OR REPLACE VIEW v_top_customers AS
SELECT 
    customer_id,
    customer_name,
    email,
    total_orders,
    lifetime_value,
    loyalty_points
FROM v_customer_summary
WHERE total_orders > 0
ORDER BY lifetime_value DESC
LIMIT 100;

COMMENT ON VIEW v_top_customers IS 'Top 100 customers by lifetime value';

-- ============================================
-- Employee and Store Management Views
-- ============================================

-- View: Employee performance
CREATE OR REPLACE VIEW v_employee_performance AS
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    e.role,
    s.store_name,
    COUNT(DISTINCT o.order_id) AS orders_processed,
    COALESCE(SUM(o.total_amount), 0) AS total_sales,
    COALESCE(AVG(o.total_amount), 0) AS avg_sale_value
FROM employees e
JOIN stores s ON e.store_id = s.store_id
LEFT JOIN orders o ON e.employee_id = o.employee_id 
    AND o.status NOT IN ('cancelled', 'refunded')
WHERE e.is_active = true
GROUP BY e.employee_id, e.first_name, e.last_name, e.role, s.store_name
ORDER BY total_sales DESC;

COMMENT ON VIEW v_employee_performance IS 'Employee sales performance metrics';

-- ============================================
-- Review and Rating Views
-- ============================================

-- View: Game reviews with customer details
CREATE OR REPLACE VIEW v_game_reviews AS
SELECT 
    r.review_id,
    g.title AS game_title,
    g.sku,
    p.platform_name,
    c.first_name || ' ' || c.last_name AS reviewer_name,
    r.rating,
    r.review_text,
    r.review_date,
    r.is_verified_purchase,
    r.helpful_count
FROM reviews r
JOIN games g ON r.game_id = g.game_id
JOIN platforms p ON g.platform_id = p.platform_id
JOIN customers c ON r.customer_id = c.customer_id
ORDER BY r.review_date DESC;

COMMENT ON VIEW v_game_reviews IS 'Game reviews with customer and game details';

-- ============================================
-- Promotion Views
-- ============================================

-- View: Active promotions
CREATE OR REPLACE VIEW v_active_promotions AS
SELECT 
    promotion_id,
    promotion_name,
    description,
    discount_percentage,
    discount_amount,
    start_date,
    end_date,
    min_purchase_amount,
    CURRENT_DATE - start_date AS days_active,
    end_date - CURRENT_DATE AS days_remaining
FROM promotions
WHERE is_active = true
    AND CURRENT_DATE BETWEEN start_date AND end_date
ORDER BY end_date;

COMMENT ON VIEW v_active_promotions IS 'Currently active promotions';

-- ============================================
-- Pre-Order Views
-- ============================================

-- View: Pending pre-orders
CREATE OR REPLACE VIEW v_pending_preorders AS
SELECT 
    po.pre_order_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    g.title AS game_title,
    g.sku,
    p.platform_name,
    po.quantity,
    po.deposit_amount,
    po.total_price,
    po.pre_order_date,
    po.expected_release_date,
    COALESCE(s.store_name, 'Online') AS pickup_location
FROM pre_orders po
JOIN customers c ON po.customer_id = c.customer_id
JOIN games g ON po.game_id = g.game_id
JOIN platforms p ON g.platform_id = p.platform_id
LEFT JOIN stores s ON po.store_id = s.store_id
WHERE po.is_fulfilled = false
ORDER BY po.expected_release_date;

COMMENT ON VIEW v_pending_preorders IS 'Unfulfilled pre-orders awaiting release';

-- Views creation complete
SELECT 'All views created successfully!' AS status;
