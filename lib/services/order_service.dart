import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/order.dart';
import '../models/product.dart';

class OrderService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Helper to generate sequential readable numbers: ORD-YYYYMMDD-XXXX
  Future<String> _generateOrderNumber(Transaction txn, DateTime date) async {
    final datePrefix = DateFormat('yyyyMMdd').format(date);
    final matchPattern = 'ORD-$datePrefix-%';
    
    final countMaps = await txn.rawQuery(
      "SELECT COUNT(*) as count FROM orders WHERE order_number LIKE ?",
      [matchPattern],
    );
    final count = Sqflite.firstIntValue(countMaps) ?? 0;
    final sequence = (count + 1).toString().padLeft(4, '0');
    
    return 'ORD-$datePrefix-$sequence';
  }

  // Saves a multi-item order inside a single transaction, reducing stock of every item
  Future<void> saveOrder(Order order) async {
    try {
      final Database db = await _databaseHelper.database;

      await db.transaction((txn) async {
        final orderDate = order.orderDate;
        final orderNumber = await _generateOrderNumber(txn, orderDate);

        // 1. Insert order details
        final orderId = await txn.insert('orders', {
          'order_number': orderNumber,
          'order_date': orderDate.toIso8601String(),
          'total_amount': order.totalAmount,
          'total_boxes': order.totalBoxes,
          'status': 'COMPLETED',
          'remarks': order.remarks,
          'created_at': DateTime.now().toIso8601String(),
        });

        // 2. Process and save order items
        for (final item in order.items) {
          // Fetch product
          final List<Map<String, dynamic>> productMaps = await txn.query(
            'products',
            where: 'id = ?',
            whereArgs: [item.productId],
          );

          if (productMaps.isEmpty) {
            throw Exception("Product with ID ${item.productId} not found");
          }

          final product = Product.fromMap(productMaps.first);
          
          // Verify Stock
          if (product.boxesInStock < item.quantity) {
            throw Exception(
              "Insufficient stock for '${product.name}'! Available: ${product.boxesInStock} boxes, requested: ${item.quantity} boxes.",
            );
          }

          // Deduct Stock
          final newStock = product.boxesInStock - item.quantity;
          await txn.update(
            'products',
            {'boxes_in_stock': newStock},
            where: 'id = ?',
            whereArgs: [item.productId],
          );

          // Save Item with snapshots
          await txn.insert('order_items', {
            'order_id': orderId,
            'product_id': item.productId,
            'quantity': item.quantity,
            'price_per_box': item.pricePerBox,
            'total_amount': item.totalAmount,
            'boxes_after_transaction': newStock,
            'product_name': product.name,
            'product_brand': product.brand,
            'product_size': product.size,
            'product_variety': product.variety,
          });
        }
      });
    } catch (e) {
      debugPrint("Error in saveOrder transaction: $e");
      rethrow;
    }
  }

  // Cancels an order, setting status to CANCELLED and restoring stock levels
  Future<void> cancelOrder(int orderId) async {
    try {
      final Database db = await _databaseHelper.database;

      await db.transaction((txn) async {
        // 1. Fetch current order
        final List<Map<String, dynamic>> orderMaps = await txn.query(
          'orders',
          where: 'id = ?',
          whereArgs: [orderId],
        );

        if (orderMaps.isEmpty) {
          throw Exception("Order not found");
        }

        final status = orderMaps.first['status'] as String;
        if (status == 'CANCELLED') {
          throw Exception("Order is already cancelled");
        }

        // 2. Fetch order items
        final List<Map<String, dynamic>> itemMaps = await txn.query(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [orderId],
        );

        // 3. Revert stock
        for (final itemMap in itemMaps) {
          final productId = itemMap['product_id'] as int;
          final quantity = itemMap['quantity'] as int;

          // Check if product still exists
          final List<Map<String, dynamic>> productMaps = await txn.query(
            'products',
            where: 'id = ?',
            whereArgs: [productId],
          );

          if (productMaps.isNotEmpty) {
            final product = Product.fromMap(productMaps.first);
            final restoredStock = product.boxesInStock + quantity;
            
            await txn.update(
              'products',
              {'boxes_in_stock': restoredStock},
              where: 'id = ?',
              whereArgs: [productId],
            );
          }
        }

        // 4. Update order status
        await txn.update(
          'orders',
          {'status': 'CANCELLED'},
          where: 'id = ?',
          whereArgs: [orderId],
        );
      });
    } catch (e) {
      debugPrint("Error in cancelOrder transaction: $e");
      rethrow;
    }
  }

  // Get orders list with optional filters and join search
  Future<List<Order>> getOrders({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Database db = await _databaseHelper.database;

      String query = 'SELECT DISTINCT o.* FROM orders o';
      List<dynamic> args = [];
      List<String> conditions = [];

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query += ' LEFT JOIN order_items oi ON o.id = oi.order_id';
        conditions.add(
          '(o.order_number LIKE ? OR o.remarks LIKE ? OR oi.product_name LIKE ? OR oi.product_brand LIKE ?)',
        );
        final match = '%${searchQuery.trim()}%';
        args.addAll([match, match, match, match]);
      }

      if (startDate != null) {
        conditions.add('datetime(o.order_date) >= datetime(?)');
        args.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        final endOfDay = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        conditions.add('datetime(o.order_date) <= datetime(?)');
        args.add(endOfDay.toIso8601String());
      }

      if (conditions.isNotEmpty) {
        query += ' WHERE ${conditions.join(' AND ')}';
      }

      query += ' ORDER BY o.order_date DESC, o.id DESC';

      final List<Map<String, dynamic>> orderMaps = await db.rawQuery(query, args);
      final List<Order> orders = [];

      for (final map in orderMaps) {
        final orderId = map['id'] as int;
        
        // Fetch items
        final List<Map<String, dynamic>> itemMaps = await db.query(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [orderId],
        );

        final items = itemMaps.map((m) => OrderItem.fromMap(m)).toList();
        orders.add(Order.fromMap(map, items: items));
      }

      return orders;
    } catch (e) {
      debugPrint("Error querying orders: $e");
      rethrow;
    }
  }

  // Get order items for detailed view
  Future<List<OrderItem>> getOrderItems(int orderId) async {
    try {
      final Database db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );
      return maps.map((m) => OrderItem.fromMap(m)).toList();
    } catch (e) {
      debugPrint("Error fetching order items: $e");
      rethrow;
    }
  }

  // Dashboard Stats
  Future<Map<String, dynamic>> getDashboardStats({int lowStockLimit = 5}) async {
    try {
      final Database db = await _databaseHelper.database;

      // 1. Total Products
      final productCountMaps = await db.rawQuery('SELECT COUNT(*) as count FROM products');
      final productCount = Sqflite.firstIntValue(productCountMaps) ?? 0;

      // 2. Total Boxes in stock
      final stockSumMaps = await db.rawQuery('SELECT SUM(boxes_in_stock) as sum FROM products');
      final totalStock = (stockSumMaps.first['sum'] as num?)?.toInt() ?? 0;

      // 3. Low stock count
      final lowStockMaps = await db.rawQuery(
        'SELECT COUNT(*) as count FROM products WHERE boxes_in_stock <= ?',
        [lowStockLimit],
      );
      final lowStockCount = Sqflite.firstIntValue(lowStockMaps) ?? 0;

      // Time marks
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final monthMidnight = DateTime(now.year, now.month, 1);

      final startTodayIso = todayMidnight.toIso8601String();
      final startMonthIso = monthMidnight.toIso8601String();

      // 4. Today's orders count, revenue, boxes sold
      final todayStatsMaps = await db.rawQuery(
        "SELECT COUNT(*) as count, SUM(total_amount) as revenue, SUM(total_boxes) as boxes FROM orders WHERE status = 'COMPLETED' AND datetime(order_date) >= datetime(?)",
        [startTodayIso],
      );
      final todayOrdersCount = Sqflite.firstIntValue(todayStatsMaps) ?? 0;
      final todayRevenue = (todayStatsMaps.first['revenue'] as num?)?.toDouble() ?? 0.0;
      final todayBoxes = (todayStatsMaps.first['boxes'] as num?)?.toInt() ?? 0;

      // 5. Month revenue
      final monthStatsMaps = await db.rawQuery(
        "SELECT SUM(total_amount) as revenue FROM orders WHERE status = 'COMPLETED' AND datetime(order_date) >= datetime(?)",
        [startMonthIso],
      );
      final monthRevenue = (monthStatsMaps.first['revenue'] as num?)?.toDouble() ?? 0.0;

      return {
        'products': productCount,
        'stock': totalStock,
        'lowStock': lowStockCount,
        'todayOrdersCount': todayOrdersCount,
        'todayRevenue': todayRevenue,
        'todayBoxes': todayBoxes,
        'monthRevenue': monthRevenue,
      };
    } catch (e) {
      debugPrint("Error fetching dashboard statistics: $e");
      return {
        'products': 0,
        'stock': 0,
        'lowStock': 0,
        'todayOrdersCount': 0,
        'todayRevenue': 0.0,
        'todayBoxes': 0,
        'monthRevenue': 0.0,
      };
    }
  }

  // Get recent orders
  Future<List<Order>> getRecentOrders(int limit) async {
    try {
      final Database db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'orders',
        orderBy: 'order_date DESC, id DESC',
        limit: limit,
      );

      final List<Order> orders = [];
      for (final map in maps) {
        final orderId = map['id'] as int;
        final List<Map<String, dynamic>> itemMaps = await db.query(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [orderId],
        );
        final items = itemMaps.map((m) => OrderItem.fromMap(m)).toList();
        orders.add(Order.fromMap(map, items: items));
      }
      return orders;
    } catch (e) {
      debugPrint("Error fetching recent orders: $e");
      return [];
    }
  }
}
