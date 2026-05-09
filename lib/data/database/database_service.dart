import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// DatabaseService handles the core database lifecycle and connections.
/// It implements a singleton pattern to ensure that the entire application
/// communicates through a single database connection stream, preventing race locks.
class DatabaseService {
  // Singleton pattern instantiation
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  /// Retrieves the active database connection. If not initialized, opens a new one.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Establishes the database file inside the system's local Application documents path
  /// and runs schema scripts on first-time launch.
  Future<Database> _initDatabase() async {
    String path;
    if (kIsWeb) {
      // On Web, raw filesystem directory paths are sandboxed, so we store
      // our SQLite files directly inside the browser's persistent IndexedDB context.
      path = 'offline_order_manager.db';
    } else {
      // Discovery of native system storage path
      String databasesPath = await getDatabasesPath();
      path = join(databasesPath, 'offline_order_manager.db');
    }

    // Opens or creates the SQLite DB file, setting our version scheme
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  /// Sets low-level database settings upon connection (e.g. enabling foreign key enforcement).
  Future<void> _onConfigure(Database db) async {
    // Crucial: Enforces SQLite foreign key constraints (defaults to OFF in SQLite)
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  /// Executes SQL commands to build all required data tables from scratch.
  Future<void> _onCreate(Database db, int version) async {
    // 1. Create standard security users credentials table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        auth_type TEXT NOT NULL,
        password_hash TEXT,
        pin_hash TEXT,
        created_at TEXT NOT NULL
      );
    ''');

    // 2. Create products inventory table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        unit_cost REAL NOT NULL,
        selling_price REAL NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        extra_columns_json TEXT,
        created_at TEXT NOT NULL
      );
    ''');

    // 3. Create client orders transaction tracking table
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT NOT NULL,
        customer_address TEXT NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        computed_price REAL NOT NULL,
        fulfillment_type TEXT NOT NULL,
        delivery_rider TEXT,
        status TEXT NOT NULL DEFAULT 'PENDING',
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
      );
    ''');

    // 4. Create merchant branding config table
    await db.execute('''
      CREATE TABLE merchant_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_name TEXT NOT NULL,
        store_tagline TEXT NOT NULL,
        store_icon TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    // Add a default system user to skip manual CLI inserts (just in case)
    // The presentation setup wizard will prompt to overwrite this default
    await db.insert('users', {
      'username': 'admin',
      'auth_type': 'PIN',
      'pin_hash': '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918', // SHA-256 for '1234'
      'created_at': DateTime.now().toIso8601String(),
    });

    // Pre-populate with default branding (e.g. GilNor Gas Store as default!)
    await db.insert('merchant_config', {
      'store_name': 'GilNor Gas Store',
      'store_tagline': 'OFFLINE LEDGER & POS SYSTEM',
      'store_icon': 'GAS',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Drops or deletes all data from tables and re-inserts the default admin.
  /// Used for application reset functionality.
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Clear orders ledger
      await txn.execute('DELETE FROM orders;');
      // 2. Clear products inventory
      await txn.execute('DELETE FROM products;');
      // 3. Clear security credentials
      await txn.execute('DELETE FROM users;');
      // 4. Clear merchant branding
      await txn.execute('DELETE FROM merchant_config;');

      // 5. Re-inject temporary default credentials to enable setup flow
      await txn.insert('users', {
        'username': 'admin',
        'auth_type': 'PIN',
        'pin_hash': '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918', // SHA-256 for '1234'
        'created_at': DateTime.now().toIso8601String(),
      });

      // 6. Re-inject temporary default branding to enable custom client onboarding
      await txn.insert('merchant_config', {
        'store_name': 'GilNor Gas Store',
        'store_tagline': 'OFFLINE LEDGER & POS SYSTEM',
        'store_icon': 'GAS',
        'updated_at': DateTime.now().toIso8601String(),
      });
    });
  }

  /// Safely closes the database connection stream during app shutdown or logout.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
