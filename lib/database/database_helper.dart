import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../utils/password_hasher.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);
    final localDbPath = p.join(exeDir, 'defected_log_app.db');
    if (!File(localDbPath).existsSync()) {
      throw Exception("Database file `defected_log_app.db` not found at: $localDbPath");
    }
    return await openDatabase(
      localDbPath,
      version: 1,
      onOpen: (db) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS defect_types (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            defect_name TEXT UNIQUE NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> getTotalCount({DateTime? start, DateTime? end}) async {
    final db = await instance.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];
    if (start != null && end != null) {
      whereClause = 'WHERE timestamp >= ? AND timestamp <= ?';
      whereArgs = [start.toIso8601String(), end.toIso8601String()];
    }
    final result = await db.rawQuery('''
      SELECT COUNT(*) as cnt
      FROM defects
      $whereClause
    ''', whereArgs);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getCategoryBreakdown({DateTime? start, DateTime? end}) async {
    final db = await instance.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];
    if (start != null && end != null) {
      whereClause = 'WHERE timestamp >= ? AND timestamp <= ?';
      whereArgs = [start.toIso8601String(), end.toIso8601String()];
    }
    final result = await db.rawQuery('''
      SELECT defect_type, COUNT(*) as cnt
      FROM defects
      $whereClause
      GROUP BY defect_type
    ''', whereArgs);
    return result;
  }

  Future<List<Map<String, dynamic>>> getTrendOverTime({DateTime? start, DateTime? end}) async {
    final db = await instance.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];
    if (start != null && end != null) {
      whereClause = 'WHERE timestamp >= ? AND timestamp <= ?';
      whereArgs = [start.toIso8601String(), end.toIso8601String()];
    }
    final result = await db.rawQuery('''
      SELECT date(timestamp) as day, COUNT(*) as cnt
      FROM defects
      $whereClause
      GROUP BY day
      ORDER BY day
    ''', whereArgs);
    return result;
  }

  Future<List<Map<String, dynamic>>> getAllDefects() async {
    final db = await instance.database;
    return await db.query('defects');
  }

  Future<List<Map<String, dynamic>>> getDefectsByUser(String username) async {
    final db = await instance.database;
    return await db.query('defects', where: 'created_by = ?', whereArgs: [username]);
  }

  Future<int> updateDefect(int defectId, String newDocNumber, String newDefectType, DateTime newTimestamp) async {
    final db = await instance.database;
    final updateData = {
      'document_number': newDocNumber,
      'defect_type': newDefectType,
      'timestamp': newTimestamp.toIso8601String(),
    };
    final rowsAffected = await db.update(
      'defects',
      updateData,
      where: 'id = ?',
      whereArgs: [defectId],
    );
    return rowsAffected;
  }

  Future<void> saveDefects(List<Map<String, dynamic>> defects) async {
    final db = await instance.database;
    Batch batch = db.batch();
    for (var defect in defects) {
      batch.insert('defects', defect);
    }
    await batch.commit(noResult: true);
  }

  Future<Map<String, dynamic>?> getUser(String username, String password) async {
    final db = await instance.database;
    final result = await db.query('users_info', where: 'user_name = ?', whereArgs: [username]);
    if (result.isEmpty) return null;
    final userRow = result.first;
    final storedHash = userRow['user_password'] as String;
    final isMatch = PasswordHasher.verifyPassword(password, storedHash);
    return isMatch ? userRow : null;
  }

  Future<bool> addUser(String username, String password, String userType) async {
    final db = await instance.database;
    final existingUser = await db.query('users_info', where: 'user_name = ?', whereArgs: [username]);
    if (existingUser.isNotEmpty) return false;
    final hashedPassword = PasswordHasher.hashPassword(password);
    await db.insert('users_info', {
      'user_name': username,
      'user_password': hashedPassword,
      'user_type': userType,
    });
    return true;
  }

  Future<int> insertDefectType(String defectTypeName) async {
    final db = await instance.database;
    final existing = await db.query('defect_types', where: 'defect_name = ?', whereArgs: [defectTypeName]);
    if (existing.isNotEmpty) {
      throw Exception('Defect type "$defectTypeName" already exists.');
    }
    final newId = await db.insert('defect_types', {'defect_name': defectTypeName});
    return newId;
  }

  Future<void> renameDefectType(String oldDefectTypeName, String newDefectTypeName) async {
    final db = await instance.database;
    final oldType = await db.query('defect_types', where: 'defect_name = ?', whereArgs: [oldDefectTypeName]);
    if (oldType.isEmpty) {
      throw Exception('Defect type "$oldDefectTypeName" does not exist.');
    }
    final newType = await db.query('defect_types', where: 'defect_name = ?', whereArgs: [newDefectTypeName]);
    if (newType.isNotEmpty) {
      throw Exception('Defect type "$newDefectTypeName" already exists.');
    }
    await db.transaction((txn) async {
      await txn.update(
        'defect_types',
        {'defect_name': newDefectTypeName},
        where: 'defect_name = ?',
        whereArgs: [oldDefectTypeName],
      );
      await txn.update(
        'defects',
        {'defect_type': newDefectTypeName},
        where: 'defect_type = ?',
        whereArgs: [oldDefectTypeName],
      );
    });
  }

  Future<bool> isDefectTypeInUse(String defectTypeName) async {
    final db = await instance.database;
    final result = await db.query('defects', where: 'defect_type = ?', whereArgs: [defectTypeName], limit: 1);
    return result.isNotEmpty;
  }

  Future<int> deleteDefectType(String defectTypeName) async {
    final db = await instance.database;
    final inUse = await isDefectTypeInUse(defectTypeName);
    if (inUse) {
      throw Exception('Cannot delete "$defectTypeName": it is still in use.');
    }
    final deletedCount = await db.delete(
      'defect_types',
      where: 'defect_name = ?',
      whereArgs: [defectTypeName],
    );
    return deletedCount;
  }

  Future<List<Map<String, dynamic>>> getAllDefectTypes() async {
    final db = await instance.database;
    return await db.query('defect_types');
  }

  Future<int> deleteDefect(int defectId) async {
    final db = await instance.database;
    return await db.delete(
      'defects',
      where: 'id = ?',
      whereArgs: [defectId],
    );
  }
}
