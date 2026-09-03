// lib/src/services/auth_service.dart
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:postgres/postgres.dart';
import 'tenant_database_service.dart';

class AuthService {
  final String jwtSecret;

  AuthService({required this.jwtSecret});

  // ─────────────────────────── TENANT (SCOPED) LOGIN ───────────────────────────

  /// Login a user against a specific tenant database (SchoolAdmin, Teacher, Student, etc.)
  Future<Map<String, dynamic>?> loginTenantUser({
    required Pool tenantPool,
    required String username,
    required String password,
    required TenantConfig tenantConfig,
  }) async {
    final result = await tenantPool.execute(
      Sql.named('''
        SELECT id, username, email, role
        FROM users
        WHERE LOWER(username) = LOWER(@username)
          AND password_hash = @password
          AND status = 'active'
      '''),
      parameters: {
        'username': username,
        'password': password, // Use bcrypt comparison in production
      },
    );

    if (result.isEmpty) return null;

    final row = result.first.toColumnMap();

    return {
      'token': _generateToken(
        userId: row['id'].toString(),
        username: row['username'] as String,
        role: row['role'] as String,
        tenantSlug: tenantConfig.slug,
        schoolName: tenantConfig.name,
        isImpersonating: false,
      ),
      'user': {
        'id': row['id'],
        'username': row['username'],
        'email': row['email'],
        'role': row['role'],
        'tenantSlug': tenantConfig.slug,
        'schoolName': tenantConfig.name,
      }
    };
  }

  // ─────────────────────────── SUPER ADMIN LOGIN ───────────────────────────

  /// Login a Super Admin user against the Central Database
  Future<Map<String, dynamic>?> loginSuperAdmin({
    required Pool centralPool,
    required String email,
    required String password,
  }) async {
    final result = await centralPool.execute(
      Sql.named('''
        SELECT id, email, role
        FROM central_users
        WHERE LOWER(email) = LOWER(@email)
          AND password_hash = @password
      '''),
      parameters: {
        'email': email,
        'password': password,
      },
    );

    if (result.isEmpty) return null;

    final row = result.first.toColumnMap();

    return {
      'token': _generateToken(
        userId: row['id'].toString(),
        username: row['email'] as String,
        role: 'SuperAdmin',
        tenantSlug: 'platform',
        schoolName: 'IFTIINSHE PLATFORM',
        isImpersonating: false,
        isSuperAdmin: true,
      ),
      'user': {
        'id': row['id'],
        'email': row['email'],
        'role': 'SuperAdmin',
      }
    };
  }

  // ─────────────────────────── IMPERSONATION TOKEN ───────────────────────────

  /// Generate a scoped impersonation token for Super Admin to access a school's dashboard
  String generateImpersonationToken({
    required String superAdminEmail,
    required String targetSlug,
    required String targetSchoolName,
  }) {
    return _generateToken(
      userId: 'superadmin',
      username: superAdminEmail,
      role: 'SchoolAdmin',
      tenantSlug: targetSlug,
      schoolName: targetSchoolName,
      isImpersonating: true,
      isSuperAdmin: false,
    );
  }

  // ─────────────────────────── TOKEN VERIFICATION ───────────────────────────

  /// Verify and decode a JWT token
  Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(jwtSecret));
      return jwt.payload as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────── PRIVATE HELPERS ───────────────────────────

  String _generateToken({
    required String userId,
    required String username,
    required String role,
    required String tenantSlug,
    required String schoolName,
    required bool isImpersonating,
    bool isSuperAdmin = false,
  }) {
    final jwt = JWT({
      'sub': userId,
      'username': username,
      'role': role,
      'tenantSlug': tenantSlug,
      'schoolName': schoolName,
      'isImpersonating': isImpersonating,
      'isSuperAdmin': isSuperAdmin,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });

    return jwt.sign(
      SecretKey(jwtSecret),
      expiresIn: isImpersonating
          ? const Duration(hours: 2) // Impersonation tokens expire in 2 hours
          : const Duration(hours: 24),
    );
  }
}
