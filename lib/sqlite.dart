import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DBHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  static Future<Database> initDB() async {
    String path = join(await getDatabasesPath(), 'map_tiles.db');
    return await openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE tiles (url TEXT PRIMARY KEY, tile BLOB)',
        );
      },
      version: 1,
    );
  }

  static Future<void> insertTile(String url, List<int> tile) async {
    final db = await database;
    await db.insert(
      'tiles',
      {'url': url, 'tile': tile},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<int>?> getTile(String url) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tiles',
      where: 'url = ?',
      whereArgs: [url],
    );

    if (maps.isNotEmpty) {
      return maps.first['tile'];
    }
    return null;
  }
}
