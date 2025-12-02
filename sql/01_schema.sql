-- ============================================
-- Game Store Database Schema (DDL)
-- File: 01_schema.sql
-- Description: Creates all tables, types, and constraints
-- ============================================

-- Drop existing tables if they exist (for clean reinstall)
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS pre_orders CASCADE;
DROP TABLE IF EXISTS returns CASCADE;
DROP TABLE IF EXISTS loyalty_transactions CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS purchase_order_items CASCADE;
DROP TABLE IF EXISTS purchase_orders CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS game_genres CASCADE;
DROP TABLE IF EXISTS games CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS promotions CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS stores CASCADE;
DROP TABLE IF EXISTS vendors CASCADE;
DROP TABLE IF EXISTS publishers CASCADE;
DROP TABLE IF EXISTS platforms CASCADE;
DROP TABLE IF EXISTS genres CASCADE;
DROP TABLE IF EXISTS product_categories CASCADE;

-- Drop types if they exist
DROP TYPE IF EXISTS order_status CASCADE;
DROP TYPE IF EXISTS payment_method CASCADE;
DROP TYPE IF EXISTS employee_role CASCADE;
DROP TYPE IF EXISTS esrb_rating CASCADE;
DROP TYPE IF EXISTS product_type CASCADE;
DROP TYPE IF EXISTS return_status CASCADE;

-- ============================================
-- Custom Types
-- ============================================

CREATE TYPE order_status AS ENUM (
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'refunded'
);

CREATE TYPE payment_method AS ENUM (
    'credit_card',
    'debit_card',
    'cash',
    'gift_card',
    'loyalty_points'
);

CREATE TYPE employee_role AS ENUM (
    'cashier',
    'sales_associate',
    'inventory_clerk',
    'store_manager',
    'assistant_manager'
);

CREATE TYPE esrb_rating AS ENUM (
    'E',      -- Everyone
    'E10+',   -- Everyone 10+
    'T',      -- Teen
    'M',      -- Mature 17+
    'AO',     -- Adults Only 18+
    'RP'      -- Rating Pending
);

CREATE TYPE product_type AS ENUM (
    'game',
    'console',
    'accessory'
);

CREATE TYPE return_status AS ENUM (
    'pending',
    'approved',
    'rejected',
    'completed'
);

-- ============================================
-- Reference Tables
-- ============================================

-- Platforms (PlayStation, Xbox, Nintendo, PC, etc.)
CREATE TABLE platforms (
    platform_id SERIAL PRIMARY KEY,
    platform_name VARCHAR(100) NOT NULL UNIQUE,
    manufacturer VARCHAR(100),
    release_year INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Genres (Action, RPG, Sports, etc.)
CREATE TABLE genres (
    genre_id SERIAL PRIMARY KEY,
    genre_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Publishers
CREATE TABLE publishers (
    publisher_id SERIAL PRIMARY KEY,
    publisher_name VARCHAR(200) NOT NULL UNIQUE,
    country VARCHAR(100),
    website VARCHAR(255),
    contact_email VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Vendors/Suppliers
CREATE TABLE vendors (
    vendor_id SERIAL PRIMARY KEY,
    vendor_name VARCHAR(200) NOT NULL,
    contact_name VARCHAR(100),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    address TEXT,
    payment_terms VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Product Categories
CREATE TABLE product_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    category_type product_type NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- Store & Employee Tables
-- ============================================

-- Stores
CREATE TABLE stores (
    store_id SERIAL PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    zip_code VARCHAR(10) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    manager_id INTEGER,  -- Will reference employees
    is_active BOOLEAN DEFAULT true,
    opened_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Employees
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    store_id INTEGER NOT NULL REFERENCES stores(store_id),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20),
    role employee_role NOT NULL,
    hire_date DATE NOT NULL,
    salary DECIMAL(10,2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add foreign key for store manager
ALTER TABLE stores
ADD CONSTRAINT fk_store_manager
FOREIGN KEY (manager_id) REFERENCES employees(employee_id);

-- ============================================
-- Customer Tables
-- ============================================

-- Customers
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    loyalty_points INTEGER DEFAULT 0 CHECK (loyalty_points >= 0),
    total_spent DECIMAL(10,2) DEFAULT 0.00,
    join_date DATE DEFAULT CURRENT_DATE,
    is_active BOOLEAN DEFAULT true,
    age_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- Product Tables
-- ============================================

-- Games
CREATE TABLE games (
    game_id SERIAL PRIMARY KEY,
    sku VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    platform_id INTEGER NOT NULL REFERENCES platforms(platform_id),
    publisher_id INTEGER NOT NULL REFERENCES publishers(publisher_id),
    release_date DATE,
    esrb_rating esrb_rating NOT NULL,
    description TEXT,
    base_price DECIMAL(10,2) NOT NULL CHECK (base_price >= 0),
    is_digital_only BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Game-Genre junction table (many-to-many)
CREATE TABLE game_genres (
    game_id INTEGER NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
    genre_id INTEGER NOT NULL REFERENCES genres(genre_id) ON DELETE CASCADE,
    PRIMARY KEY (game_id, genre_id)
);

-- Products (consoles and accessories)
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    sku VARCHAR(50) NOT NULL UNIQUE,
    product_name VARCHAR(255) NOT NULL,
    category_id INTEGER NOT NULL REFERENCES product_categories(category_id),
    platform_id INTEGER REFERENCES platforms(platform_id),  -- nullable for universal accessories
    description TEXT,
    base_price DECIMAL(10,2) NOT NULL CHECK (base_price >= 0),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- Inventory Tables
-- ============================================

-- Inventory (tracks stock per store)
CREATE TABLE inventory (
    inventory_id SERIAL PRIMARY KEY,
    store_id INTEGER NOT NULL REFERENCES stores(store_id),
    game_id INTEGER REFERENCES games(game_id),
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    reorder_level INTEGER DEFAULT 10,
    last_restocked DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_game_or_product CHECK (
        (game_id IS NOT NULL AND product_id IS NULL) OR
        (game_id IS NULL AND product_id IS NOT NULL)
    ),
    CONSTRAINT unique_store_item UNIQUE (store_id, game_id, product_id)
);

-- ============================================
-- Promotion Tables
-- ============================================

-- Promotions
CREATE TABLE promotions (
    promotion_id SERIAL PRIMARY KEY,
    promotion_name VARCHAR(200) NOT NULL,
    description TEXT,
    discount_percentage DECIMAL(5,2) CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    discount_amount DECIMAL(10,2) CHECK (discount_amount >= 0),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    min_purchase_amount DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_dates CHECK (end_date >= start_date),
    CONSTRAINT check_discount CHECK (
        (discount_percentage IS NOT NULL AND discount_amount IS NULL) OR
        (discount_percentage IS NULL AND discount_amount IS NOT NULL)
    )
);

-- ============================================
-- Order Tables
-- ============================================

-- Orders
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    store_id INTEGER REFERENCES stores(store_id),  -- NULL for online orders
    employee_id INTEGER REFERENCES employees(employee_id),  -- NULL for online orders
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status order_status DEFAULT 'pending',
    subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
    tax_amount DECIMAL(10,2) DEFAULT 0 CHECK (tax_amount >= 0),
    discount_amount DECIMAL(10,2) DEFAULT 0 CHECK (discount_amount >= 0),
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
    payment_method payment_method NOT NULL,
    promotion_id INTEGER REFERENCES promotions(promotion_id),
    is_online BOOLEAN DEFAULT false,
    shipping_address TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order Items
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    game_id INTEGER REFERENCES games(game_id),
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    discount_amount DECIMAL(10,2) DEFAULT 0 CHECK (discount_amount >= 0),
    line_total DECIMAL(10,2) NOT NULL CHECK (line_total >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_game_or_product_item CHECK (
        (game_id IS NOT NULL AND product_id IS NULL) OR
        (game_id IS NULL AND product_id IS NOT NULL)
    )
);

-- ============================================
-- Pre-Order Tables
-- ============================================

-- Pre-Orders
CREATE TABLE pre_orders (
    pre_order_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    game_id INTEGER NOT NULL REFERENCES games(game_id),
    store_id INTEGER REFERENCES stores(store_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    deposit_amount DECIMAL(10,2) NOT NULL CHECK (deposit_amount >= 0),
    total_price DECIMAL(10,2) NOT NULL CHECK (total_price >= 0),
    pre_order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expected_release_date DATE NOT NULL,
    is_fulfilled BOOLEAN DEFAULT false,
    fulfilled_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_future_release CHECK (expected_release_date > CURRENT_DATE)
);

-- ============================================
-- Return Tables
-- ============================================

-- Returns
CREATE TABLE returns (
    return_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(order_id),
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    employee_id INTEGER REFERENCES employees(employee_id),
    return_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reason TEXT,
    condition VARCHAR(50),  -- 'unopened', 'opened', 'defective'
    refund_amount DECIMAL(10,2) NOT NULL CHECK (refund_amount >= 0),
    status return_status DEFAULT 'pending',
    approved_by INTEGER REFERENCES employees(employee_id),
    approved_date TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_return_window CHECK (
        return_date <= (SELECT order_date FROM orders WHERE order_id = returns.order_id) + INTERVAL '30 days'
    )
);

-- ============================================
-- Loyalty Program Tables
-- ============================================

-- Loyalty Transactions
CREATE TABLE loyalty_transactions (
    transaction_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    order_id INTEGER REFERENCES orders(order_id),
    points_earned INTEGER DEFAULT 0,
    points_redeemed INTEGER DEFAULT 0,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    CONSTRAINT check_points CHECK (
        (points_earned > 0 AND points_redeemed = 0) OR
        (points_earned = 0 AND points_redeemed > 0)
    )
);

-- ============================================
-- Purchase Order Tables (from vendors)
-- ============================================

-- Purchase Orders
CREATE TABLE purchase_orders (
    po_id SERIAL PRIMARY KEY,
    vendor_id INTEGER NOT NULL REFERENCES vendors(vendor_id),
    store_id INTEGER NOT NULL REFERENCES stores(store_id),
    order_date DATE DEFAULT CURRENT_DATE,
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    status VARCHAR(50) DEFAULT 'pending',
    total_amount DECIMAL(10,2) CHECK (total_amount >= 0),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Purchase Order Items
CREATE TABLE purchase_order_items (
    po_item_id SERIAL PRIMARY KEY,
    po_id INTEGER NOT NULL REFERENCES purchase_orders(po_id) ON DELETE CASCADE,
    game_id INTEGER REFERENCES games(game_id),
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_cost DECIMAL(10,2) NOT NULL CHECK (unit_cost >= 0),
    line_total DECIMAL(10,2) NOT NULL CHECK (line_total >= 0),
    CONSTRAINT check_game_or_product_po CHECK (
        (game_id IS NOT NULL AND product_id IS NULL) OR
        (game_id IS NULL AND product_id IS NOT NULL)
    )
);

-- ============================================
-- Review Tables
-- ============================================

-- Reviews
CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    game_id INTEGER NOT NULL REFERENCES games(game_id),
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_verified_purchase BOOLEAN DEFAULT false,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_customer_game_review UNIQUE (game_id, customer_id)
);

-- ============================================
-- Comments and Indexes
-- ============================================

COMMENT ON TABLE games IS 'Video game catalog with platform, rating, and pricing information';
COMMENT ON TABLE customers IS 'Customer accounts with loyalty program tracking';
COMMENT ON TABLE orders IS 'Sales transactions for both in-store and online purchases';
COMMENT ON TABLE inventory IS 'Stock levels per store for all products and games';
COMMENT ON TABLE pre_orders IS 'Pre-order reservations for upcoming game releases';
COMMENT ON TABLE reviews IS 'Customer reviews and ratings for games';

-- Schema creation complete
