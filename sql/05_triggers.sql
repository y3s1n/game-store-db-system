-- ============================================
-- Game Store Database - Triggers
-- File: 05_triggers.sql
-- Description: Business rule enforcement through triggers
-- ============================================

-- ============================================
-- Inventory Management Triggers
-- ============================================

-- Trigger: Prevent negative inventory
CREATE OR REPLACE FUNCTION trg_prevent_negative_inventory()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.quantity < 0 THEN
        RAISE EXCEPTION 'Inventory quantity cannot be negative for store %, item %', 
            NEW.store_id, COALESCE(NEW.game_id, NEW.product_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_negative_inventory
BEFORE INSERT OR UPDATE ON inventory
FOR EACH ROW
EXECUTE FUNCTION trg_prevent_negative_inventory();

COMMENT ON TRIGGER prevent_negative_inventory ON inventory IS 'Ensures inventory quantity never goes below zero';

-- Trigger: Update inventory timestamp
CREATE OR REPLACE FUNCTION trg_update_inventory_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_inventory_timestamp
BEFORE UPDATE ON inventory
FOR EACH ROW
EXECUTE FUNCTION trg_update_inventory_timestamp();

-- ============================================
-- Order Processing Triggers
-- ============================================

-- Trigger: Validate order items before insert
CREATE OR REPLACE FUNCTION trg_validate_order_item()
RETURNS TRIGGER AS $$
DECLARE
    v_order_store_id INTEGER;
    v_available_stock INTEGER;
BEGIN
    -- Get the store_id from the order
    SELECT store_id INTO v_order_store_id
    FROM orders
    WHERE order_id = NEW.order_id;
    
    -- Only check inventory for in-store orders
    IF v_order_store_id IS NOT NULL THEN
        -- Check if sufficient inventory exists
        SELECT quantity INTO v_available_stock
        FROM inventory
        WHERE store_id = v_order_store_id
            AND (game_id = NEW.game_id OR product_id = NEW.product_id);
        
        IF v_available_stock IS NULL OR v_available_stock < NEW.quantity THEN
            RAISE EXCEPTION 'Insufficient inventory for item. Available: %, Requested: %',
                COALESCE(v_available_stock, 0), NEW.quantity;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_order_item
BEFORE INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION trg_validate_order_item();

COMMENT ON TRIGGER validate_order_item ON order_items IS 'Validates sufficient inventory before adding order item';

-- Trigger: Decrement inventory after order item insert
CREATE OR REPLACE FUNCTION trg_decrement_inventory_on_order()
RETURNS TRIGGER AS $$
DECLARE
    v_order_store_id INTEGER;
    v_order_status order_status;
BEGIN
    -- Get order details
    SELECT store_id, status INTO v_order_store_id, v_order_status
    FROM orders
    WHERE order_id = NEW.order_id;
    
    -- Only decrement for in-store orders that are not cancelled/refunded
    IF v_order_store_id IS NOT NULL AND v_order_status NOT IN ('cancelled', 'refunded') THEN
        UPDATE inventory
        SET quantity = quantity - NEW.quantity,
            updated_at = CURRENT_TIMESTAMP
        WHERE store_id = v_order_store_id
            AND (game_id = NEW.game_id OR product_id = NEW.product_id);
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Inventory record not found for store % and item %',
                v_order_store_id, COALESCE(NEW.game_id, NEW.product_id);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER decrement_inventory_on_order
AFTER INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION trg_decrement_inventory_on_order();

COMMENT ON TRIGGER decrement_inventory_on_order ON order_items IS 'Decrements inventory when order item is added';

-- Trigger: Calculate order totals
CREATE OR REPLACE FUNCTION trg_calculate_order_item_total()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate line total
    NEW.line_total = (NEW.unit_price * NEW.quantity) - NEW.discount_amount;
    
    -- Ensure line total is not negative
    IF NEW.line_total < 0 THEN
        NEW.line_total = 0;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_order_item_total
BEFORE INSERT OR UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION trg_calculate_order_item_total();

COMMENT ON TRIGGER calculate_order_item_total ON order_items IS 'Automatically calculates line total for order items';

-- Trigger: Update order timestamp
CREATE OR REPLACE FUNCTION trg_update_order_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_order_timestamp
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION trg_update_order_timestamp();

-- ============================================
-- Customer and Loyalty Triggers
-- ============================================

-- Trigger: Award loyalty points after order
CREATE OR REPLACE FUNCTION trg_award_loyalty_points()
RETURNS TRIGGER AS $$
DECLARE
    v_points_earned INTEGER;
BEGIN
    -- Only award points for completed orders
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        -- Calculate points (1 point per $10 spent)
        v_points_earned := calculate_loyalty_points(NEW.total_amount);
        
        -- Update customer points
        UPDATE customers
        SET loyalty_points = loyalty_points + v_points_earned,
            total_spent = total_spent + NEW.total_amount,
            updated_at = CURRENT_TIMESTAMP
        WHERE customer_id = NEW.customer_id;
        
        -- Record transaction
        INSERT INTO loyalty_transactions (customer_id, order_id, points_earned, description)
        VALUES (NEW.customer_id, NEW.order_id, v_points_earned, 'Points earned from order');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER award_loyalty_points
AFTER UPDATE ON orders
FOR EACH ROW
WHEN (NEW.status = 'delivered')
EXECUTE FUNCTION trg_award_loyalty_points();

COMMENT ON TRIGGER award_loyalty_points ON orders IS 'Awards loyalty points when order is delivered';

-- Trigger: Update customer timestamp
CREATE OR REPLACE FUNCTION trg_update_customer_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_customer_timestamp
BEFORE UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION trg_update_customer_timestamp();

-- Trigger: Validate loyalty points balance
CREATE OR REPLACE FUNCTION trg_validate_loyalty_points()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.loyalty_points < 0 THEN
        RAISE EXCEPTION 'Customer loyalty points cannot be negative. Customer ID: %', NEW.customer_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_loyalty_points
BEFORE UPDATE ON customers
FOR EACH ROW
WHEN (NEW.loyalty_points IS DISTINCT FROM OLD.loyalty_points)
EXECUTE FUNCTION trg_validate_loyalty_points();

COMMENT ON TRIGGER validate_loyalty_points ON customers IS 'Ensures loyalty points balance stays non-negative';

-- ============================================
-- Age Verification Triggers
-- ============================================

-- Trigger: Enforce age verification for mature games
CREATE OR REPLACE FUNCTION trg_enforce_age_verification()
RETURNS TRIGGER AS $$
DECLARE
    v_game_rating esrb_rating;
    v_customer_age INTEGER;
    v_age_verified BOOLEAN;
    v_customer_dob DATE;
BEGIN
    -- Only check for game purchases
    IF NEW.game_id IS NOT NULL THEN
        -- Get game rating
        SELECT esrb_rating INTO v_game_rating
        FROM games
        WHERE game_id = NEW.game_id;
        
        -- Only enforce for M and AO rated games
        IF v_game_rating IN ('M', 'AO') THEN
            -- Get customer info
            SELECT date_of_birth, age_verified 
            INTO v_customer_dob, v_age_verified
            FROM customers c
            JOIN orders o ON c.customer_id = o.customer_id
            WHERE o.order_id = NEW.order_id;
            
            -- Check if customer has date of birth on file
            IF v_customer_dob IS NULL THEN
                RAISE EXCEPTION 'Date of birth required to purchase % rated game', v_game_rating;
            END IF;
            
            -- Calculate age
            v_customer_age := EXTRACT(YEAR FROM AGE(v_customer_dob));
            
            -- Check age requirement
            IF (v_game_rating = 'M' AND v_customer_age < 17) OR 
               (v_game_rating = 'AO' AND v_customer_age < 18) THEN
                RAISE EXCEPTION 'Customer does not meet age requirement for % rated game. Customer age: %', 
                    v_game_rating, v_customer_age;
            END IF;
            
            -- Check if age has been verified
            IF NOT v_age_verified THEN
                RAISE EXCEPTION 'Age verification required for % rated game purchase', v_game_rating;
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_age_verification
BEFORE INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION trg_enforce_age_verification();

COMMENT ON TRIGGER enforce_age_verification ON order_items IS 'Enforces age verification for mature-rated games';

-- ============================================
-- Pre-Order Triggers
-- ============================================

-- Trigger: Validate pre-order requirements
CREATE OR REPLACE FUNCTION trg_validate_preorder()
RETURNS TRIGGER AS $$
DECLARE
    v_game_release_date DATE;
BEGIN
    -- Get game release date
    SELECT release_date INTO v_game_release_date
    FROM games
    WHERE game_id = NEW.game_id;
    
    -- Ensure release date is in the future
    IF v_game_release_date <= CURRENT_DATE THEN
        RAISE EXCEPTION 'Pre-orders only allowed for games with future release dates';
    END IF;
    
    -- Ensure expected release matches game release
    IF NEW.expected_release_date != v_game_release_date THEN
        NEW.expected_release_date := v_game_release_date;
    END IF;
    
    -- Ensure deposit is at least 10% of total
    IF NEW.deposit_amount < (NEW.total_price * 0.10) THEN
        RAISE EXCEPTION 'Deposit must be at least 10%% of total price';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_preorder
BEFORE INSERT ON pre_orders
FOR EACH ROW
EXECUTE FUNCTION trg_validate_preorder();

COMMENT ON TRIGGER validate_preorder ON pre_orders IS 'Validates pre-order business rules';

-- Trigger: Update pre-order timestamp
CREATE OR REPLACE FUNCTION trg_update_preorder_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_preorder_timestamp
BEFORE UPDATE ON pre_orders
FOR EACH ROW
EXECUTE FUNCTION trg_update_preorder_timestamp();

-- ============================================
-- Review Triggers
-- ============================================

-- Trigger: Verify purchase before allowing review
CREATE OR REPLACE FUNCTION trg_verify_review_purchase()
RETURNS TRIGGER AS $$
DECLARE
    v_has_purchased BOOLEAN;
BEGIN
    -- Check if customer has purchased this game
    SELECT EXISTS(
        SELECT 1
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.customer_id = NEW.customer_id
            AND oi.game_id = NEW.game_id
            AND o.status = 'delivered'
    ) INTO v_has_purchased;
    
    NEW.is_verified_purchase := v_has_purchased;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER verify_review_purchase
BEFORE INSERT ON reviews
FOR EACH ROW
EXECUTE FUNCTION trg_verify_review_purchase();

COMMENT ON TRIGGER verify_review_purchase ON reviews IS 'Marks review as verified if customer purchased the game';

-- Trigger: Update review timestamp
CREATE OR REPLACE FUNCTION trg_update_review_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_review_timestamp
BEFORE UPDATE ON reviews
FOR EACH ROW
EXECUTE FUNCTION trg_update_review_timestamp();

-- ============================================
-- Return Processing Triggers
-- ============================================

-- Trigger: Validate return window
CREATE OR REPLACE FUNCTION trg_validate_return_window()
RETURNS TRIGGER AS $$
DECLARE
    v_order_date TIMESTAMP;
    v_days_elapsed INTEGER;
BEGIN
    -- Get order date
    SELECT order_date INTO v_order_date
    FROM orders
    WHERE order_id = NEW.order_id;
    
    -- Calculate days since order
    v_days_elapsed := EXTRACT(DAY FROM (NEW.return_date - v_order_date));
    
    -- Check 30-day return window
    IF v_days_elapsed > 30 THEN
        RAISE EXCEPTION 'Return request exceeds 30-day return window. Days elapsed: %', v_days_elapsed;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_return_window
BEFORE INSERT ON returns
FOR EACH ROW
EXECUTE FUNCTION trg_validate_return_window();

COMMENT ON TRIGGER validate_return_window ON returns IS 'Enforces 30-day return window policy';

-- Trigger: Restore inventory on approved return
CREATE OR REPLACE FUNCTION trg_restore_inventory_on_return()
RETURNS TRIGGER AS $$
DECLARE
    v_order_store_id INTEGER;
    v_item_record RECORD;
BEGIN
    -- Only restore inventory when return is approved
    IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status != 'approved') THEN
        -- Get store from order
        SELECT store_id INTO v_order_store_id
        FROM orders
        WHERE order_id = NEW.order_id;
        
        -- Only restore for in-store purchases
        IF v_order_store_id IS NOT NULL THEN
            -- Restore inventory for all items in the order
            FOR v_item_record IN 
                SELECT game_id, product_id, quantity 
                FROM order_items 
                WHERE order_id = NEW.order_id
            LOOP
                UPDATE inventory
                SET quantity = quantity + v_item_record.quantity,
                    updated_at = CURRENT_TIMESTAMP
                WHERE store_id = v_order_store_id
                    AND (game_id = v_item_record.game_id OR product_id = v_item_record.product_id);
            END LOOP;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER restore_inventory_on_return
AFTER UPDATE ON returns
FOR EACH ROW
WHEN (NEW.status = 'approved')
EXECUTE FUNCTION trg_restore_inventory_on_return();

COMMENT ON TRIGGER restore_inventory_on_return ON returns IS 'Restores inventory when return is approved';

-- ============================================
-- Game and Product Triggers
-- ============================================

-- Trigger: Update game timestamp
CREATE OR REPLACE FUNCTION trg_update_game_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_game_timestamp
BEFORE UPDATE ON games
FOR EACH ROW
EXECUTE FUNCTION trg_update_game_timestamp();

-- Trigger: Update product timestamp
CREATE OR REPLACE FUNCTION trg_update_product_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_product_timestamp
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION trg_update_product_timestamp();

-- Triggers creation complete
SELECT 'All triggers created successfully!' AS status;
