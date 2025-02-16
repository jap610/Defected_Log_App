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
      throw Exception(
          "Database file `defected_log_app.db` not found next to the exe at: $localDbPath");
    }

    return await openDatabase(
      localDbPath,
      version: 1,
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
      SELECT COUNT(*) as cnt FROM defects
      $whereClause
    ''', whereArgs);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getCategoryBreakdown({
    DateTime? start,
    DateTime? end,
  }) async {
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

  Future<List<Map<String, dynamic>>> getTrendOverTime({
    DateTime? start,
    DateTime? end,
  }) async {
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

  Future<Map<String, dynamic>?> getUser(String username, String password) async {
    final db = await instance.database;

    final result = await db.query(
      'users_info',
      where: 'user_name = ?',
      whereArgs: [username],
    );
    if (result.isEmpty) return null;

    final userRow = result.first;
    final storedHash = userRow['user_password'] as String;
    final isMatch = PasswordHasher.verifyPassword(password, storedHash);

    return isMatch ? userRow : null;
  }

  Future<bool> addUser(String username, String password, String userType) async {
    final db = await instance.database;

    final existingUser = await db.query(
      'users_info',
      where: 'user_name = ?',
      whereArgs: [username],
    );
    if (existingUser.isNotEmpty) return false;

    // Hash the password
    final hashedPassword = PasswordHasher.hashPassword(password);

    // Insert
    await db.insert(
      'users_info',
      {
        'user_name': username,
        'user_password': hashedPassword,
        'user_type': userType,
      },
    );
    return true;
  }

  Future<void> saveDefects(List<Map<String, dynamic>> defects) async {
    final db = await instance.database;
    Batch batch = db.batch();
    for (var defect in defects) {
      batch.insert('defects', defect);
    }
    await batch.commit(noResult: true);
  }
}
