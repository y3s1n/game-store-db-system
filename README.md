# Game Store Database System

A relational database for a small game retail chain that manages customers, products, inventory, orders, pre-orders, loyalty rewards, and vendor relationships.

## Project Overview

This system supports a small retail chain that sells video games (physical and digital), consoles, and accessories through both in-store and online channels. The database is designed to handle all aspects of retail operations including customer management, product catalog, inventory tracking, order processing, and vendor relationships.

The database tracks customers, products (games, consoles, accessories), inventory per store, orders and payments, employee roles, and vendors/publishers with their purchase orders. It also supports pre-orders for upcoming titles, loyalty rewards programs, and basic reporting on sales and stock levels across all store locations.

### Actors

- **Customers** – Browse catalog, place orders (online/in-store), manage pre-orders, earn/redeem loyalty points
- **Store Employees** – Create/update orders, process returns, manage inventory counts, handle pre-orders
- **Store Managers** – Configure promotions, review sales reports, approve returns/exchanges, monitor stock per store
- **Vendors/Publishers** – Supply products, respond to purchase orders, may have special pricing or promotions

### Core Activities / Events

- Browsing catalog by platform/genre/rating
- Purchasing games/consoles/accessories
- Recording orders and payments
- Decrementing inventory; handling backorders and pre-orders
- Recording vendor shipments and stock updates
- Running manager reports (best-sellers, low stock, promotion performance)
- Processing returns and exchanges

## Key Business Rules

### Games
- Each game has:
  - A unique SKU
  - Platform
  - ESRB rating
  - Genre
  - Publisher
- Some titles are digital-only (no physical stock)

### Inventory
- Inventory is tracked per store and per product
- Quantity cannot go below zero unless explicitly flagged as a backorder

### Pre-orders
- Only allowed for games with a future release date
- Must be associated to a specific customer
- Must be fully or partially prepaid

### Age-Restricted Games
- Age-restricted games (e.g., Mature) require:
  - Customer meets the minimum age
  - Age verification recorded

### Loyalty Points
- Earned as a function of total order value
- Can be redeemed on future purchases
- Balance cannot go negative

### Returns
- Must reference a valid past order
- Must obey a time window (e.g., 30 days)
- May enforce condition rules (e.g., unopened for full refund)

