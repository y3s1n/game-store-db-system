# Data Directory

This directory contains CSV files for bulk data loading into the Game Store database.

## Available CSV Files

- `games.csv` - Sample game catalog data
- `customers.csv` - Sample customer records
- `orders.csv` - Sample order transactions

## Usage

These CSV files can be used for:

1. **Testing data import functionality**
2. **Populating additional test data**
3. **Demonstrating bulk load operations**

## Loading CSV Data

### Using PostgreSQL COPY Command

```sql
-- Connect to database
psql -U postgres -d game_store

-- Load games (after adjusting columns to match your schema)
\COPY games(sku, title, platform_id, publisher_id, release_date, esrb_rating, base_price, is_digital_only) 
FROM 'data/games.csv' 
WITH (FORMAT csv, HEADER true);

-- Load customers
\COPY customers(email, first_name, last_name, phone, date_of_birth, city, state, zip_code, loyalty_points, join_date) 
FROM 'data/customers.csv' 
WITH (FORMAT csv, HEADER true);
```

### Using Python Script

```python
import csv
import psycopg2

conn = psycopg2.connect(
    host='localhost',
    database='game_store',
    user='postgres',
    password='your_password'
)

with open('data/games.csv', 'r') as f:
    reader = csv.DictReader(f)
    cursor = conn.cursor()
    
    for row in reader:
        cursor.execute("""
            INSERT INTO games (sku, title, ...)
            VALUES (%s, %s, ...)
        """, (row['sku'], row['title'], ...))
    
    conn.commit()
```

## Note

The sample data in `02_seed.sql` is more comprehensive and includes relational consistency. These CSV files are provided as additional examples for bulk loading scenarios.

## Custom Data Generation

To generate larger datasets, consider using:
- **Faker** (Python library): `pip install faker`
- **Mockaroo**: https://www.mockaroo.com/
- **PostgreSQL random functions**: `generate_series()`, `random()`, etc.

Example:
```python
from faker import Faker
import csv

fake = Faker()

with open('customers_large.csv', 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['email', 'first_name', 'last_name', 'phone', 'date_of_birth'])
    
    for _ in range(1000):
        writer.writerow([
            fake.email(),
            fake.first_name(),
            fake.last_name(),
            fake.phone_number(),
            fake.date_of_birth()
        ])
```
