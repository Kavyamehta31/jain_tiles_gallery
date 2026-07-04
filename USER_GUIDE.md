# User Guide - Jain Tiles Gallery (Order Management)

Welcome to the **Jain Tiles Gallery** application! This manual provides step-by-step instructions to help showroom staff manage tile products, record sales, review invoices, check reports, and perform database maintenance.

---

## 1. Cataloguing Products
Go to the **Products** tab to manage your showroom tile collection.
1. Tap **+ Add Product**.
2. Fill in the details: Name, Brand, Size, Variety, Opening Stock (boxes), Pieces per Box.
3. **Selling Price per Box**: Enter the default price (in ₹) that will prefill on orders.
4. **Photos**: Select one or multiple tile photos from your gallery.
5. Tap **Save Product**.

---

## 2. Showroom Billing (New Order)
The **Entry** tab has been redesigned into a commercial billing station.

### Creating a New Order
1. Go to the **Entry** tab and tap **+ Add Entry**.
2. **Order Number & Date**: The app automatically generates date-sequenced order numbers (e.g., `ORD-20260704-0001`) and stamps timestamps.
3. **Remarks**: Enter billing details (e.g., "Customer: Rohan Gupta, Phone: 9821034291, Invoice #482").
4. **Select Tile**: Tap the dropdown inside the first item row. The card will instantly display the current stock level.
5. **Set Price**: The default price per box is prefilled. You can edit this price for specific discount sales (only affects this order).
6. **Set Quantity**: Enter the boxes sold. The app checks stock and will **reject** values exceeding stock.
7. **Line Total**: Line totals are calculated automatically.
8. **Add Rows**: Tap **Add Another Product** to add different tiles to the same order.
9. **Remove Rows**: Tap the trash icon on any row to delete it.
10. **Save Order**: Review the Total Boxes and Grand Total at the bottom, tap **Save Showroom Order**, and tap **Confirm**.

---

## 3. Order History & Cancellations
All billed orders are logged in the **Entry** feed.

### Viewing Order Details
- Tap any order card to open the itemized invoice.
- The invoice displays each product, brand, size, quantity sold, price, line total, and the remaining stock immediately following the sale.

### Cancelling an Order
- Completed orders are locked and cannot be edited.
- If a customer returns stock or order details were entered incorrectly, tap **Cancel Showroom Order** in the invoice sheet.
- **Stock Restoration**: Cancelling an order will mark it as `CANCELLED` and automatically restore the box quantities of all items back to active stock.

---

## 4. Reports & Performance Analytics
The **Reports** tab ignores cancelled orders and monitors showroom progress.
- **Period Filter**: Select Daily, Weekly, Monthly, or Custom ranges.
- **Sales Metrics**: Review total orders, revenue, average order value, highest/lowest invoices, and total boxes sold.
- **Sales Analytics**: Brand-wise, Size-wise, and Variety-wise tables detailing unit volumes and revenue totals.
- **Best Sellers**: List of products sorted by sales volume.
- **Inventory Status**: Lists Current, Low Stock, and Out of Stock products.

---

## 5. Maintenance & Settings
Tap **Settings** on the dashboard to access system operations.
- **Branding**: Customize your showroom name and select a shop logo.
- **Backup Now**: Creates a timestamped directory containing database and images.
- **Restore**: Recovery utility allowing database restores from older files.
- **Metrics**: Displays active database file size, image directory size, total orders count, and total product counts.
