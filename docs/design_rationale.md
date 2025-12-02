# Game Store Database System - Design Rationale

## 1. Introduction

### 1.1 Project Overview
This document describes the design rationale for a relational database system that supports a small retail chain selling video games, consoles, and accessories. The system manages all aspects of retail operations including customer relationships, product catalogs, inventory tracking, order processing, and vendor management.

### 1.2 Purpose and Scope
The database is designed to:
- Track products (games, consoles, accessories) across multiple stores
- Manage customer accounts, orders, and loyalty programs
- Handle pre-orders for upcoming game releases
- Support inventory management and vendor relationships
- Enable reporting on sales, stock levels, and promotional performance

---

## 2. Requirements Analysis

### 2.1 Business Domain
The system supports a game retail chain operating through:
- Physical store locations
- Online sales channel
- Mixed fulfillment (in-store pickup, shipping)

### 2.2 Key Actors and Their Needs

**Customers**
- Browse catalog by platform, genre, ESRB rating
- Place orders online or in-store
- Manage pre-orders for upcoming releases
- Earn and redeem loyalty points
- Process returns/exchanges

**Store Employees**
- Create and update orders
- Process payments and returns
- Manage inventory counts
- Handle pre-order fulfillment
- Check stock availability

**Store Managers**
- Configure promotions and discounts
- Review sales and inventory reports
- Approve returns and exchanges
- Monitor stock levels per store
- Track employee performance

**Vendors/Publishers**
- Supply products to stores
- Respond to purchase orders
- Manage special pricing agreements
- Track shipment status

### 2.3 Core Business Events
1. Customer browses catalog and adds items to cart
2. Order is placed (online or in-store)
3. Payment is processed
4. Inventory is decremented
5. Pre-orders are recorded for future releases
6. Vendor shipments arrive and update inventory
7. Returns/exchanges are processed
8. Loyalty points are earned and redeemed
9. Reports are generated for management

### 2.4 Critical Business Rules
[TO BE COMPLETED: List specific constraints such as age verification for M-rated games, inventory cannot go negative, pre-order requirements, loyalty point calculations, return policies, etc.]

---

## 3. Conceptual Model (Entity-Relationship Design)

### 3.1 Core Entities

**Product Entities**
- **Game**: Video game titles with platform, genre, rating, publisher
- **Console**: Gaming hardware (PlayStation, Xbox, Nintendo, PC)
- **Accessory**: Controllers, headsets, cables, etc.

**Customer & Sales Entities**
- **Customer**: Account information, demographics, loyalty status
- **Order**: Transaction record with date, status, total
- **OrderItem**: Line items within an order
- **PreOrder**: Future releases with deposit tracking

**Inventory & Location Entities**
- **Store**: Physical locations with address and contact info
- **Inventory**: Stock levels per store per product
- **Vendor**: Suppliers and publishers
- **PurchaseOrder**: Restocking orders to vendors

**Employee & System Entities**
- **Employee**: Staff with roles and store assignments
- **LoyaltyProgram**: Point accumulation and redemption rules
- **Promotion**: Discounts and special offers

### 3.2 Relationships
[TO BE COMPLETED: Describe cardinalities - one-to-many between Order and OrderItem, many-to-many between Game and Genre through a junction table, etc.]

### 3.3 Entity-Relationship Diagram
See `erd.png` in this directory for the complete ERD.

---

## 4. Logical Model (Relational Schema Design)

### 4.1 Normalization Strategy
[TO BE COMPLETED: Explain your normalization decisions]
- **1NF**: Atomic values, no repeating groups
- **2NF**: Remove partial dependencies
- **3NF**: Remove transitive dependencies
- **Design trade-offs**: Where and why you denormalized (if applicable)

### 4.2 Table Design

#### Core Tables
[TO BE COMPLETED: For each major table, describe:]
- **Table name and purpose**
- **Primary key choice** (natural vs surrogate)
- **Foreign key relationships**
- **Important constraints** (NOT NULL, UNIQUE, CHECK)
- **Rationale for design decisions**

Example structure:
```
Table: games
- game_id (PK, SERIAL): Surrogate key for internal reference
- sku (UNIQUE): Business key for external identification
- title, platform_id (FK), genre_id (FK), publisher_id (FK)
- release_date, esrb_rating, price
- Constraints: CHECK (price >= 0), CHECK (esrb_rating IN ('E','E10+','T','M','AO'))
```

### 4.3 Data Types and Constraints
[TO BE COMPLETED: Justify specific type choices]
- Why use `DECIMAL(10,2)` for prices?
- Why use `DATE` vs `TIMESTAMP` for certain fields?
- Why use `ENUM` or `CHECK` constraints for categorical data?

### 4.4 Referential Integrity
[TO BE COMPLETED: Describe foreign key relationships and ON DELETE/ON UPDATE actions]
- CASCADE vs RESTRICT decisions
- Handling orphaned records

---

## 5. Physical Design Decisions

### 5.1 Indexing Strategy
[TO BE COMPLETED: For each index in `06_indexes.sql`, explain:]
- **What queries it optimizes**
- **Why this index helps**
- **Trade-offs** (query speedup vs insert/update cost)

Example:
```
Index: idx_games_platform_genre
- Columns: platform_id, genre_id
- Purpose: Optimizes catalog browsing by platform and genre
- Query pattern: "Show me all Action games for PlayStation 5"
- Trade-off: Slight overhead on game inserts, significant speedup on frequent browse queries
```

### 5.2 Views Design
[TO BE COMPLETED: For each view in `03_views.sql`, explain:]
- **Purpose and intended users**
- **What complexity it abstracts**
- **Performance considerations**

### 5.3 Stored Functions and Procedures
[TO BE COMPLETED: For each function in `04_functions.sql`, explain:]
- **Business logic encapsulated**
- **Why it's in the database vs application layer**
- **Parameters and return types**

### 5.4 Triggers
[TO BE COMPLETED: For each trigger in `05_triggers.sql`, explain:]
- **Business rule being enforced**
- **BEFORE vs AFTER decision**
- **Row-level vs statement-level**
- **Potential side effects**

Example:
```
Trigger: check_inventory_before_order
- Event: BEFORE INSERT ON order_items
- Purpose: Ensure sufficient stock before allowing order
- Logic: Query inventory table, raise exception if quantity insufficient
- Rationale: Prevents overselling, maintains data consistency
```

---

## 6. Query Workload Design

### 6.1 Representative Queries
[TO BE COMPLETED: For queries in `07_queries.sql`, categorize and explain:]

**Catalog Queries**
- Browse by platform/genre
- Search by title
- Filter by rating/price range

**Sales Queries**
- Order history per customer
- Best-selling games
- Revenue by store/time period

**Inventory Queries**
- Stock levels per store
- Low-stock alerts
- Reorder recommendations

**Analytical Queries**
- Customer lifetime value
- Promotion effectiveness
- Employee performance metrics

### 6.2 Query Optimization
[TO BE COMPLETED: Show EXPLAIN ANALYZE output and optimizations made]

---

## 7. Transaction Design

### 7.1 ACID Properties
[TO BE COMPLETED: Describe how your design ensures:]
- **Atomicity**: Example transaction that must fully complete or fully roll back
- **Consistency**: Constraints that maintain database validity
- **Isolation**: Demonstrate isolation level behavior (see `08_transactions.sql`)
- **Durability**: How committed transactions persist

### 7.2 Concurrency Scenarios
[TO BE COMPLETED: Address scenarios like:]
- Two customers ordering the last copy of a game simultaneously
- Employee updating inventory while customer is placing order
- Manager running report while sales are being recorded

### 7.3 Isolation Levels
[TO BE COMPLETED: Justify isolation level choices for different transaction types]

---

## 8. Alternative Designs Considered

### 8.1 Design Option 1: [Describe alternative]
[TO BE COMPLETED: Describe an alternative design approach you considered]
- **Approach**: ...
- **Advantages**: ...
- **Disadvantages**: ...
- **Why rejected**: ...

### 8.2 Design Option 2: [Describe alternative]
[TO BE COMPLETED]

---

## 9. Future Enhancements

[TO BE COMPLETED: Describe potential extensions:]
- Support for digital game delivery and license keys
- Integration with third-party game recommendation engines
- Advanced analytics and machine learning for demand forecasting
- Multi-currency support for international sales
- Mobile app integration
- Subscription services (e.g., Game Pass style)

---

## 10. Conclusion

[TO BE COMPLETED: Summarize:]
- How the design meets the business requirements
- Key design principles followed (normalization, integrity, performance)
- Trade-offs made and their justifications
- Overall strengths of the solution

---

## Appendix A: Data Dictionary

[TO BE COMPLETED: Complete reference of all tables, columns, types, constraints]

## Appendix B: Sample Data Specifications

[TO BE COMPLETED: Describe the sample data in `02_seed.sql`]
- Number of records per table
- Data generation methodology
- Coverage of edge cases

## Appendix C: References

- PostgreSQL 14 Documentation
- Date, C.J. "An Introduction to Database Systems"
- Elmasri & Navathe "Fundamentals of Database Systems"
- Course lecture notes and materials
