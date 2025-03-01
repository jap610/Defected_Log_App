import 'database_helper.dart';

class AdminHelper {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<bool> removeUser(String usernameToRemove, String currentAdminUsername) async {
    if (usernameToRemove == currentAdminUsername) {
      return false;
    }

    final db = await _dbHelper.database;
    final rowsDeleted = await db.delete(
      'users_info',
      where: 'user_name = ?',
      whereArgs: [usernameToRemove],
    );

    return rowsDeleted > 0;
  }

  Future<bool> updateUserRole(String username, String newRole) async {
    final db = await _dbHelper.database;
    
    final existingUser = await db.query(
      'users_info',
      where: 'user_name = ?',
      whereArgs: [username],
    );
    if (existingUser.isEmpty) {
      return false;
    }

    final rowsUpdated = await db.update(
      'users_info',
      {'user_type': newRole},
      where: 'user_name = ?',
      whereArgs: [username],
    );

    return rowsUpdated > 0;
  }
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await _dbHelper.database;
    return await db.query('users_info');
  }
}
