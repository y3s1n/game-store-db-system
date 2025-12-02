#!/usr/bin/env python3
"""
Query Performance Analysis Script
Runs EXPLAIN ANALYZE on key queries to show execution plans and performance
"""

import os
import sys
import psycopg2
from datetime import datetime

# ============================================
# Configuration
# ============================================

DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'user': 'postgres',
    'password': 'postgres',  # Change this to your PostgreSQL password
    'database': 'game_store'
}

# ============================================
# Queries to Analyze
# ============================================

QUERIES_TO_ANALYZE = [
    {
        'name': 'Game Catalog Lookup by Platform',
        'description': 'Browsing games for a specific platform with ratings',
        'query': """
            SELECT 
                g.title,
                g.base_price,
                g.esrb_rating,
                STRING_AGG(gen.genre_name, ', ') AS genres,
                ROUND(AVG(r.rating), 2) AS avg_rating
            FROM games g
            JOIN platforms p ON g.platform_id = p.platform_id
            LEFT JOIN game_genres gg ON g.game_id = gg.game_id
            LEFT JOIN genres gen ON gg.genre_id = gen.genre_id
            LEFT JOIN reviews r ON g.game_id = r.game_id
            WHERE p.platform_name = 'PlayStation 5'
                AND g.is_active = true
            GROUP BY g.game_id, g.title, g.base_price, g.esrb_rating
            ORDER BY avg_rating DESC NULLS LAST;
        """
    },
    {
        'name': 'Inventory Check Across Stores',
        'description': 'Finding which stores have a specific game in stock',
        'query': """
            SELECT 
                s.store_name,
                s.city,
                i.quantity
            FROM stores s
            LEFT JOIN inventory i ON s.store_id = i.store_id 
                AND i.game_id = (SELECT game_id FROM games WHERE sku = 'PS5-001' LIMIT 1)
            WHERE s.is_active = true
            ORDER BY i.quantity DESC NULLS LAST;
        """
    },
    {
        'name': 'Best Sellers Report',
        'description': 'Finding top-selling games by revenue',
        'query': """
            SELECT 
                g.title,
                p.platform_name,
                SUM(oi.quantity) AS units_sold,
                SUM(oi.line_total) AS total_revenue
            FROM order_items oi
            JOIN games g ON oi.game_id = g.game_id
            JOIN platforms p ON g.platform_id = p.platform_id
            JOIN orders o ON oi.order_id = o.order_id
            WHERE o.status NOT IN ('cancelled', 'refunded')
            GROUP BY g.game_id, g.title, p.platform_name
            ORDER BY total_revenue DESC
            LIMIT 10;
        """
    },
    {
        'name': 'Customer Lifetime Value',
        'description': 'Calculating top customers by total spending',
        'query': """
            SELECT 
                c.customer_id,
                c.first_name || ' ' || c.last_name AS customer_name,
                COUNT(DISTINCT o.order_id) AS total_orders,
                SUM(o.total_amount) AS lifetime_value
            FROM customers c
            JOIN orders o ON c.customer_id = o.customer_id
            WHERE o.status NOT IN ('cancelled', 'refunded')
            GROUP BY c.customer_id, c.first_name, c.last_name
            ORDER BY lifetime_value DESC
            LIMIT 20;
        """
    },
    {
        'name': 'Store Performance Comparison',
        'description': 'Comparing sales metrics across stores',
        'query': """
            SELECT 
                s.store_name,
                COUNT(DISTINCT o.order_id) AS order_count,
                SUM(o.total_amount) AS total_revenue,
                ROUND(AVG(o.total_amount), 2) AS avg_order_value
            FROM stores s
            LEFT JOIN orders o ON s.store_id = o.store_id
            WHERE (o.status NOT IN ('cancelled', 'refunded') OR o.order_id IS NULL)
            GROUP BY s.store_id, s.store_name
            ORDER BY total_revenue DESC NULLS LAST;
        """
    },
    {
        'name': 'Low Stock Items Report',
        'description': 'Finding items that need reordering',
        'query': """
            SELECT 
                s.store_name,
                COALESCE(g.title, pr.product_name) AS item_name,
                i.quantity,
                i.reorder_level
            FROM inventory i
            JOIN stores s ON i.store_id = s.store_id
            LEFT JOIN games g ON i.game_id = g.game_id
            LEFT JOIN products pr ON i.product_id = pr.product_id
            WHERE i.quantity <= i.reorder_level
            ORDER BY i.quantity ASC;
        """
    }
]

# ============================================
# Helper Functions
# ============================================

def print_header(message):
    """Print a formatted header"""
    print("\n" + "=" * 80)
    print(message)
    print("=" * 80)

def print_section(message):
    """Print a section header"""
    print("\n" + "-" * 80)
    print(message)
    print("-" * 80)

def analyze_query(cursor, query_info):
    """Run EXPLAIN ANALYZE on a query and display results"""
    print_section(f"Query: {query_info['name']}")
    print(f"Description: {query_info['description']}\n")
    
    try:
        # Run EXPLAIN ANALYZE
        explain_query = f"EXPLAIN (ANALYZE, BUFFERS, VERBOSE) {query_info['query']}"
        cursor.execute(explain_query)
        
        # Get results
        results = cursor.fetchall()
        
        # Print query plan
        print("Execution Plan:")
        print("-" * 80)
        for row in results:
            print(row[0])
        
        # Extract and display key metrics
        print("\n" + "-" * 80)
        print("Key Metrics:")
        
        for row in results:
            line = row[0]
            if 'Planning Time:' in line:
                print(f"  {line.strip()}")
            elif 'Execution Time:' in line:
                print(f"  {line.strip()}")
            elif 'Buffers:' in line:
                print(f"  {line.strip()}")
        
        return True
        
    except psycopg2.Error as e:
        print(f"ERROR: Query analysis failed")
        print(f"  {e}")
        return False

def run_simple_benchmark(cursor, query_info, iterations=5):
    """Run a query multiple times and calculate average execution time"""
    print_section(f"Benchmark: {query_info['name']}")
    print(f"Running query {iterations} times...\n")
    
    times = []
    
    try:
        for i in range(iterations):
            start = datetime.now()
            cursor.execute(query_info['query'])
            cursor.fetchall()  # Ensure all results are retrieved
            end = datetime.now()
            
            duration_ms = (end - start).total_seconds() * 1000
            times.append(duration_ms)
            print(f"  Run {i+1}: {duration_ms:.2f} ms")
        
        # Calculate statistics
        avg_time = sum(times) / len(times)
        min_time = min(times)
        max_time = max(times)
        
        print(f"\nStatistics:")
        print(f"  Average: {avg_time:.2f} ms")
        print(f"  Min:     {min_time:.2f} ms")
        print(f"  Max:     {max_time:.2f} ms")
        
        return True
        
    except psycopg2.Error as e:
        print(f"ERROR: Benchmark failed")
        print(f"  {e}")
        return False

def get_index_usage_stats(cursor):
    """Display index usage statistics"""
    print_section("Index Usage Statistics")
    print("Shows which indexes are being used and how often\n")
    
    try:
        cursor.execute("""
            SELECT 
                schemaname,
                tablename,
                indexname,
                idx_scan AS scans,
                idx_tup_read AS tuples_read,
                idx_tup_fetch AS tuples_fetched
            FROM pg_stat_user_indexes
            WHERE schemaname = 'public'
            ORDER BY idx_scan DESC
            LIMIT 20;
        """)
        
        results = cursor.fetchall()
        
        if results:
            print(f"{'Table':<20} {'Index':<35} {'Scans':<10} {'Tuples Read':<12} {'Tuples Fetched':<15}")
            print("-" * 95)
            for row in results:
                table = row[1][:19]
                index = row[2][:34]
                scans = row[3]
                tup_read = row[4]
                tup_fetch = row[5]
                print(f"{table:<20} {index:<35} {scans:<10} {tup_read:<12} {tup_fetch:<15}")
        else:
            print("No index usage data available yet. Run some queries first.")
        
        return True
        
    except psycopg2.Error as e:
        print(f"ERROR: Failed to retrieve index stats")
        print(f"  {e}")
        return False

def get_table_sizes(cursor):
    """Display table and index sizes"""
    print_section("Database Size Information")
    
    try:
        cursor.execute("""
            SELECT 
                tablename,
                pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
                pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
                pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - 
                              pg_relation_size(schemaname||'.'||tablename)) AS indexes_size
            FROM pg_tables
            WHERE schemaname = 'public'
            ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
            LIMIT 15;
        """)
        
        results = cursor.fetchall()
        
        print(f"\n{'Table':<25} {'Total Size':<12} {'Table Size':<12} {'Indexes Size':<12}")
        print("-" * 65)
        for row in results:
            print(f"{row[0]:<25} {row[1]:<12} {row[2]:<12} {row[3]:<12}")
        
        return True
        
    except psycopg2.Error as e:
        print(f"ERROR: Failed to retrieve table sizes")
        print(f"  {e}")
        return False

# ============================================
# Main Execution
# ============================================

def main():
    """Main execution function"""
    print_header("Game Store Database - Query Performance Analysis")
    print(f"\nAnalyzing {len(QUERIES_TO_ANALYZE)} key queries")
    print("This will show execution plans, timing, and optimization opportunities\n")
    
    try:
        # Connect to database
        print("Connecting to database...")
        conn = psycopg2.connect(
            host=DB_CONFIG['host'],
            port=DB_CONFIG['port'],
            user=DB_CONFIG['user'],
            password=DB_CONFIG['password'],
            database=DB_CONFIG['database']
        )
        cursor = conn.cursor()
        print("✓ Connected successfully\n")
        
        # Analyze each query
        print_header("Query Execution Plans")
        for i, query_info in enumerate(QUERIES_TO_ANALYZE, 1):
            print(f"\n[{i}/{len(QUERIES_TO_ANALYZE)}]")
            analyze_query(cursor, query_info)
        
        # Show index usage
        print("\n")
        get_index_usage_stats(cursor)
        
        # Show table sizes
        print("\n")
        get_table_sizes(cursor)
        
        # Optional: Run benchmarks
        print("\n")
        response = input("\nRun query benchmarks? (y/N): ").strip().lower()
        if response == 'y':
            print_header("Query Benchmarks")
            for i, query_info in enumerate(QUERIES_TO_ANALYZE, 1):
                print(f"\n[{i}/{len(QUERIES_TO_ANALYZE)}]")
                run_simple_benchmark(cursor, query_info, iterations=5)
        
        # Cleanup
        cursor.close()
        conn.close()
        
        print_header("Analysis Complete")
        print("\nRecommendations:")
        print("1. Review slow queries (high execution time)")
        print("2. Check for sequential scans on large tables")
        print("3. Verify indexes are being used (check index usage stats)")
        print("4. Consider adding indexes for frequently filtered columns")
        print("5. Use VACUUM ANALYZE to update statistics")
        print("\n" + "=" * 80 + "\n")
        
    except psycopg2.Error as e:
        print(f"\nERROR: Database connection failed")
        print(f"  {e}")
        print("\nPlease check:")
        print("1. PostgreSQL is running")
        print("2. Database credentials are correct")
        print("3. Database 'game_store' exists")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n\nAnalysis cancelled.")
        sys.exit(0)

if __name__ == "__main__":
    main()
