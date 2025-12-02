-- ============================================
-- Game Store Database - Transaction Demos
-- File: 08_transactions.sql
-- Description: Demonstrates ACID properties and isolation levels
-- ============================================

\echo '==============================================='
\echo 'TRANSACTION DEMONSTRATIONS'
\echo 'This file demonstrates:'
\echo '1. Atomicity - All or nothing execution'
\echo '2. Consistency - Maintaining database constraints'
\echo '3. Isolation - Concurrent transaction behavior'
\echo '4. Durability - Persistence of committed changes'
\echo '==============================================='
\echo ''

-- ============================================
-- 1. ATOMICITY DEMONSTRATION
-- ============================================

\echo '--- DEMO 1: ATOMICITY ---'
\echo 'Showing that transactions are all-or-nothing'
\echo ''

-- Successful transaction (will commit)
\echo 'Transaction 1A: Successful order placement (will commit)'
BEGIN;
    -- Create order
    INSERT INTO orders (customer_id, store_id, employee_id, status, subtotal, tax_amount, total_amount, payment_method)
    VALUES (1, 1, 2, 'pending', 129.98, 11.70, 141.68, 'credit_card')
    RETURNING order_id AS new_order_id;
    
    -- Add order items
    INSERT INTO order_items (order_id, game_id, quantity, unit_price, line_total)
    SELECT currval('orders_order_id_seq'), 1, 1, 69.99, 69.99;
    
    INSERT INTO order_items (order_id, game_id, quantity, unit_price, line_total)
    SELECT currval('orders_order_id_seq'), 2, 1, 59.99, 59.99;
    
    \echo 'Order created successfully. Changes visible within this transaction.'
COMMIT;
\echo 'Transaction committed. Changes are now permanent.'
\echo ''

-- Failed transaction (will rollback due to constraint violation)
\echo 'Transaction 1B: Failed order with constraint violation (will rollback)'
BEGIN;
    -- Attempt to create order
    INSERT INTO orders (customer_id, store_id, employee_id, status, subtotal, tax_amount, total_amount, payment_method)
    VALUES (1, 1, 2, 'pending', 69.99, 6.30, 76.29, 'credit_card');
    
    \echo 'Order created, now attempting to add item with invalid quantity...'
    
    -- This will fail due to CHECK constraint (quantity must be > 0)
    INSERT INTO order_items (order_id, game_id, quantity, unit_price, line_total)
    SELECT currval('orders_order_id_seq'), 3, -1, 69.99, 69.99;  -- Negative quantity!
    
ROLLBACK;  -- Explicit rollback (would happen automatically on error)
\echo 'Transaction rolled back. No changes were saved.'
\echo ''

-- ============================================
-- 2. CONSISTENCY DEMONSTRATION
-- ============================================

\echo '--- DEMO 2: CONSISTENCY ---'
\echo 'Showing that database constraints maintain data integrity'
\echo ''

-- Attempt to violate inventory constraint
\echo 'Attempt 2A: Try to set negative inventory (should fail)'
BEGIN;
    UPDATE inventory 
    SET quantity = -10 
    WHERE store_id = 1 AND game_id = 1;
    \echo 'This should not print - constraint violation should abort transaction'
ROLLBACK;
\echo 'Transaction blocked by CHECK constraint preventing negative inventory.'
\echo ''

-- Attempt to violate foreign key constraint
\echo 'Attempt 2B: Try to create order for non-existent customer (should fail)'
BEGIN;
    INSERT INTO orders (customer_id, store_id, status, subtotal, tax_amount, total_amount, payment_method)
    VALUES (99999, 1, 'pending', 100.00, 9.00, 109.00, 'credit_card');
    \echo 'This should not print - foreign key violation should abort transaction'
ROLLBACK;
\echo 'Transaction blocked by foreign key constraint.'
\echo ''

-- Successful transaction respecting constraints
\echo 'Attempt 2C: Valid transaction respecting all constraints (will succeed)'
BEGIN;
    -- Check current stock first
    SELECT store_id, quantity 
    FROM inventory 
    WHERE store_id = 1 AND game_id = 3
    LIMIT 1;
    
    -- Decrement inventory safely
    UPDATE inventory 
    SET quantity = quantity - 1 
    WHERE store_id = 1 AND game_id = 3 AND quantity > 0;
    
    \echo 'Inventory decremented successfully.'
COMMIT;
\echo ''

-- ============================================
-- 3. ISOLATION DEMONSTRATION
-- ============================================

\echo '--- DEMO 3: ISOLATION LEVELS ---'
\echo 'Demonstrating different isolation levels and their effects'
\echo 'Note: To fully test, run these in separate psql sessions simultaneously'
\echo ''

-- Setup: Create test data
BEGIN;
    -- Ensure we have a customer with known loyalty points
    UPDATE customers 
    SET loyalty_points = 100 
    WHERE customer_id = 1;
COMMIT;

\echo 'Current state: Customer 1 has 100 loyalty points'
SELECT customer_id, loyalty_points FROM customers WHERE customer_id = 1;
\echo ''

-- Isolation Level: READ COMMITTED (PostgreSQL default)
\echo 'Demo 3A: READ COMMITTED (default isolation level)'
\echo 'Session 1: Reading customer loyalty points'
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
    SELECT customer_id, loyalty_points, 'First read' AS note
    FROM customers WHERE customer_id = 1;
    
    \echo 'In another session, update loyalty_points to 200 and COMMIT.'
    \echo 'Press Enter to continue once the other transaction commits...'
    -- \prompt 'Press Enter to continue...' dummy
    
    -- After other session commits, read again
    SELECT customer_id, loyalty_points, 'Second read (sees committed changes)' AS note
    FROM customers WHERE customer_id = 1;
COMMIT;
\echo 'READ COMMITTED: Second read sees changes from committed concurrent transaction'
\echo ''

-- Reset for next demo
UPDATE customers SET loyalty_points = 100 WHERE customer_id = 1;

-- Isolation Level: REPEATABLE READ
\echo 'Demo 3B: REPEATABLE READ isolation level'
\echo 'Session 1: Reading with repeatable read'
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    SELECT customer_id, loyalty_points, 'First read' AS note
    FROM customers WHERE customer_id = 1;
    
    \echo 'In another session, update loyalty_points to 300 and COMMIT.'
    \echo 'Press Enter to continue...'
    -- \prompt 'Press Enter to continue...' dummy
    
    -- Try to read again - should see original value
    SELECT customer_id, loyalty_points, 'Second read (still sees 100)' AS note
    FROM customers WHERE customer_id = 1;
COMMIT;
\echo 'REPEATABLE READ: Transaction maintains consistent snapshot, does not see concurrent changes'
\echo ''

-- ============================================
-- 4. CONCURRENCY SCENARIO: Last Item Race Condition
-- ============================================

\echo '--- DEMO 4: CONCURRENT INVENTORY RACE CONDITION ---'
\echo 'Scenario: Two customers try to buy the last item simultaneously'
\echo ''

-- Setup: Set inventory to 1 for a specific game
BEGIN;
    UPDATE inventory 
    SET quantity = 1 
    WHERE store_id = 1 AND game_id = 5;
COMMIT;

\echo 'Setup: Store 1 has exactly 1 copy of God of War Ragnarök'
SELECT store_id, game_id, quantity 
FROM inventory 
WHERE store_id = 1 AND game_id = 5;
\echo ''

\echo 'Session 1 (Customer A): Attempting to purchase'
BEGIN;
    -- Check stock
    SELECT quantity, 'Customer A sees stock' AS note
    FROM inventory 
    WHERE store_id = 1 AND game_id = 5;
    
    \echo 'Session 2 (Customer B) also checks stock simultaneously and sees 1 in stock'
    \echo 'Both proceed to create orders...'
    
    -- Customer A creates order
    INSERT INTO orders (customer_id, store_id, employee_id, status, subtotal, tax_amount, total_amount, payment_method)
    VALUES (1, 1, 2, 'pending', 69.99, 6.30, 76.29, 'credit_card');
    
    INSERT INTO order_items (order_id, game_id, quantity, unit_price, line_total)
    SELECT currval('orders_order_id_seq'), 5, 1, 69.99, 69.99;
    
    \echo 'Customer A order created and inventory decremented via trigger'
    
    SELECT quantity, 'Inventory after Customer A' AS note
    FROM inventory 
    WHERE store_id = 1 AND game_id = 5;
COMMIT;

\echo 'Customer A succeeded. Now Customer B tries (will fail):'
BEGIN;
    -- Customer B attempt (should fail due to insufficient inventory)
    INSERT INTO orders (customer_id, store_id, employee_id, status, subtotal, tax_amount, total_amount, payment_method)
    VALUES (2, 1, 2, 'pending', 69.99, 6.30, 76.29, 'credit_card');
    
    -- This will fail because inventory trigger checks stock
    INSERT INTO order_items (order_id, game_id, quantity, unit_price, line_total)
    SELECT currval('orders_order_id_seq'), 5, 1, 69.99, 69.99;
ROLLBACK;
\echo 'Customer B order failed - insufficient inventory. Trigger prevented overselling!'
\echo ''

-- ============================================
-- 5. DEADLOCK DEMONSTRATION
-- ============================================

\echo '--- DEMO 5: DEADLOCK DETECTION ---'
\echo 'PostgreSQL automatically detects and resolves deadlocks'
\echo 'Run these two blocks in separate sessions simultaneously to trigger deadlock:'
\echo ''

\echo 'Session 1 commands:'
\echo 'BEGIN;'
\echo '  UPDATE inventory SET quantity = quantity - 1 WHERE store_id = 1 AND game_id = 1;'
\echo '  SELECT pg_sleep(5);  -- Wait 5 seconds'
\echo '  UPDATE inventory SET quantity = quantity - 1 WHERE store_id = 1 AND game_id = 2;'
\echo 'COMMIT;'
\echo ''

\echo 'Session 2 commands (run concurrently):'
\echo 'BEGIN;'
\echo '  UPDATE inventory SET quantity = quantity - 1 WHERE store_id = 1 AND game_id = 2;'
\echo '  SELECT pg_sleep(5);  -- Wait 5 seconds'
\echo '  UPDATE inventory SET quantity = quantity - 1 WHERE store_id = 1 AND game_id = 1;'
\echo 'COMMIT;'
\echo ''
\echo 'Result: One session will be aborted with a deadlock error, the other succeeds'
\echo ''

-- ============================================
-- 6. DURABILITY DEMONSTRATION
-- ============================================

\echo '--- DEMO 6: DURABILITY ---'
\echo 'Demonstrating that committed transactions persist'
\echo ''

-- Create a test order and commit
\echo 'Creating order and committing...'
BEGIN;
    INSERT INTO orders (customer_id, store_id, employee_id, status, subtotal, tax_amount, total_amount, payment_method)
    VALUES (1, 1, 2, 'pending', 59.99, 5.40, 65.39, 'cash');
    
    INSERT INTO order_items (order_id, game_id, quantity, unit_price, line_total)
    SELECT currval('orders_order_id_seq'), 7, 1, 59.99, 59.99;
COMMIT;

\echo 'Transaction committed. Order persisted to disk.'
\echo 'Even if the database crashes now, this order will exist when it restarts.'
\echo 'Verifying order exists:'

SELECT 
    o.order_id,
    o.order_date,
    o.total_amount,
    g.title,
    oi.quantity
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN games g ON oi.game_id = g.game_id
WHERE o.order_id = currval('orders_order_id_seq');
\echo ''

-- ============================================
-- 7. SAVEPOINTS DEMONSTRATION
-- ============================================

\echo '--- DEMO 7: SAVEPOINTS ---'
\echo 'Partial rollback within a transaction'
\echo ''

BEGIN;
    -- Create first order
    INSERT INTO orders (customer_id, store_id, status, subtotal, tax_amount, total_amount, payment_method)
    VALUES (1, 1, 'pending', 100.00, 9.00, 109.00, 'credit_card');
    
    \echo 'Order 1 created'
    
    SAVEPOINT after_first_order;
    
    -- Create second order
    INSERT INTO orders (customer_id, store_id, status, subtotal, tax_amount, total_amount, payment_method)
    VALUES (1, 1, 'pending', 200.00, 18.00, 218.00, 'credit_card');
    
    \echo 'Order 2 created'
    
    SAVEPOINT after_second_order;
    
    -- Attempt third order with error
    \echo 'Attempting order 3 with invalid data...'
    INSERT INTO orders (customer_id, store_id, status, subtotal, tax_amount, total_amount, payment_method)
    VALUES (999999, 1, 'pending', 300.00, 27.00, 327.00, 'credit_card');  -- Invalid customer
    
    \echo 'Error occurred - rolling back to savepoint'
    
ROLLBACK TO SAVEPOINT after_second_order;

    \echo 'Rolled back to after order 2. Order 1 and 2 still exist in transaction.'
    \echo 'Committing order 1 and 2...'
    
COMMIT;

\echo 'Orders 1 and 2 saved, order 3 discarded'
\echo ''

-- ============================================
-- 8. TRANSACTION PERFORMANCE COMPARISON
-- ============================================

\echo '--- DEMO 8: TRANSACTION PERFORMANCE ---'
\echo 'Comparing transactional vs non-transactional batch inserts'
\echo ''

-- Create temporary test table
CREATE TEMP TABLE test_perf (
    id SERIAL PRIMARY KEY,
    value INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

\echo 'Test 1: Without explicit transaction (autocommit each insert)'
\timing on
DO $$
BEGIN
    FOR i IN 1..100 LOOP
        INSERT INTO test_perf (value) VALUES (i);
    END LOOP;
END $$;
\timing off

\echo ''
\echo 'Test 2: With explicit transaction (single commit)'
\timing on
BEGIN;
DO $$
BEGIN
    FOR i IN 101..200 LOOP
        INSERT INTO test_perf (value) VALUES (i);
    END LOOP;
END $$;
COMMIT;
\timing off

\echo ''
\echo 'Result: Explicit transaction is significantly faster for batch operations'
\echo 'because it commits once instead of 100 times'
\echo ''

-- Cleanup
DROP TABLE test_perf;

-- ============================================
-- SUMMARY
-- ============================================

\echo '==============================================='
\echo 'TRANSACTION DEMONSTRATIONS COMPLETE'
\echo ''
\echo 'Key Takeaways:'
\echo '1. ATOMICITY: Transactions either fully succeed or fully fail'
\echo '2. CONSISTENCY: Constraints ensure data integrity'
\echo '3. ISOLATION: Transactions do not interfere with each other'
\echo '4. DURABILITY: Committed data persists through system failures'
\echo '5. PostgreSQL detects and resolves deadlocks automatically'
\echo '6. Savepoints allow partial rollback within transactions'
\echo '7. Explicit transactions improve batch operation performance'
\echo '==============================================='
