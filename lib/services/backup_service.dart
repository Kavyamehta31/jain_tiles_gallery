import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

import '../database/database_helper.dart';
import '../services/settings_service.dart';

class BackupService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final SettingsService _settingsService = SettingsService();

  // Create a timestamped backup containing database.db, product_images/, and settings.json
  Future<String> backup() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dbDir = await getDatabasesPath();
      final activeDbPath = p.join(dbDir, 'jain_tiles_gallery.db');
      final activeImagesDir = Directory(p.join(docsDir.path, 'product_images'));

      // Create timestamped backup folder
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      final backupFolderName = 'JainTilesBackup_$timestamp';
      final backupDir = Directory(p.join(docsDir.path, 'backups', backupFolderName));
      
      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
      }
      await backupDir.create(recursive: true);

      // Copy database file
      final backupDbPath = p.join(backupDir.path, 'database.db');
      if (await File(activeDbPath).exists()) {
        await File(activeDbPath).copy(backupDbPath);
      }

      // Copy product images recursively
      final backupImagesDir = Directory(p.join(backupDir.path, 'product_images'));
      if (await activeImagesDir.exists()) {
        await backupImagesDir.create(recursive: true);
        await for (final entity in activeImagesDir.list(recursive: true)) {
          if (entity is File) {
            final relative = p.relative(entity.path, from: activeImagesDir.path);
            final targetPath = p.join(backupImagesDir.path, relative);
            await Directory(p.dirname(targetPath)).create(recursive: true);
            await entity.copy(targetPath);
          }
        }
      }

      // Read current settings and counts
      final settings = await _settingsService.getSettings();
      final Database db = await _databaseHelper.database;
      final productCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM products'),
          ) ??
          0;
      final orderCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM orders'),
          ) ??
          0;

      // Save metadata settings.json
      final metadata = {
        'backup_name': backupFolderName,
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': '0.4.0',
        'db_version': 5,
        'shop_name': settings.shopName,
        'low_stock_limit': settings.lowStockLimit,
        'product_count': productCount,
        'transaction_count': orderCount, // Mapped for stats listing compatibility
      };

      final settingsJsonFile = File(p.join(backupDir.path, 'settings.json'));
      await settingsJsonFile.writeAsString(jsonEncode(metadata));

      // Update last backup time
      final formattedTime = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
      await _settingsService.updateSettings(
        settings.copyWith(lastBackupTime: formattedTime),
      );

      return backupFolderName;
    } catch (e) {
      debugPrint("Error performing backup: $e");
      rethrow;
    }
  }

  // Retrieve the list of existing backups sorted by date
  Future<List<Map<String, dynamic>>> getBackupsList() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final backupsDir = Directory(p.join(docsDir.path, 'backups'));
      if (!await backupsDir.exists()) {
        return [];
      }

      final List<Map<String, dynamic>> list = [];
      await for (final entity in backupsDir.list()) {
        if (entity is Directory) {
          final settingsFile = File(p.join(entity.path, 'settings.json'));
          final dbFile = File(p.join(entity.path, 'database.db'));
          
          if (await settingsFile.exists() && await dbFile.exists()) {
            try {
              final jsonStr = await settingsFile.readAsString();
              final Map<String, dynamic> metadata = jsonDecode(jsonStr);
              
              // Calculate backup folder assets size
              int imagesSize = 0;
              final imagesDir = Directory(p.join(entity.path, 'product_images'));
              if (await imagesDir.exists()) {
                await for (final file in imagesDir.list(recursive: true)) {
                  if (file is File) {
                    imagesSize += await file.length();
                  }
                }
              }
              final dbSize = await dbFile.length();
              
              metadata['db_size'] = dbSize;
              metadata['images_size'] = imagesSize;
              metadata['folder_name'] = p.basename(entity.path);
              list.add(metadata);
            } catch (e) {
              debugPrint("Error reading metadata for ${entity.path}: $e");
            }
          }
        }
      }

      // Sort by newest first
      list.sort((a, b) {
        final tA = DateTime.parse(a['timestamp'] as String);
        final tB = DateTime.parse(b['timestamp'] as String);
        return tB.compareTo(tA);
      });

      return list;
    } catch (e) {
      debugPrint("Error listing backups: $e");
      return [];
    }
  }

  // Deletes a specific backup directory
  Future<void> deleteBackup(String folderName) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(p.join(docsDir.path, 'backups', folderName));
      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint("Error deleting backup folder $folderName: $e");
      rethrow;
    }
  }

  // Restores the entire database and images directories from a backup folder
  Future<void> restoreBackup(String folderName) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(p.join(docsDir.path, 'backups', folderName));
      if (!await backupDir.exists()) {
        throw Exception("Backup folder not found");
      }

      final backupDbFile = File(p.join(backupDir.path, 'database.db'));
      final backupImagesDir = Directory(p.join(backupDir.path, 'product_images'));
      final settingsFile = File(p.join(backupDir.path, 'settings.json'));

      if (!await backupDbFile.exists() || !await settingsFile.exists()) {
        throw Exception("Invalid backup folder structure");
      }

      // 1. Terminate current SQLite connection
      await _databaseHelper.closeDatabase();

      // 2. Replace the active database file
      final dbDir = await getDatabasesPath();
      final activeDbPath = p.join(dbDir, 'jain_tiles_gallery.db');
      await backupDbFile.copy(activeDbPath);

      // 3. Clear active product images directory and copy restored ones
      final activeImagesDir = Directory(p.join(docsDir.path, 'product_images'));
      if (await activeImagesDir.exists()) {
        await activeImagesDir.delete(recursive: true);
      }
      await activeImagesDir.create(recursive: true);

      if (await backupImagesDir.exists()) {
        await for (final entity in backupImagesDir.list(recursive: true)) {
          if (entity is File) {
            final relative = p.relative(entity.path, from: backupImagesDir.path);
            final targetPath = p.join(activeImagesDir.path, relative);
            await Directory(p.dirname(targetPath)).create(recursive: true);
            await entity.copy(targetPath);
          }
        }
      }

      // 4. Force re-open database connection
      await _databaseHelper.database;
    } catch (e) {
      debugPrint("Error performing restore: $e");
      rethrow;
    }
  }

  // Fetches current database stats, file sizes, and backup logs
  Future<Map<String, dynamic>> getMaintenanceStats() async {
    try {
      final Database db = await _databaseHelper.database;
      final docsDir = await getApplicationDocumentsDirectory();
      final dbDir = await getDatabasesPath();

      final productCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM products'),
          ) ??
          0;
      final orderCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM orders'),
          ) ??
          0;

      final dbFile = File(p.join(dbDir, 'jain_tiles_gallery.db'));
      int dbSize = 0;
      if (await dbFile.exists()) {
        dbSize = await dbFile.length();
      }

      int imagesSize = 0;
      final imagesDir = Directory(p.join(docsDir.path, 'product_images'));
      if (await imagesDir.exists()) {
        await for (final file in imagesDir.list(recursive: true)) {
          if (file is File) {
            imagesSize += await file.length();
          }
        }
      }

      final settings = await _settingsService.getSettings();

      return {
        'product_count': productCount,
        'transaction_count': orderCount, // Mapped for consistency in UI stats row
        'db_size': dbSize,
        'images_size': imagesSize,
        'last_backup_time':
            settings.lastBackupTime.isEmpty ? 'Never' : settings.lastBackupTime,
      };
    } catch (e) {
      debugPrint("Error fetching maintenance stats: $e");
      return {
        'product_count': 0,
        'transaction_count': 0,
        'db_size': 0,
        'images_size': 0,
        'last_backup_time': 'Never',
      };
    }
  }

  // Format bytes to readable size
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
