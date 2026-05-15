import 'package:uuid/uuid.dart';

import '../../core/crypto/password_hash.dart';
import '../../core/localization/seil_error_codes.dart';
import '../../core/storage/local_database.dart';
import '../../shared/models.dart';

class AuthRepository {
  AuthRepository(this.database);

  final LocalDatabase database;
  final _uuid = const Uuid();

  Future<bool> hasUsers() async {
    final rows = await database.db.rawQuery('SELECT COUNT(*) AS c FROM users');
    return (rows.first['c'] as int) > 0;
  }

  Future<SeilUser> bootstrapAdmin({
    required String username,
    required String name,
    required String password,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    assertUsername(normalizedUsername);
    assertDisplayName(name);
    assertPassword(password);

    if (await hasUsers()) {
      throw StateError(SeilErrorCodes.initialUserExists);
    }

    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final passwordHash = await hashPassword(password);
    await database.db.insert('users', {
      'id': id,
      'username': normalizedUsername,
      'name': name.trim(),
      'role': 'admin',
      'password_hash': passwordHash,
      'protected_account': 1,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'password_changed_at': now.toIso8601String(),
    });
    return getUserById(id);
  }

  Future<SeilUser> bootstrapLocalAdmin() {
    return bootstrapAdmin(
      username: 'admin',
      name: 'Seil Admin',
      password: _uuid.v4(),
    );
  }

  Future<SeilUser?> authenticateDefault(String password) async {
    final rows = await database.db.query(
      'users',
      orderBy: 'protected_account DESC, created_at ASC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    final matched =
        await verifyPassword(password, rows.first['password_hash'] as String);
    return matched ? _mapUser(rows.first) : null;
  }

  Future<SeilUser?> defaultUser() async {
    final rows = await database.db.query(
      'users',
      orderBy: 'protected_account DESC, created_at ASC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapUser(rows.first);
  }

  Future<SeilUser> getUserById(String id) async {
    final rows = await database.db
        .query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) {
      throw StateError(SeilErrorCodes.userNotFound);
    }
    return _mapUser(rows.first);
  }

  Future<void> setPassword({
    required String userId,
    required String newPassword,
  }) async {
    assertPassword(newPassword);
    final now = DateTime.now().toUtc().toIso8601String();
    await database.db.update(
      'users',
      {
        'password_hash': await hashPassword(newPassword),
        'updated_at': now,
        'password_changed_at': now,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  SeilUser _mapUser(Map<String, Object?> row) {
    return SeilUser(
      id: row['id'] as String,
      username: row['username'] as String,
      name: row['name'] as String,
      createdAt: parseIso(row['created_at'] as String),
      updatedAt: parseIso(row['updated_at'] as String),
      passwordChangedAt: parseIso(row['password_changed_at'] as String),
    );
  }
}
