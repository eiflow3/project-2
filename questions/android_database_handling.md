# Q&A: How the SQLite Database is Handled on Android

This document details how the OrderFlow SQLite database is managed, initialized, and secured on the Android platform in comparison to Web and Desktop platforms.

---

## 🏛️ High-Level Platform Comparison

Because Flutter is a multi-platform framework, the database layer in `lib/main.dart` and `lib/data/database/database_service.dart` adapts dynamically to each target OS to maximize native speed and safety:

| Platform | Database Driver / Factory | Database File Path / Location |
| :--- | :--- | :--- |
| **Android** | **Native OS SQLite Channel (Default)** | `/data/data/com.orderflow.offline/databases/offline_order_manager.db` (Isolated Sandbox) |
| **macOS / Windows** | FFI bindings (`sqflite_common_ffi`) | User's local Application Support directory (native OS file system) |
| **Web (Chrome)** | IndexedDB Web WASM (`sqflite_common_ffi_web`) | Browser-sandboxed WebAssembly virtual filesystem (IndexedDB) |

---

## 🛠️ How It Works under the Hood on Android

### 1. Zero-Overhead Native Platform Channels
In `lib/main.dart`, we configure custom drivers only for Web and Desktop:
```dart
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
```
For **Android** (and iOS), we do **not** override `databaseFactory`. By default:
* The application utilizes the native `sqflite` mobile library.
* This library leverages **Flutter MethodChannels** to talk directly to Android's built-in, highly optimized SQLite C library (`libsqlite.so`).
* Since Android has native SQLite embedded directly inside the operating system, the application has **zero overhead**: it doesn't need to bundle bulky FFI binaries or WASM engines, resulting in a much smaller APK size and faster start times!

### 2. Isolated Application Sandboxing
In `lib/data/database/database_service.dart`, we define the database path initialization:
```dart
  Future<Database> _initDatabase() async {
    String path;
    if (kIsWeb) {
      path = 'offline_order_manager.db';
    } else {
      // Discovery of native system storage path
      String databasesPath = await getDatabasesPath();
      path = join(databasesPath, 'offline_order_manager.db');
    }
```
* **`getDatabasesPath()`** is a native bridge function. On Android, it returns the standard system path allocated to our application sandbox: `/data/data/com.orderflow.offline/databases/`.
* Android's security kernel strictly enforces that only our package ID (`com.orderflow.offline`) has permission to read or write to this directory. Other apps on the device cannot access your database file, keeping customer and transaction data fully secure.

### 3. Native Constraint Enforcement
Even though Android utilizes native bindings, low-level database configurations (such as foreign key constraints) are perfectly synchronized using our custom `onConfigure` callback:
```dart
  Future<void> _onConfigure(Database db) async {
    // Crucial: Enforces SQLite foreign key constraints (defaults to OFF in SQLite)
    await db.execute('PRAGMA foreign_keys = ON;');
  }
```
This ensures that rules like `ON DELETE RESTRICT` for products with open orders are enforced directly inside the Android SQLite database engine.
