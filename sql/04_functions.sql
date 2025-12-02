-- ============================================
-- Game Store Database - Functions and Procedures
-- File: 04_functions.sql
-- Description: Stored functions and procedures for business logic
-- ============================================

-- ============================================
-- Inventory Management Functions
-- ============================================

-- Function: Check if item is in stock at a specific store
CREATE OR REPLACE FUNCTION check_stock_availability(
    p_store_id INTEGER,
    p_game_id INTEGER DEFAULT NULL,
    p_product_id INTEGER DEFAULT NULL,
    p_quantity INTEGER DEFAULT 1
)
RETURNS BOOLEAN AS $$
DECLARE
    v_current_stock INTEGER;
BEGIN
    SELECT quantity INTO v_current_stock
    FROM inventory
    WHERE store_id = p_store_id
        AND (game_id = p_game_id OR product_id = p_product_id);
    
    RETURN COALESCE(v_current_stock, 0) >= p_quantity;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_stock_availability IS 'Checks if sufficient stock exists for an item at a store';

-- Function: Get total inventory value by store
CREATE OR REPLACE FUNCTION get_inventory_value(p_store_id INTEGER)
RETURNS DECIMAL(12,2) AS $$
DECLARE
    v_total_value DECIMAL(12,2);
BEGIN
    SELECT 
        SUM(
            COALESCE(i.quantity * g.base_price, 0) +
            COALESCE(i.quantity * pr.base_price, 0)
        )
    INTO v_total_value
    FROM inventory i
    LEFT JOIN games g ON i.game_id = g.game_id
    LEFT JOIN products pr ON i.product_id = pr.product_id
    WHERE i.store_id = p_store_id;
    
    RETURN COALESCE(v_total_value, 0.00);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_inventory_value IS 'Calculates total inventory value for a store';

-- Function: Update inventory after sale
CREATE OR REPLACE FUNCTION decrement_inventory(
    p_store_id INTEGER,
    p_game_id INTEGER DEFAULT NULL,
    p_product_id INTEGER DEFAULT NULL,
    p_quantity INTEGER DEFAULT 1
)
RETURNS BOOLEAN AS $$
DECLARE
    v_rows_affected INTEGER;
BEGIN
    UPDATE inventory
    SET quantity = quantity - p_quantity,
        updated_at = CURRENT_TIMESTAMP
    WHERE store_id = p_store_id
        AND (game_id = p_game_id OR product_id = p_product_id)
        AND quantity >= p_quantity;
    
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    
    RETURN v_rows_affected > 0;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION decrement_inventory IS 'Decrements inventory quantity after a sale';

-- ============================================
-- Customer and Loyalty Functions
-- ============================================

-- Function: Calculate loyalty points for order amount
CREATE OR REPLACE FUNCTION calculate_loyalty_points(p_order_amount DECIMAL)
RETURNS INTEGER AS $$
BEGIN
    -- Earn 1 point for every $10 spent
    RETURN FLOOR(p_order_amount / 10)::INTEGER;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_loyalty_points IS 'Calculates loyalty points earned based on order amount';

-- Function: Apply loyalty points to order
CREATE OR REPLACE FUNCTION redeem_loyalty_points(
    p_customer_id INTEGER,
    p_points_to_redeem INTEGER
)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    v_current_points INTEGER;
    v_discount_amount DECIMAL(10,2);
BEGIN
    -- Get current points
    SELECT loyalty_points INTO v_current_points
    FROM customers
    WHERE customer_id = p_customer_id;
    
    -- Check if customer has enough points
    IF v_current_points < p_points_to_redeem THEN
        RAISE EXCEPTION 'Insufficient loyalty points. Available: %, Requested: %', 
            v_current_points, p_points_to_redeem;
    END IF;
    
    -- Calculate discount: 100 points = $1
    v_discount_amount := (p_points_to_redeem / 100.0);
    
    -- Update customer points
    UPDATE customers
    SET loyalty_points = loyalty_points - p_points_to_redeem,
        updated_at = CURRENT_TIMESTAMP
    WHERE customer_id = p_customer_id;
    
    RETURN v_discount_amount;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION redeem_loyalty_points IS 'Redeems loyalty points and returns discount amount';

-- Function: Get customer lifetime value
CREATE OR REPLACE FUNCTION get_customer_lifetime_value(p_customer_id INTEGER)
RETURNS DECIMAL(12,2) AS $$
DECLARE
    v_lifetime_value DECIMAL(12,2);
BEGIN
    SELECT COALESCE(SUM(total_amount), 0)
    INTO v_lifetime_value
    FROM orders
    WHERE customer_id = p_customer_id
        AND status NOT IN ('cancelled', 'refunded');
    
    RETURN v_lifetime_value;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_customer_lifetime_value IS 'Calculates total spending for a customer';

-- ============================================
-- Order Processing Functions
-- ============================================

-- Function: Calculate order totals
CREATE OR REPLACE FUNCTION calculate_order_totals(
    p_subtotal DECIMAL,
    p_tax_rate DECIMAL DEFAULT 0.09,
    p_discount_amount DECIMAL DEFAULT 0
)
RETURNS TABLE(
    subtotal DECIMAL(10,2),
    tax_amount DECIMAL(10,2),
    discount_amount DECIMAL(10,2),
    total_amount DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p_subtotal,
        ROUND((p_subtotal * p_tax_rate)::NUMERIC, 2) AS tax_amount,
        p_discount_amount,
        ROUND((p_subtotal + (p_subtotal * p_tax_rate) - p_discount_amount)::NUMERIC, 2) AS total_amount;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_order_totals IS 'Calculates order subtotal, tax, discount, and total';

-- Function: Validate order before processing
CREATE OR REPLACE FUNCTION validate_order(p_order_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    v_order_record RECORD;
    v_item_record RECORD;
    v_has_stock BOOLEAN;
BEGIN
    -- Get order details
    SELECT * INTO v_order_record
    FROM orders
    WHERE order_id = p_order_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order % not found', p_order_id;
    END IF;
    
    -- Check inventory for each item
    FOR v_item_record IN 
        SELECT * FROM order_items WHERE order_id = p_order_id
    LOOP
        -- Only check inventory for in-store orders
        IF v_order_record.store_id IS NOT NULL THEN
            SELECT check_stock_availability(
                v_order_record.store_id,
                v_item_record.game_id,
                v_item_record.product_id,
                v_item_record.quantity
            ) INTO v_has_stock;
            
            IF NOT v_has_stock THEN
                RAISE EXCEPTION 'Insufficient stock for item in order %', p_order_id;
            END IF;
        END IF;
    END LOOP;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION validate_order IS 'Validates order can be fulfilled based on inventory';

-- ============================================
-- Age Verification Functions
-- ============================================

-- Function: Check if customer meets age requirement for game
CREATE OR REPLACE FUNCTION check_age_requirement(
    p_customer_id INTEGER,
    p_game_id INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    v_customer_age INTEGER;
    v_game_rating esrb_rating;
    v_required_age INTEGER;
BEGIN
    -- Get customer age
    SELECT EXTRACT(YEAR FROM AGE(date_of_birth)) INTO v_customer_age
    FROM customers
    WHERE customer_id = p_customer_id;
    
    -- Get game rating
    SELECT esrb_rating INTO v_game_rating
    FROM games
    WHERE game_id = p_game_id;
    
    -- Determine required age
    v_required_age := CASE v_game_rating
        WHEN 'E' THEN 0
        WHEN 'E10+' THEN 10
        WHEN 'T' THEN 13
        WHEN 'M' THEN 17
        WHEN 'AO' THEN 18
        ELSE 0
    END;
    
    RETURN v_customer_age >= v_required_age;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_age_requirement IS 'Verifies customer age meets ESRB rating requirement';

-- ============================================
-- Promotion Functions
-- ============================================

-- Function: Get applicable discount for order
CREATE OR REPLACE FUNCTION get_promotion_discount(
    p_promotion_id INTEGER,
    p_subtotal DECIMAL
)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    v_promo RECORD;
    v_discount DECIMAL(10,2);
BEGIN
    SELECT * INTO v_promo
    FROM promotions
    WHERE promotion_id = p_promotion_id
        AND is_active = true
        AND CURRENT_DATE BETWEEN start_date AND end_date;
    
    IF NOT FOUND THEN
        RETURN 0.00;
    END IF;
    
    -- Check minimum purchase requirement
    IF p_subtotal < v_promo.min_purchase_amount THEN
        RETURN 0.00;
    END IF;
    
    -- Calculate discount
    IF v_promo.discount_percentage IS NOT NULL THEN
        v_discount := p_subtotal * (v_promo.discount_percentage / 100);
    ELSE
        v_discount := v_promo.discount_amount;
    END IF;
    
    RETURN LEAST(v_discount, p_subtotal);  -- Don't exceed subtotal
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_promotion_discount IS 'Calculates discount amount for a promotion';

-- ============================================
-- Reporting Functions
-- ============================================

-- Function: Get sales report for date range
CREATE OR REPLACE FUNCTION get_sales_report(
    p_start_date DATE,
    p_end_date DATE,
    p_store_id INTEGER DEFAULT NULL
)
RETURNS TABLE(
    total_orders INTEGER,
    total_revenue DECIMAL(12,2),
    avg_order_value DECIMAL(10,2),
    unique_customers INTEGER,
    items_sold INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT o.order_id)::INTEGER AS total_orders,
        COALESCE(SUM(o.total_amount), 0)::DECIMAL(12,2) AS total_revenue,
        COALESCE(AVG(o.total_amount), 0)::DECIMAL(10,2) AS avg_order_value,
        COUNT(DISTINCT o.customer_id)::INTEGER AS unique_customers,
        COALESCE(SUM(oi.quantity), 0)::INTEGER AS items_sold
    FROM orders o
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_date::DATE BETWEEN p_start_date AND p_end_date
        AND o.status NOT IN ('cancelled', 'refunded')
        AND (p_store_id IS NULL OR o.store_id = p_store_id);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_sales_report IS 'Generates sales summary for a date range';

-- Function: Get best selling games
CREATE OR REPLACE FUNCTION get_best_sellers(
    p_limit INTEGER DEFAULT 10,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE(
    game_title VARCHAR,
    platform_name VARCHAR,
    units_sold BIGINT,
    revenue DECIMAL(12,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        g.title AS game_title,
        p.platform_name,
        SUM(oi.quantity) AS units_sold,
        SUM(oi.line_total) AS revenue
    FROM order_items oi
    JOIN games g ON oi.game_id = g.game_id
    JOIN platforms p ON g.platform_id = p.platform_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status NOT IN ('cancelled', 'refunded')
        AND (p_start_date IS NULL OR o.order_date::DATE >= p_start_date)
        AND (p_end_date IS NULL OR o.order_date::DATE <= p_end_date)
    GROUP BY g.title, p.platform_name
    ORDER BY units_sold DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_best_sellers IS 'Returns top selling games by units sold';

-- ============================================
-- Utility Functions
-- ============================================

-- Function: Clean old data (for maintenance)
CREATE OR REPLACE FUNCTION archive_old_orders(p_days_old INTEGER DEFAULT 365)
RETURNS INTEGER AS $$
DECLARE
    v_archived_count INTEGER;
BEGIN
    -- This is a placeholder - in production, you'd move to archive table
    -- For now, just count how many orders would be archived
    SELECT COUNT(*) INTO v_archived_count
    FROM orders
    WHERE order_date < CURRENT_DATE - p_days_old * INTERVAL '1 day'
        AND status IN ('delivered', 'cancelled', 'refunded');
    
    RETURN v_archived_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION archive_old_orders IS 'Identifies orders eligible for archiving';

-- Functions creation complete
SELECT 'All functions created successfully!' AS status;
