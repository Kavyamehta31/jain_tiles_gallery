import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/report_summary.dart';

class ReportService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Generates order-based report summary data within a given date range
  Future<OrderReportSummary> getReportSummary(
    DateTime startDate,
    DateTime endDate, {
    int lowStockLimit = 5,
  }) async {
    try {
      final Database db = await _databaseHelper.database;

      final startIso = startDate.toIso8601String();
      // Set to the end of the day to capture all orders within the end date
      final endOfDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
      final endIso = endOfDay.toIso8601String();

      // 1. Total Products (Global)
      final productCountMaps = await db.rawQuery('SELECT COUNT(*) as count FROM products');
      final totalProducts = Sqflite.firstIntValue(productCountMaps) ?? 0;

      // 2. Total Boxes in Stock (Global)
      final stockSumMaps = await db.rawQuery('SELECT SUM(boxes_in_stock) as sum FROM products');
      final totalBoxesInStock = (stockSumMaps.first['sum'] as num?)?.toInt() ?? 0;

      // 3. Low Stock count (Global)
      final lowStockMaps = await db.rawQuery(
        'SELECT COUNT(*) as count FROM products WHERE boxes_in_stock <= ?',
        [lowStockLimit],
      );
      final lowStockCount = Sqflite.firstIntValue(lowStockMaps) ?? 0;

      // 4. Period: Completed Orders Count
      final completedOrdersMaps = await db.rawQuery(
        "SELECT COUNT(*) as count FROM orders WHERE status = 'COMPLETED' AND datetime(order_date) >= datetime(?) AND datetime(order_date) <= datetime(?)",
        [startIso, endIso],
      );
      final totalOrders = Sqflite.firstIntValue(completedOrdersMaps) ?? 0;

      // 5. Period: Total Revenue
      final revenueMaps = await db.rawQuery(
        "SELECT SUM(total_amount) as sum FROM orders WHERE status = 'COMPLETED' AND datetime(order_date) >= datetime(?) AND datetime(order_date) <= datetime(?)",
        [startIso, endIso],
      );
      final totalRevenue = (revenueMaps.first['sum'] as num?)?.toDouble() ?? 0.0;

      // 6. Period: Total Boxes Sold
      final boxesSoldMaps = await db.rawQuery(
        "SELECT SUM(total_boxes) as sum FROM orders WHERE status = 'COMPLETED' AND datetime(order_date) >= datetime(?) AND datetime(order_date) <= datetime(?)",
        [startIso, endIso],
      );
      final totalBoxesSold = (boxesSoldMaps.first['sum'] as num?)?.toInt() ?? 0;

      // 7. Period: Highest Order Amount
      final highestOrderMaps = await db.rawQuery(
        "SELECT MAX(total_amount) as max_val FROM orders WHERE status = 'COMPLETED' AND datetime(order_date) >= datetime(?) AND datetime(order_date) <= datetime(?)",
        [startIso, endIso],
      );
      final highestOrder = (highestOrderMaps.first['max_val'] as num?)?.toDouble() ?? 0.0;

      // 8. Period: Lowest Order Amount
      final lowestOrderMaps = await db.rawQuery(
        "SELECT MIN(total_amount) as min_val FROM orders WHERE status = 'COMPLETED' AND datetime(order_date) >= datetime(?) AND datetime(order_date) <= datetime(?)",
        [startIso, endIso],
      );
      final lowestOrder = (lowestOrderMaps.first['min_val'] as num?)?.toDouble() ?? 0.0;

      // 9. Period: Cancelled Orders Count
      final cancelledOrdersMaps = await db.rawQuery(
        "SELECT COUNT(*) as count FROM orders WHERE status = 'CANCELLED' AND datetime(order_date) >= datetime(?) AND datetime(order_date) <= datetime(?)",
        [startIso, endIso],
      );
      final cancelledOrdersCount = Sqflite.firstIntValue(cancelledOrdersMaps) ?? 0;

      final averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

      // 10. Period: Product-wise sales summary (Best Sellers)
      final String productSalesQuery = '''
        SELECT oi.product_id, oi.product_name, oi.product_brand,
               SUM(oi.quantity) AS boxes_sold,
               SUM(oi.total_amount) AS revenue
        FROM order_items oi
        INNER JOIN orders o ON oi.order_id = o.id
        WHERE o.status = 'COMPLETED' AND datetime(o.order_date) >= datetime(?) AND datetime(o.order_date) <= datetime(?)
        GROUP BY oi.product_id, oi.product_name, oi.product_brand
        ORDER BY boxes_sold DESC
      ''';
      final List<Map<String, dynamic>> prodSalesMaps =
          await db.rawQuery(productSalesQuery, [startIso, endIso]);
      final List<ProductSalesSummary> productSales = prodSalesMaps
          .map((m) => ProductSalesSummary(
                productId: m['product_id'] as int,
                name: m['product_name'] as String,
                brand: m['product_brand'] as String,
                boxesSold: m['boxes_sold'] as int,
                revenue: (m['revenue'] as num).toDouble(),
              ))
          .toList();

      // 11. Period: Brand-wise sales summary
      final String brandSalesQuery = '''
        SELECT oi.product_brand AS brand,
               COUNT(DISTINCT oi.product_id) AS product_count,
               SUM(oi.quantity) AS boxes_sold,
               SUM(oi.total_amount) AS revenue
        FROM order_items oi
        INNER JOIN orders o ON oi.order_id = o.id
        WHERE o.status = 'COMPLETED' AND datetime(o.order_date) >= datetime(?) AND datetime(o.order_date) <= datetime(?)
        GROUP BY oi.product_brand
        ORDER BY boxes_sold DESC
      ''';
      final List<Map<String, dynamic>> brandSalesMaps =
          await db.rawQuery(brandSalesQuery, [startIso, endIso]);
      final List<BrandSalesSummary> brandSales = brandSalesMaps
          .map((m) => BrandSalesSummary(
                brand: m['brand'] as String,
                productCount: m['product_count'] as int,
                boxesSold: m['boxes_sold'] as int,
                revenue: (m['revenue'] as num).toDouble(),
              ))
          .toList();

      // 12. Period: Size-wise sales summary
      final String sizeSalesQuery = '''
        SELECT oi.product_size AS size,
               COUNT(DISTINCT oi.product_id) AS product_count,
               SUM(oi.quantity) AS boxes_sold,
               SUM(oi.total_amount) AS revenue
        FROM order_items oi
        INNER JOIN orders o ON oi.order_id = o.id
        WHERE o.status = 'COMPLETED' AND datetime(o.order_date) >= datetime(?) AND datetime(o.order_date) <= datetime(?)
        GROUP BY oi.product_size
        ORDER BY boxes_sold DESC
      ''';
      final List<Map<String, dynamic>> sizeSalesMaps =
          await db.rawQuery(sizeSalesQuery, [startIso, endIso]);
      final List<SizeSalesSummary> sizeSales = sizeSalesMaps
          .map((m) => SizeSalesSummary(
                size: m['size'] as String,
                productCount: m['product_count'] as int,
                boxesSold: m['boxes_sold'] as int,
                revenue: (m['revenue'] as num).toDouble(),
              ))
          .toList();

      // 13. Period: Variety-wise sales summary
      final String varietySalesQuery = '''
        SELECT oi.product_variety AS variety,
               COUNT(DISTINCT oi.product_id) AS product_count,
               SUM(oi.quantity) AS boxes_sold,
               SUM(oi.total_amount) AS revenue
        FROM order_items oi
        INNER JOIN orders o ON oi.order_id = o.id
        WHERE o.status = 'COMPLETED' AND datetime(o.order_date) >= datetime(?) AND datetime(o.order_date) <= datetime(?)
        GROUP BY oi.product_variety
        ORDER BY boxes_sold DESC
      ''';
      final List<Map<String, dynamic>> varietySalesMaps =
          await db.rawQuery(varietySalesQuery, [startIso, endIso]);
      final List<VarietySalesSummary> varietySales = varietySalesMaps
          .map((m) => VarietySalesSummary(
                variety: m['variety'] as String,
                productCount: m['product_count'] as int,
                boxesSold: m['boxes_sold'] as int,
                revenue: (m['revenue'] as num).toDouble(),
              ))
          .toList();

      // 14. Global: Load products list for stock reports
      final List<Map<String, dynamic>> productsMaps = await db.query(
        'products',
        orderBy: 'name ASC',
      );

      final List<Map<String, dynamic>> imageMaps = await db.query('product_images');
      final Map<int, List<String>> imagePathsByProductId = {};
      for (final imageRow in imageMaps) {
        final pid = imageRow['product_id'] as int;
        final path = imageRow['image_path'] as String;
        imagePathsByProductId.putIfAbsent(pid, () => []).add(path);
      }

      final List<Product> currentStockList = [];
      final List<Product> lowStockList = [];
      final List<Product> outOfStockList = [];

      for (final row in productsMaps) {
        final pid = row['id'] as int;
        final product = Product.fromMap(
          row,
          imagePaths: imagePathsByProductId[pid] ?? const [],
        );

        currentStockList.add(product);

        if (product.boxesInStock == 0) {
          outOfStockList.add(product);
        }
        if (product.boxesInStock <= lowStockLimit) {
          lowStockList.add(product);
        }
      }

      return OrderReportSummary(
        startDate: startDate,
        endDate: endDate,
        totalProducts: totalProducts,
        totalBoxesInStock: totalBoxesInStock,
        lowStockCount: lowStockCount,
        totalOrders: totalOrders,
        totalRevenue: totalRevenue,
        totalBoxesSold: totalBoxesSold,
        averageOrderValue: averageOrderValue,
        highestOrder: highestOrder,
        lowestOrder: lowestOrder,
        cancelledOrdersCount: cancelledOrdersCount,
        productSales: productSales,
        brandSales: brandSales,
        sizeSales: sizeSales,
        varietySales: varietySales,
        currentStockList: currentStockList,
        lowStockList: lowStockList,
        outOfStockList: outOfStockList,
      );
    } catch (e) {
      debugPrint("Error generating order report summary: $e");
      rethrow;
    }
  }
}
