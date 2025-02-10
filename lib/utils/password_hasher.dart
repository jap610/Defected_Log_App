import 'package:bcrypt/bcrypt.dart';

class PasswordHasher {
  static String hashPassword(String plainTextPassword) {
    final salt = BCrypt.gensalt();
    return BCrypt.hashpw(plainTextPassword, salt);
  }

  static bool verifyPassword(String plainTextPassword, String hashedPassword) {
    return BCrypt.checkpw(plainTextPassword, hashedPassword);
  }
}
