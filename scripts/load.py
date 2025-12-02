#!/usr/bin/env python3
"""
Game Store Database Setup Script
Automatically creates database and runs all SQL scripts in order
"""

import os
import sys
import psycopg2
from psycopg2 import sql
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

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

# SQL scripts to run in order
SQL_SCRIPTS = [
    '01_schema.sql',
    '02_seed.sql',
    '03_views.sql',
    '04_functions.sql',
    '05_triggers.sql',
    '06_indexes.sql'
]

# ============================================
# Helper Functions
# ============================================

def print_header(message):
    """Print a formatted header message"""
    print("\n" + "=" * 60)
    print(message)
    print("=" * 60)

def print_step(step_num, message):
    """Print a step message"""
    print(f"\n[Step {step_num}] {message}")

def create_database():
    """Create the game_store database if it doesn't exist"""
    print_step(1, "Creating database...")
    
    try:
        # Connect to PostgreSQL server (not specific database)
        conn = psycopg2.connect(
            host=DB_CONFIG['host'],
            port=DB_CONFIG['port'],
            user=DB_CONFIG['user'],
            password=DB_CONFIG['password'],
            database='postgres'  # Connect to default database
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        # Check if database exists
        cursor.execute(
            "SELECT 1 FROM pg_database WHERE datname = %s",
            (DB_CONFIG['database'],)
        )
        
        if cursor.fetchone():
            print(f"   Database '{DB_CONFIG['database']}' already exists.")
            response = input("   Drop and recreate? (y/N): ").strip().lower()
            
            if response == 'y':
                # Terminate existing connections
                cursor.execute(f"""
                    SELECT pg_terminate_backend(pg_stat_activity.pid)
                    FROM pg_stat_activity
                    WHERE pg_stat_activity.datname = '{DB_CONFIG['database']}'
                        AND pid <> pg_backend_pid();
                """)
                
                # Drop database
                cursor.execute(sql.SQL("DROP DATABASE {}").format(
                    sql.Identifier(DB_CONFIG['database'])
                ))
                print(f"   Dropped existing database '{DB_CONFIG['database']}'")
                
                # Create database
                cursor.execute(sql.SQL("CREATE DATABASE {}").format(
                    sql.Identifier(DB_CONFIG['database'])
                ))
                print(f"   Created database '{DB_CONFIG['database']}'")
            else:
                print("   Using existing database.")
        else:
            # Create database
            cursor.execute(sql.SQL("CREATE DATABASE {}").format(
                sql.Identifier(DB_CONFIG['database'])
            ))
            print(f"   Created database '{DB_CONFIG['database']}'")
        
        cursor.close()
        conn.close()
        return True
        
    except psycopg2.Error as e:
        print(f"   ERROR: Failed to create database: {e}")
        return False

def run_sql_script(cursor, script_path, script_name):
    """Execute a SQL script file"""
    try:
        with open(script_path, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        cursor.execute(sql_content)
        print(f"   ✓ {script_name} executed successfully")
        return True
        
    except FileNotFoundError:
        print(f"   ✗ ERROR: File not found: {script_path}")
        return False
    except psycopg2.Error as e:
        print(f"   ✗ ERROR executing {script_name}:")
        print(f"      {e}")
        return False
    except Exception as e:
        print(f"   ✗ UNEXPECTED ERROR with {script_name}:")
        print(f"      {e}")
        return False

def run_sql_scripts():
    """Run all SQL scripts in order"""
    print_step(2, "Running SQL scripts...")
    
    # Get the sql directory path
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    sql_dir = os.path.join(project_root, 'sql')
    
    if not os.path.exists(sql_dir):
        print(f"   ERROR: SQL directory not found: {sql_dir}")
        return False
    
    try:
        # Connect to the game_store database
        conn = psycopg2.connect(
            host=DB_CONFIG['host'],
            port=DB_CONFIG['port'],
            user=DB_CONFIG['user'],
            password=DB_CONFIG['password'],
            database=DB_CONFIG['database']
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        # Run each script
        for script_name in SQL_SCRIPTS:
            script_path = os.path.join(sql_dir, script_name)
            print(f"\n   Running {script_name}...")
            
            if not run_sql_script(cursor, script_path, script_name):
                print("\n   Stopping due to error.")
                cursor.close()
                conn.close()
                return False
        
        cursor.close()
        conn.close()
        return True
        
    except psycopg2.Error as e:
        print(f"   ERROR: Database connection failed: {e}")
        return False

def verify_installation():
    """Verify that tables were created successfully"""
    print_step(3, "Verifying installation...")
    
    try:
        conn = psycopg2.connect(
            host=DB_CONFIG['host'],
            port=DB_CONFIG['port'],
            user=DB_CONFIG['user'],
            password=DB_CONFIG['password'],
            database=DB_CONFIG['database']
        )
        cursor = conn.cursor()
        
        # Count tables
        cursor.execute("""
            SELECT COUNT(*)
            FROM information_schema.tables
            WHERE table_schema = 'public'
                AND table_type = 'BASE TABLE';
        """)
        table_count = cursor.fetchone()[0]
        print(f"   Tables created: {table_count}")
        
        # Count views
        cursor.execute("""
            SELECT COUNT(*)
            FROM information_schema.views
            WHERE table_schema = 'public';
        """)
        view_count = cursor.fetchone()[0]
        print(f"   Views created: {view_count}")
        
        # Count functions
        cursor.execute("""
            SELECT COUNT(*)
            FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = 'public'
                AND p.prokind = 'f';
        """)
        function_count = cursor.fetchone()[0]
        print(f"   Functions created: {function_count}")
        
        # Count triggers
        cursor.execute("""
            SELECT COUNT(DISTINCT trigger_name)
            FROM information_schema.triggers
            WHERE trigger_schema = 'public';
        """)
        trigger_count = cursor.fetchone()[0]
        print(f"   Triggers created: {trigger_count}")
        
        # Sample data counts
        print("\n   Sample data loaded:")
        
        tables_to_check = [
            ('games', 'Games'),
            ('products', 'Products'),
            ('customers', 'Customers'),
            ('orders', 'Orders'),
            ('employees', 'Employees'),
            ('stores', 'Stores'),
            ('inventory', 'Inventory records')
        ]
        
        for table_name, display_name in tables_to_check:
            cursor.execute(f"SELECT COUNT(*) FROM {table_name};")
            count = cursor.fetchone()[0]
            print(f"   - {display_name}: {count}")
        
        cursor.close()
        conn.close()
        return True
        
    except psycopg2.Error as e:
        print(f"   ERROR: Verification failed: {e}")
        return False

def print_next_steps():
    """Print instructions for next steps"""
    print_header("Setup Complete!")
    print("\nYour database is ready to use!")
    print("\nNext steps:")
    print("\n1. Connect to the database:")
    print(f"   psql -U {DB_CONFIG['user']} -d {DB_CONFIG['database']}")
    
    print("\n2. Run sample queries:")
    print(f"   psql -U {DB_CONFIG['user']} -d {DB_CONFIG['database']} -f sql/07_queries.sql")
    
    print("\n3. Test transactions:")
    print(f"   psql -U {DB_CONFIG['user']} -d {DB_CONFIG['database']} -f sql/08_transactions.sql")
    
    print("\n4. Run performance analysis:")
    print("   python scripts/explain.py")
    
    print("\n5. Explore the data:")
    print("   SELECT * FROM v_game_catalog LIMIT 10;")
    print("   SELECT * FROM v_inventory_status;")
    print("   SELECT * FROM v_sales_by_store;")
    
    print("\nConnection details:")
    print(f"   Host: {DB_CONFIG['host']}")
    print(f"   Port: {DB_CONFIG['port']}")
    print(f"   Database: {DB_CONFIG['database']}")
    print(f"   User: {DB_CONFIG['user']}")
    print("\n" + "=" * 60 + "\n")

# ============================================
# Main Execution
# ============================================

def main():
    """Main execution function"""
    print_header("Game Store Database Setup")
    print("This script will:")
    print("1. Create the game_store database")
    print("2. Run all SQL scripts to set up schema, data, views, etc.")
    print("3. Verify the installation")
    print("\nPress Ctrl+C to cancel, or Enter to continue...")
    
    try:
        input()
    except KeyboardInterrupt:
        print("\n\nSetup cancelled.")
        sys.exit(0)
    
    # Step 1: Create database
    if not create_database():
        print("\nSetup failed at database creation step.")
        sys.exit(1)
    
    # Step 2: Run SQL scripts
    if not run_sql_scripts():
        print("\nSetup failed at script execution step.")
        sys.exit(1)
    
    # Step 3: Verify installation
    if not verify_installation():
        print("\nSetup completed but verification failed.")
        sys.exit(1)
    
    # Print next steps
    print_next_steps()
    sys.exit(0)

if __name__ == "__main__":
    main()
