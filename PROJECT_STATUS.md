# PROJECT_STATUS.md

# Jain Tiles Gallery

## Project Overview

Jain Tiles Gallery is a production-quality offline Android application built using Flutter.

Purpose:

Manage tile inventory, orders, revenue, reporting, and showroom settings completely offline using SQLite.

The application is intended for daily production use inside a tile showroom.

---

# Technology Stack

Flutter

Material 3

SQLite (sqflite)

image_picker

path_provider

uuid

intl

Target Platform:

Android

Architecture:

Layered Architecture

Models

Services

Database

Widgets

Screens

Constants

---

# Current Version

Version:

0.5.1

Database Version:

5

Branch:

version-2

Repository:

jain_tiles_gallery

---

# Current Progress

## Module 1

### Products

Status:

✅ COMPLETED

Completed Features

- Product CRUD
- SQLite Integration
- Multiple Product Images
- Local Image Storage
- Image Copy to App Storage
- Product Search
- Edit Product
- Delete Product
- Dynamic Variety Dropdown
- Material 3 UI
- Form Validation
- Product Cards
- Product Image Table
- Transaction-safe Database Operations
- Foreign Key Support
- Image Cleanup
- Price specification (selling_price_per_box) added to database and forms
- Flutter Analyze Passed

---

## Module 2

### Orders (Order Management System)

Status:

✅ COMPLETED

Completed Features

- Multi-product order creation in a single SQLite transaction
- Sequential readable order number generation (ORD-YYYYMMDD-XXXX) resetting daily
- Real-time stock depletion warning in order row dropdown
- Quantity & Price validations (quantity > 0, price > 0, >= 1 item, stock safeguard)
- Historical audit trail: stores post-transaction stock values (boxes_after_transaction) and product snapshots (name, brand, size, variety) directly in order_items
- Order cancellation workflow reverting stock levels atomically
- Search orders (filters by order number, remarks, product name, brand)
- Detailed invoice style modal view
- Exclude cancelled orders from dashboard metrics and analytics reports
- **Undo Last Order**: Allows showroom staff to undo the absolute latest completed order in case of billing mistakes. Restores product inventory levels and transitions the order status to `CANCELLED` transactionally.

---

## Module 3

### Reports

Status:

✅ COMPLETED

Completed Features

- Daily Report (Today)
- Weekly Report (Last 7 Days)
- Monthly Report (Last 30 Days)
- Custom Date Range (via date range picker)
- Dashboard Cards (Total Orders, Total Revenue, Boxes Sold, Avg Order Value, Max Invoice, Min Invoice, Cancelled Count, Low Stock Warning)
- Brand-wise Sales Table (Products, stock levels, Period In/Out, Net)
- Size-wise Sales Table (Products, stock levels, Period In/Out, Net)
- Variety-wise Sales Table (Products, stock levels, Period In/Out, Net)
- Product-wise Movement List (with real-time query search)
- Inventory status list (Current Stock report, Low Stock warnings, Out of Stock alerts)
- PDF & Excel export design hooks (bottom sheet choices)
- Highly optimized SQLite JOIN queries
- Clean, responsive TabBar visual layout with M3 bronze styling

---

## Module 4

### Settings

Status:

✅ COMPLETED

Completed Features

- Backup Database (database.db, product_images/, settings.json)
- Restore Database (verifies backups, safe DB termination)
- Low Stock Limit Configuration
- Change Shop Name
- Change Logo from Gallery

---

# Database Structure

## Products

- id
- name
- brand
- size
- variety
- boxes_in_stock
- pieces_per_box
- selling_price_per_box
- description

---

## Product Images

- id
- product_id
- image_path

One Product

↓

Many Images

---

## Orders

- id
- order_number
- order_date
- total_amount
- total_boxes
- status -- 'COMPLETED', 'CANCELLED'
- remarks
- created_at

---

## Order Items

- id
- order_id
- product_id
- quantity
- price_per_box
- total_amount
- boxes_after_transaction
- product_name
- product_brand
- product_size
- product_variety

---

# UI Guidelines

Material 3

White Background

Bronze / Gold Accent

Rounded Cards

Rounded Buttons

Rounded TextFields

Professional Typography

Reusable Widgets

Minimal Design

No Placeholder Screens

---

# Reusable Widgets

Implemented

- CustomTextField
- CustomDropdown
- PrimaryButton
- SectionTitle
- ImagePickerCard
- ProductCard

---

# Completed Services

- ProductService
- OrderService
- ReportService
- SettingsService
- BackupService

---

# Completed Models

- Product
- Order
- OrderItem
- ReportSummary
- Settings

---

# Completed Database Work

- Products Table
- Product Images Table
- Orders Table
- Order Items Table
- Foreign Keys
- Cascade Delete
- SQLite Transactions (Order billing rollback safety)

---

# Git Workflow

Commit after every completed module.

Commit Format:

feat(products): complete offline products module

feat(transactions): implement stock movement

feat(reports): implement reporting module

feat(settings): implement settings module

feat(orders): transform transactions into order management system

feat(orders): implement undo last order feature

---

# Current Priority

Production Release

NEXT STEPS:
1. Verify APK Build
2. Final Testing
3. Production Release
