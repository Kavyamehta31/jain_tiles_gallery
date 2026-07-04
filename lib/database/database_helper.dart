import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // Safely close database connection
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'jain_tiles_gallery.db');

    return await openDatabase(
      path,
      version: 5,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDatabase,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS order_items');
        await db.execute('DROP TABLE IF EXISTS orders');
        await db.execute('DROP TABLE IF EXISTS settings');
        await db.execute('DROP TABLE IF EXISTS product_images');
        await db.execute('DROP TABLE IF EXISTS transactions');
        await db.execute('DROP TABLE IF EXISTS products');

        await _createDatabase(db, newVersion);
      },
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        size TEXT NOT NULL,
        variety TEXT NOT NULL,
        boxes_in_stock INTEGER NOT NULL,
        pieces_per_box INTEGER NOT NULL,
        selling_price_per_box REAL NOT NULL DEFAULT 0.0,
        description TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE product_images(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        FOREIGN KEY(product_id)
        REFERENCES products(id)
        ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_number TEXT NOT NULL UNIQUE,
        order_date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        total_boxes INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'COMPLETED',
        remarks TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price_per_box REAL NOT NULL,
        total_amount REAL NOT NULL,
        boxes_after_transaction INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        product_brand TEXT NOT NULL,
        product_size TEXT NOT NULL,
        product_variety TEXT NOT NULL,
        FOREIGN KEY(order_id) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_name TEXT NOT NULL DEFAULT 'Jain Tiles Showroom',
        shop_logo_path TEXT NOT NULL DEFAULT '',
        low_stock_limit INTEGER NOT NULL DEFAULT 5,
        last_backup_time TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Seed default settings row
    await db.insert('settings', {
      'shop_name': 'Jain Tiles Showroom',
      'shop_logo_path': '',
      'low_stock_limit': 5,
      'last_backup_time': '',
    });
  }
}
