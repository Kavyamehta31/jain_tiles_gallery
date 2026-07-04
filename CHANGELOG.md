# Changelog - Jain Tiles Gallery

All notable changes to the **Jain Tiles Gallery** project are documented here.

---

## [0.5.0] - 2026-07-04
### Added
- **Order Management System (OMS) Redesign**:
  - Unified multi-item order checkout screen (`NewOrderScreen`) replacing single-item transactions.
  - Sequential order numbers (`ORD-YYYYMMDD-XXXX`) resetting daily.
  - Editable default product selling prices prefilled on item rows.
  - Audit trail snapshots storing tile name, brand, size, and variety specs in `order_items` to protect against future catalog updates.
  - Safe transaction order cancellation restoring stock levels and tagging orders as `CANCELLED`.
- **Database Schema Upgrade (v5)**:
  - Added `selling_price_per_box` to the `products` table.
  - Dropped `transactions` table, created `orders` and `order_items` tables with cascade configuration.
- **Reporting & Dashboard Rebuild**:
  - Reports calculate completed order statistics, ignoring cancelled transactions.
  - Dashboard analytics cards display today's revenue, completed orders count, monthly revenue figures, and average order prices.
  - Detailed invoice sheets show product summaries and post-transaction stock indexes (`boxes_after_transaction`).
- **Obsolete Cleanup**:
  - Deleted obsolete transaction models, services, and UI files.

### Fixed
- Fixed deprecation linter warnings in Dropdown Form Fields.
- Resolved unused imports and missing type parameters.
- Static analyzer clean with 0 issues.

---

## [0.4.0] - 2026-07-04
### Added
- **Showroom Configuration**:
  - Dynamically editable Shop Name displayed in AppBar.
  - Custom Shop Logo from gallery (stored locally in private storage).
  - Configurable Low Stock Threshold (in boxes) adjusting alerts globally.
- **Database Backup & Recovery**:
  - Timestamped backup generator saving `database.db`, `product_images/`, and metadata `settings.json`.
  - Recovery utility restoring products, transactions, settings, and image files cleanly from disk.
  - confirmation prompts for deletion and restoration.
- **Dashboard Enhancements (Production Polish)**:
  - Quick Actions Bar (New Tile, Stock Entry, Backups).
  - Dynamic Low Stock horizontal cards alert panel.
  - Recent Activities feed displaying last 3 logs with status badges.
- **Maintenance Metrics**:
  - Tally checks for database size, image directory size, product/transaction tallies, and last backup logs.

---

## [0.3.0] - 2026-07-04
### Added
- **Reports Module**:
  - Segmented period chips (Daily, Weekly, Monthly, Custom) controlling reporting scopes.
  - Performance dashboard cards (Total Products, Stock, Period In/Out, Net Movement, Warnings).
  - Brand-wise, Size-wise, and Variety-wise analytics tables.
  - Product-wise summary ledger with search filtering.
  - Inventory lists dividing stock into Current, Low Stock, and Out of Stock.
  - Share options bottom sheet for PDF/Excel.

---

## [0.2.0] - 2026-07-04
### Added
- **Transactions Module**:
  - Stock In / Stock Out log sheet with atomic SQLite updates.
  - Depletion safeguard aborting Out transactions exceeding stock count.
  - Search history logs filtering by name, brand, remarks.
  - Category, type, and Date Range filter panels.

---

## [0.1.0] - 2026-07-04
### Added
- **Products Module**:
  - SQLite database version 1 structure.
  - Multiple image uploads and local private storage copying.
  - Detail view panel, search bars, cascading product deletions, forms and size variety bindings.
