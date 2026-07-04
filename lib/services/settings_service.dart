import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

import '../database/database_helper.dart';
import '../models/settings_model.dart';

class SettingsService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Retrieve the showroom configuration (reads the single seeded configuration row)
  Future<SettingsModel> getSettings() async {
    try {
      final Database db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('settings', limit: 1);

      if (maps.isNotEmpty) {
        return SettingsModel.fromMap(maps.first);
      }

      // Seed fallback in case row is missing
      const defaultSettings = SettingsModel(
        id: 1,
        shopName: "Jain Tiles Showroom",
        shopLogoPath: "",
        lowStockLimit: 5,
        lastBackupTime: "",
      );
      
      await db.insert('settings', defaultSettings.toMap());
      return defaultSettings;
    } catch (e) {
      debugPrint("Error loading settings: $e");
      rethrow;
    }
  }

  // Update configuration parameters in database
  Future<void> updateSettings(SettingsModel settings) async {
    try {
      final Database db = await _databaseHelper.database;
      await db.update(
        'settings',
        settings.toMap(),
        where: 'id = ?',
        whereArgs: [settings.id ?? 1],
      );
    } catch (e) {
      debugPrint("Error updating settings: $e");
      rethrow;
    }
  }
}
