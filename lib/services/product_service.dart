import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/product.dart';

class ProductService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> addProduct(Product product) async {
    final Database db = await _databaseHelper.database;

    return await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Product>> getProducts() async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      orderBy: 'name ASC',
    );

    return maps.map((e) => Product.fromMap(e)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final Database db = await _databaseHelper.database;

    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final Database db = await _databaseHelper.database;

    await db.delete('product_images', where: 'product_id = ?', whereArgs: [id]);

    await db.delete('transactions', where: 'product_id = ?', whereArgs: [id]);

    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}
