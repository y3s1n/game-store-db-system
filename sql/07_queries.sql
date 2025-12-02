-- ============================================
-- Game Store Database - Workload Queries
-- File: 07_queries.sql
-- Description: Representative queries demonstrating database capabilities
-- ============================================

-- ============================================
-- 1. CATALOG BROWSING QUERIES
-- ============================================

-- Query 1.1: Browse games by platform with ratings
-- Use case: Customer browsing PlayStation 5 games
SELECT 
    g.title,
    g.base_price,
    g.esrb_rating,
    g.release_date,
    STRING_AGG(gen.genre_name, ', ') AS genres,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    COUNT(r.review_id) AS review_count
FROM games g
JOIN platforms p ON g.platform_id = p.platform_id
LEFT JOIN game_genres gg ON g.game_id = gg.game_id
LEFT JOIN genres gen ON gg.genre_id = gen.genre_id
LEFT JOIN reviews r ON g.game_id = r.game_id
WHERE p.platform_name = 'PlayStation 5'
    AND g.is_active = true
GROUP BY g.game_id, g.title, g.base_price, g.esrb_rating, g.release_date
ORDER BY avg_rating DESC NULLS LAST, review_count DESC;

-- Query 1.2: Search games by genre and rating
-- Use case: Parent looking for age-appropriate RPG games
SELECT 
    g.title,
    p.platform_name,
    pub.publisher_name,
    g.base_price,
    g.esrb_rating,
    g.release_date
FROM games g
JOIN platforms p ON g.platform_id = p.platform_id
JOIN publishers pub ON g.publisher_id = pub.publisher_id
JOIN game_genres gg ON g.game_id = gg.game_id
JOIN genres gen ON gg.genre_id = gen.genre_id
WHERE gen.genre_name = 'RPG'
    AND g.esrb_rating IN ('E', 'E10+', 'T')
    AND g.is_active = true
ORDER BY g.release_date DESC;

-- Query 1.3: Find new releases (last 6 months)
-- Use case: Customer wants to see what's new
SELECT 
    g.title,
    p.platform_name,
    g.release_date,
    g.base_price,
    g.esrb_rating,
    STRING_AGG(gen.genre_name, ', ') AS genres
FROM games g
JOIN platforms p ON g.platform_id = p.platform_id
LEFT JOIN game_genres gg ON g.game_id = gg.game_id
LEFT JOIN genres gen ON gg.genre_id = gen.genre_id
WHERE g.release_date >= CURRENT_DATE - INTERVAL '6 months'
    AND g.is_active = true
GROUP BY g.game_id, g.title, p.platform_name, g.release_date, g.base_price, g.esrb_rating
ORDER BY g.release_date DESC;

-- Query 1.4: Full-text search for games
-- Use case: Customer searches for "Spider" or "Mario"
SELECT 
    g.title,
    p.platform_name,
    g.base_price,
    g.esrb_rating,
    ts_rank(to_tsvector('english', g.title), query) AS relevance
FROM games g
JOIN platforms p ON g.platform_id = p.platform_id,
    to_tsquery('english', 'Spider | Mario') query
WHERE to_tsvector('english', g.title) @@ query
    AND g.is_active = true
ORDER BY relevance DESC, g.title;

-- ============================================
-- 2. INVENTORY AND STOCK QUERIES
-- ============================================

-- Query 2.1: Check stock availability across all stores
-- Use case: Customer wants to know which stores have a specific game
SELECT 
    s.store_name,
    s.city,
    s.state,
    i.quantity,
    CASE 
        WHEN i.quantity = 0 THEN 'Out of Stock'
        WHEN i.quantity <= i.reorder_level THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM games g
CROSS JOIN stores s
LEFT JOIN inventory i ON s.store_id = i.store_id AND g.game_id = i.game_id
WHERE g.sku = 'PS5-001'  -- Spider-Man 2
    AND s.is_active = true
ORDER BY i.quantity DESC NULLS LAST;

-- Query 2.2: Low stock alert report
-- Use case: Store manager wants to see items needing reorder
SELECT 
    s.store_name,
    COALESCE(g.title, pr.product_name) AS item_name,
    COALESCE(g.sku, pr.sku) AS sku,
    i.quantity AS current_stock,
    i.reorder_level,
    i.last_restocked,
    CURRENT_DATE - i.last_restocked AS days_since_restock,
    COALESCE(g.base_price, pr.base_price) AS price
FROM inventory i
JOIN stores s ON i.store_id = s.store_id
LEFT JOIN games g ON i.game_id = g.game_id
LEFT JOIN products pr ON i.product_id = pr.product_id
WHERE i.quantity <= i.reorder_level
ORDER BY i.quantity ASC, s.store_name;

-- Query 2.3: Inventory valuation by store
-- Use case: Management wants to know total inventory value per location
SELECT 
    s.store_name,
    s.city,
    COUNT(DISTINCT i.inventory_id) AS unique_items,
    SUM(i.quantity) AS total_units,
    SUM(i.quantity * COALESCE(g.base_price, pr.base_price)) AS inventory_value
FROM stores s
LEFT JOIN inventory i ON s.store_id = i.store_id
LEFT JOIN games g ON i.game_id = g.game_id
LEFT JOIN products pr ON i.product_id = pr.product_id
WHERE s.is_active = true
GROUP BY s.store_id, s.store_name, s.city
ORDER BY inventory_value DESC;

-- ============================================
-- 3. SALES AND REVENUE QUERIES
-- ============================================

-- Query 3.1: Best-selling games (by units sold)
-- Use case: Marketing wants to promote top sellers
SELECT 
    g.title,
    p.platform_name,
    COUNT(DISTINCT oi.order_id) AS order_count,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.line_total) AS total_revenue,
    ROUND(AVG(oi.unit_price), 2) AS avg_selling_price
FROM order_items oi
JOIN games g ON oi.game_id = g.game_id
JOIN platforms p ON g.platform_id = p.platform_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status NOT IN ('cancelled', 'refunded')
    AND o.order_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY g.game_id, g.title, p.platform_name
ORDER BY units_sold DESC
LIMIT 10;

-- Query 3.2: Sales by store performance
-- Use case: Executive dashboard showing store comparison
SELECT 
    s.store_name,
    s.city,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(o.total_amount) AS total_revenue,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    SUM(CASE WHEN o.is_online = false THEN o.total_amount ELSE 0 END) AS in_store_revenue,
    SUM(CASE WHEN o.is_online = true THEN o.total_amount ELSE 0 END) AS online_revenue
FROM stores s
LEFT JOIN orders o ON s.store_id = o.store_id
WHERE s.is_active = true
    AND (o.status NOT IN ('cancelled', 'refunded') OR o.order_id IS NULL)
    AND (o.order_date >= CURRENT_DATE - INTERVAL '30 days' OR o.order_id IS NULL)
GROUP BY s.store_id, s.store_name, s.city
ORDER BY total_revenue DESC;

-- Query 3.3: Revenue by product category
-- Use case: Understanding which product types drive the most revenue
SELECT 
    CASE 
        WHEN oi.game_id IS NOT NULL THEN 'Games'
        WHEN pc.category_type = 'console' THEN 'Consoles'
        WHEN pc.category_type = 'accessory' THEN 'Accessories'
    END AS product_category,
    COUNT(DISTINCT oi.order_id) AS order_count,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.line_total) AS total_revenue,
    ROUND(AVG(oi.unit_price), 2) AS avg_price
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN products pr ON oi.product_id = pr.product_id
LEFT JOIN product_categories pc ON pr.category_id = pc.category_id
WHERE o.status NOT IN ('cancelled', 'refunded')
    AND o.order_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY product_category
ORDER BY total_revenue DESC;

-- Query 3.4: Monthly sales trend analysis
-- Use case: Finance needs monthly revenue reports
SELECT 
    DATE_TRUNC('month', o.order_date) AS month,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(o.total_amount) AS total_revenue,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value,
    COUNT(DISTINCT o.customer_id) AS unique_customers
FROM orders o
WHERE o.status NOT IN ('cancelled', 'refunded')
    AND o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY month DESC;

-- ============================================
-- 4. CUSTOMER ANALYTICS QUERIES
-- ============================================

-- Query 4.1: Top customers by lifetime value
-- Use case: Identifying VIP customers for special promotions
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    c.loyalty_points,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.total_amount) AS lifetime_value,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value,
    MAX(o.order_date) AS last_order_date,
    EXTRACT(DAY FROM (CURRENT_DATE - MAX(o.order_date::DATE))) AS days_since_last_order
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status NOT IN ('cancelled', 'refunded')
    AND c.is_active = true
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.loyalty_points
ORDER BY lifetime_value DESC
LIMIT 20;

-- Query 4.2: Customer segmentation by purchase frequency
-- Use case: Marketing wants to target different customer segments
WITH customer_segments AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name AS customer_name,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(o.total_amount) AS total_spent,
        MAX(o.order_date) AS last_order_date,
        CASE 
            WHEN COUNT(o.order_id) >= 10 THEN 'Frequent Buyer'
            WHEN COUNT(o.order_id) >= 5 THEN 'Regular Customer'
            WHEN COUNT(o.order_id) >= 2 THEN 'Occasional Buyer'
            ELSE 'One-Time Customer'
        END AS segment
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id 
        AND o.status NOT IN ('cancelled', 'refunded')
    WHERE c.is_active = true
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT 
    segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(order_count), 1) AS avg_orders,
    ROUND(AVG(total_spent), 2) AS avg_lifetime_value
FROM customer_segments
GROUP BY segment
ORDER BY avg_orders DESC;

-- Query 4.3: Customer purchase history with recommendations
-- Use case: Show customer their history and suggest similar games
SELECT 
    o.order_id,
    o.order_date,
    g.title AS game_purchased,
    p.platform_name,
    STRING_AGG(DISTINCT gen.genre_name, ', ') AS genres,
    oi.unit_price
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN games g ON oi.game_id = g.game_id
JOIN platforms p ON g.platform_id = p.platform_id
LEFT JOIN game_genres gg ON g.game_id = gg.game_id
LEFT JOIN genres gen ON gg.genre_id = gen.genre_id
WHERE o.customer_id = 1  -- Specific customer
    AND o.status = 'delivered'
GROUP BY o.order_id, o.order_date, g.title, p.platform_name, oi.unit_price
ORDER BY o.order_date DESC;

-- ============================================
-- 5. EMPLOYEE PERFORMANCE QUERIES
-- ============================================

-- Query 5.1: Employee sales performance
-- Use case: Store manager reviewing employee contributions
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    e.role,
    s.store_name,
    COUNT(DISTINCT o.order_id) AS orders_processed,
    SUM(o.total_amount) AS total_sales,
    ROUND(AVG(o.total_amount), 2) AS avg_sale_value,
    COUNT(DISTINCT o.customer_id) AS unique_customers
FROM employees e
JOIN stores s ON e.store_id = s.store_id
LEFT JOIN orders o ON e.employee_id = o.employee_id 
    AND o.status NOT IN ('cancelled', 'refunded')
    AND o.order_date >= CURRENT_DATE - INTERVAL '30 days'
WHERE e.is_active = true
    AND e.role IN ('cashier', 'sales_associate')
GROUP BY e.employee_id, e.first_name, e.last_name, e.role, s.store_name
ORDER BY total_sales DESC;

-- ============================================
-- 6. REVIEW AND RATING QUERIES
-- ============================================

-- Query 6.1: Games with highest ratings
-- Use case: Featured section showing top-rated games
SELECT 
    g.title,
    p.platform_name,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    COUNT(r.review_id) AS review_count,
    SUM(CASE WHEN r.is_verified_purchase THEN 1 ELSE 0 END) AS verified_reviews
FROM games g
JOIN platforms p ON g.platform_id = p.platform_id
JOIN reviews r ON g.game_id = r.game_id
WHERE g.is_active = true
GROUP BY g.game_id, g.title, p.platform_name
HAVING COUNT(r.review_id) >= 3  -- At least 3 reviews
ORDER BY avg_rating DESC, review_count DESC
LIMIT 10;

-- Query 6.2: Recent reviews with customer details
-- Use case: Displaying latest reviews on product pages
SELECT 
    r.review_id,
    g.title AS game_title,
    c.first_name || ' ' || LEFT(c.last_name, 1) || '.' AS reviewer,
    r.rating,
    r.review_text,
    r.review_date,
    r.is_verified_purchase,
    r.helpful_count
FROM reviews r
JOIN games g ON r.game_id = g.game_id
JOIN customers c ON r.customer_id = c.customer_id
WHERE g.sku = 'PS5-001'  -- Specific game
ORDER BY r.review_date DESC
LIMIT 10;

-- ============================================
-- 7. PRE-ORDER QUERIES
-- ============================================

-- Query 7.1: Upcoming releases with pre-order counts
-- Use case: Marketing planning for upcoming launches
SELECT 
    g.title,
    p.platform_name,
    g.release_date,
    COUNT(po.pre_order_id) AS preorder_count,
    SUM(po.quantity) AS total_units_preordered,
    SUM(po.deposit_amount) AS total_deposits,
    SUM(po.total_price) AS expected_revenue
FROM games g
JOIN platforms p ON g.platform_id = p.platform_id
LEFT JOIN pre_orders po ON g.game_id = po.game_id AND po.is_fulfilled = false
WHERE g.release_date > CURRENT_DATE
    AND g.release_date <= CURRENT_DATE + INTERVAL '90 days'
GROUP BY g.game_id, g.title, p.platform_name, g.release_date
ORDER BY g.release_date;

-- ============================================
-- 8. PROMOTION EFFECTIVENESS QUERIES
-- ============================================

-- Query 8.1: Promotion impact analysis
-- Use case: Measuring ROI of promotional campaigns
SELECT 
    pr.promotion_name,
    pr.start_date,
    pr.end_date,
    COUNT(DISTINCT o.order_id) AS orders_with_promotion,
    SUM(o.discount_amount) AS total_discount_given,
    SUM(o.total_amount) AS revenue_with_discount,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM promotions pr
LEFT JOIN orders o ON pr.promotion_id = o.promotion_id 
    AND o.status NOT IN ('cancelled', 'refunded')
WHERE pr.is_active = true
    OR pr.end_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY pr.promotion_id, pr.promotion_name, pr.start_date, pr.end_date
ORDER BY revenue_with_discount DESC;

-- ============================================
-- 9. COMPLEX ANALYTICAL QUERIES
-- ============================================

-- Query 9.1: Customer churn analysis
-- Use case: Identify customers at risk of churning
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    MAX(o.order_date) AS last_order_date,
    EXTRACT(DAY FROM (CURRENT_DATE - MAX(o.order_date::DATE))) AS days_inactive,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS lifetime_value,
    CASE 
        WHEN MAX(o.order_date) < CURRENT_DATE - INTERVAL '180 days' THEN 'High Risk'
        WHEN MAX(o.order_date) < CURRENT_DATE - INTERVAL '90 days' THEN 'Medium Risk'
        WHEN MAX(o.order_date) < CURRENT_DATE - INTERVAL '60 days' THEN 'Low Risk'
        ELSE 'Active'
    END AS churn_risk
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id 
    AND o.status NOT IN ('cancelled', 'refunded')
WHERE c.is_active = true
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
HAVING MAX(o.order_date) IS NOT NULL
ORDER BY days_inactive DESC;

-- Query 9.2: Cross-sell opportunities (customers who bought X might like Y)
-- Use case: Product recommendation engine
WITH game_pairs AS (
    SELECT 
        oi1.game_id AS game_a,
        oi2.game_id AS game_b,
        COUNT(DISTINCT oi1.order_id) AS co_purchase_count
    FROM order_items oi1
    JOIN order_items oi2 ON oi1.order_id = oi2.order_id 
        AND oi1.game_id < oi2.game_id
    WHERE oi1.game_id IS NOT NULL 
        AND oi2.game_id IS NOT NULL
    GROUP BY oi1.game_id, oi2.game_id
    HAVING COUNT(DISTINCT oi1.order_id) >= 2
)
SELECT 
    g1.title AS frequently_bought,
    g2.title AS also_bought,
    gp.co_purchase_count AS times_purchased_together,
    p1.platform_name AS platform_a,
    p2.platform_name AS platform_b
FROM game_pairs gp
JOIN games g1 ON gp.game_a = g1.game_id
JOIN games g2 ON gp.game_b = g2.game_id
JOIN platforms p1 ON g1.platform_id = p1.platform_id
JOIN platforms p2 ON g2.platform_id = p2.platform_id
ORDER BY co_purchase_count DESC
LIMIT 20;

-- Queries complete
SELECT 'All workload queries defined successfully!' AS status;
