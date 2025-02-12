import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:techware_flutter/models/ComputerComponent.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._constructor();
  static Database? _database;

  final String _tableName = "computer_components";
  final String _offlineChangesTable = "offline_changes";

  static int temporaryId = -1;

  DatabaseService._constructor();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await getDatabase();
    return _database!;
  }

  Future<Database> getDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, "techware_man_db.db");

    final database = await openDatabase(
      databasePath,
      version: 2,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE IF NOT EXISTS $_tableName (
            product_id INTEGER PRIMARY KEY,
            product_name TEXT NOT NULL,
            manufacturer TEXT NOT NULL,
            category TEXT NOT NULL,
            price REAL NOT NULL,
            quantity INTEGER NOT NULL,
            release_date TEXT NOT NULL
          )
        ''');
        db.execute('''
          CREATE TABLE IF NOT EXISTS $_offlineChangesTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            change_type TEXT NOT NULL,
            product_id INTEGER,
            data TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');
      },
    );

    return database;
  }

  Future<int> addComponent(ComputerComponent component) async {
    final db = await database;

    int resultId = await db.insert(_tableName, component.toJson());
    return resultId;
  }

  Future<int> addComponentOffline(ComputerComponent component) async {
    final db = await database;

    int resultId = await db.insert(_tableName, component.toJsonWithoutId());
    component.id = --temporaryId;

    await db.insert(_offlineChangesTable, {
      "change_type": "add",
      "product_id": temporaryId,
      "data": json.encode(component.toJson()),
      "synced": 0,
    });

    return temporaryId;
  }

  Future<int> updateComponent(ComputerComponent component) async {
    final db = await database;

    int result = await db.update(
      _tableName,
      component.toJsonWithoutId(),
      where: "product_id = ?",
      whereArgs: [component.id],
    );

    return result;
  }

  Future<int> updateComponentOffline(ComputerComponent component) async {
    final db = await database;

    int result = await db.update(
      _tableName,
      component.toJsonWithoutId(),
      where: "product_id = ?",
      whereArgs: [component.id],
    );

    // check if the component was added offline
    final offlineChanges = await db.query(
      _offlineChangesTable,
      where: "change_type = ? AND product_id = ?",
      whereArgs: ['add', component.id],
    );

    // if so, update the "add" entry instead
    if (offlineChanges.isNotEmpty) {
      await db.update(
        _offlineChangesTable,
        {
          "data": json.encode(component.toJsonWithoutId()),
          "synced": 0,
        },
        where: "product_id = ? AND change_type = ?",
        whereArgs: [component.id, 'add'],
      );

    // otherwise, log the update operation in the offline changes table
    } else {
      await db.insert(_offlineChangesTable, {
        "change_type": "update",
        "product_id": component.id,
        "data": json.encode(component.toJsonWithoutId()),
        "synced": 0,
      });

    }

    return result;
  }

  Future<int> deleteComponent(int id) async {
    final db = await database;
    int result = await db.delete(_tableName, where: "product_id = ?", whereArgs: [id]);
    return result;
  }

  Future<int> deleteComponentOffline(int id) async {
    final db = await database;

    int result = await db.delete(_tableName, where: "product_id = ?", whereArgs: [id]);

    // check if the component was added offline
    final offlineChanges = await db.query(
      _offlineChangesTable,
      where: "change_type = ? AND product_id = ?",
      whereArgs: ['add', id],
    );

    // if so, remove the 'add' entry, as it is no longer necessary to add the item to the server db
    if (offlineChanges.isNotEmpty) {
      await db.delete(
        _offlineChangesTable,
        where: "product_id = ? AND change_type = ?",
        whereArgs: [id, 'add'],
      );

    // otherwise, log the delete operation in the offline changes table
    } else {
      await db.insert(_offlineChangesTable, {
        "change_type": "delete",
        "product_id": id,
        "data": '',
        "synced": 0,
      });

    }

    return result;
  }

  Future<ComputerComponent?> getComponentById(int id) async {
    final db = await database;

    final data = await db.query(
      _tableName,
      where: "product_id = ?",
      whereArgs: [id],
    );

    if (data.isNotEmpty) {
      return ComputerComponent.fromJson(data.first);

    } else {
      return null;
    }
  }


  Future<List<ComputerComponent>> getAllComponents() async {
    final db = await database;
    final data = await db.query(_tableName);

    return data.map((e) => ComputerComponent.fromJson(e)).toList();
  }

  Future<void> clearAllComponents() async {
    final db = await database;
    await db.delete(_tableName);
  }

  Future<List<Map<String, dynamic>>> getOfflineChanges() async {
    final db = await database;
    return await db.query(_offlineChangesTable, where: "synced = 0");
  }

  Future<void> markChangeAsSynced(int id) async {
    final db = await database;
    await db.update(
      _offlineChangesTable,
      {"synced": 1},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<void> clearOfflineChanges() async {
    final db = await database;
    await db.delete(_offlineChangesTable);
  }
}