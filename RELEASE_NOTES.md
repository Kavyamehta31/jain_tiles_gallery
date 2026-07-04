# Release Notes - Jain Tiles Gallery v0.5.0

We are excited to announce the release of **Jain Tiles Gallery v0.5.0**, which elevates the application from a simple transaction log to a commercial-grade **Order Management System (OMS)**.

---

## What's New in v0.5.0

### 1. Multi-Item Order Billing
- **Unified Billing**: Create orders containing multiple different tile items, quantities, and pricing configurations inside one transaction.
- **Editable Default Prices**: Product selling prices are prefilled as defaults but remain fully editable during billing.
- **Save Safeguards**: Ensures all-or-nothing database writes. If any product in the order has insufficient stock, the entire order is rejected.

### 2. Immutable Order Ledger & Cancellations
- **Immutable Ledger**: Once saved, order details are locked for editing to preserve operational auditing records.
- **Restoration Cancellation**: Completed orders can be marked as `CANCELLED`, which automatically restores all product stock levels back to active inventory using safe database transactions.

### 3. Snapshot Auditing
- **Branding Preservation**: `order_items` stores name, brand, size, and variety snapshots directly at the time of order billing. This ensures historical records are retained even if products are edited or deleted later.
- **Stock Traceability**: Stores post-transaction stock values (`boxes_after_transaction`) as an audit trail.

### 4. Sequential Order Numbers
- Automatically generates sequential numbers (e.g. `ORD-20260704-0001`) that reset each day.

### 5. Rich Analytics
- Excludes cancelled orders from report figures.
- Rich metrics: Total revenue, boxes sold, cancelled order counters, average order value, highest/lowest invoices, and best-selling listings (products, brands, sizes, varieties).

---

## Technical Specifications

| Metric | Value / Standard |
| --- | --- |
| **SDK Platform** | Flutter (Material 3) |
| **Storage Engine** | SQLite (sqflite) |
| **Database Schema** | Version 5 (Products, Settings, Orders, Order Items) |
| **Build Artifact** | `build/app/outputs/flutter-apk/app-release.apk` (50.3MB) |
| **Offline Limit** | 100% Offline (No Internet, No Cloud Sync Required) |
| **Android target** | Android 6.0 (API 23) and above |
