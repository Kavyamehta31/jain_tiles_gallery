import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/product.dart';

class ProductService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Utility to copy images to app local directory
  Future<String> _copyImageToAppStorage(String sourcePath) async {
    try {
      final file = File(sourcePath);
      if (!await file.exists()) {
        return sourcePath;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'product_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Check if file is already in the application storage
      if (p.isWithin(imagesDir.path, sourcePath)) {
        return sourcePath;
      }

      final extension = p.extension(sourcePath);
      final uniqueFileName = '${const Uuid().v4()}$extension';
      final targetPath = p.join(imagesDir.path, uniqueFileName);

      final savedFile = await file.copy(targetPath);
      return savedFile.path;
    } catch (e) {
      debugPrint("Error copying image to app storage: $e");
      rethrow;
    }
  }

  // Utility to delete images from app storage
  Future<void> _deleteImageFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("Error deleting image file from disk: $e");
    }
  }

  // Adds a product, copies selected images, and registers image paths in database
  Future<int> addProduct(Product product) async {
    try {
      final Database db = await _databaseHelper.database;

      return await db.transaction<int>((txn) async {
        // 1. Insert product details
        final productId = await txn.insert(
          'products',
          product.toMap(),
        );

        // 2. Copy and store images
        for (final path in product.imagePaths) {
          final localPath = await _copyImageToAppStorage(path);
          await txn.insert('product_images', {
            'product_id': productId,
            'image_path': localPath,
          });
        }

        return productId;
      });
    } catch (e) {
      debugPrint("Error in addProduct transaction: $e");
      rethrow;
    }
  }

  // Gets list of all products, fetching associated image paths
  Future<List<Product>> getProducts() async {
    try {
      final Database db = await _databaseHelper.database;

      final List<Map<String, dynamic>> productMaps = await db.query(
        'products',
        orderBy: 'name ASC',
      );

      final List<Product> products = [];
      for (final map in productMaps) {
        final productId = map['id'] as int;

        final List<Map<String, dynamic>> imageMaps = await db.query(
          'product_images',
          where: 'product_id = ?',
          whereArgs: [productId],
        );

        final List<String> imagePaths = imageMaps
            .map((item) => item['image_path'] as String)
            .toList();

        products.add(Product.fromMap(map, imagePaths: imagePaths));
      }

      return products;
    } catch (e) {
      debugPrint("Error in getProducts: $e");
      rethrow;
    }
  }

  // Fetches a single product by ID
  Future<Product?> getProduct(int id) async {
    try {
      final Database db = await _databaseHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;

      final List<Map<String, dynamic>> imageMaps = await db.query(
        'product_images',
        where: 'product_id = ?',
        whereArgs: [id],
      );

      final List<String> imagePaths = imageMaps
          .map((item) => item['image_path'] as String)
          .toList();

      return Product.fromMap(maps.first, imagePaths: imagePaths);
    } catch (e) {
      debugPrint("Error in getProduct: $e");
      rethrow;
    }
  }

  // Updates product details, processes image diffs
  Future<int> updateProduct(Product product) async {
    final productId = product.id;
    if (productId == null) return 0;

    try {
      final Database db = await _databaseHelper.database;

      return await db.transaction<int>((txn) async {
        // 1. Update product details
        final updatedRows = await txn.update(
          'products',
          product.toMap(),
          where: 'id = ?',
          whereArgs: [productId],
        );

        // 2. Fetch existing images from database to perform diff
        final List<Map<String, dynamic>> existingImageRows = await txn.query(
          'product_images',
          where: 'product_id = ?',
          whereArgs: [productId],
        );

        final List<String> dbPaths = existingImageRows
            .map((row) => row['image_path'] as String)
            .toList();

        // Deleted images
        final List<String> deletedPaths = dbPaths
            .where((path) => !product.imagePaths.contains(path))
            .toList();

        // New images
        final List<String> newPaths = product.imagePaths
            .where((path) => !dbPaths.contains(path))
            .toList();

        // Delete removed files and DB mappings
        for (final path in deletedPaths) {
          await _deleteImageFile(path);
          await txn.delete(
            'product_images',
            where: 'product_id = ? AND image_path = ?',
            whereArgs: [productId, path],
          );
        }

        // Copy and store new files
        for (final path in newPaths) {
          final localPath = await _copyImageToAppStorage(path);
          await txn.insert('product_images', {
            'product_id': productId,
            'image_path': localPath,
          });
        }

        return updatedRows;
      });
    } catch (e) {
      debugPrint("Error in updateProduct transaction: $e");
      rethrow;
    }
  }

  // Deletes product, deletes physical image files first, then records from db
  Future<int> deleteProduct(int id) async {
    try {
      final Database db = await _databaseHelper.database;

      // 1. Fetch image paths to clean up physical storage
      final List<Map<String, dynamic>> imageMaps = await db.query(
        'product_images',
        where: 'product_id = ?',
        whereArgs: [id],
      );

      final List<String> imagePaths = imageMaps
          .map((item) => item['image_path'] as String)
          .toList();

      for (final path in imagePaths) {
        await _deleteImageFile(path);
      }

      // 2. Delete database records in transaction
      return await db.transaction<int>((txn) async {
        // Delete child rows explicitly for safety
        await txn.delete(
          'product_images',
          where: 'product_id = ?',
          whereArgs: [id],
        );

        // Delete the parent product (cascade delete will automatically clean up order_items)
        return await txn.delete(
          'products',
          where: 'id = ?',
          whereArgs: [id],
        );
      });
    } catch (e) {
      debugPrint("Error in deleteProduct transaction: $e");
      rethrow;
    }
  }
}
