// lib/src/services/tenant_database_service.dart
import 'dart:async';
import 'package:postgres/postgres.dart';

/// Tenant Configuration DTO
class TenantConfig {
  final int id;
  final String name;
  final String slug;
  final String dbHost;
  final int dbPort;
  final String dbName;
  final String dbUsername;
  final String dbPassword;
  final String status;

  TenantConfig({
    required this.id,
    required this.name,
    required this.slug,
    required this.dbHost,
    required this.dbPort,
    required this.dbName,
    required this.dbUsername,
    required this.dbPassword,
    required this.status,
  });
}

/// Cache entry tracking dynamic pool and usage timestamp
class TenantPoolEntry {
  final Pool pool;
  DateTime lastUsed;

  TenantPoolEntry(this.pool) : lastUsed = DateTime.now();
}

/// Dynamic Connection Pooler Service managing PostgreSQL tenant databases
class TenantDatabaseService {
  static final TenantDatabaseService _instance = TenantDatabaseService._internal();
  factory TenantDatabaseService() => _instance;
  TenantDatabaseService._internal();

  final Map<String, TenantPoolEntry> _pools = {};
  Timer? _cleanupTimer;

  /// Start background timer purging idle connection pools
  void initializeCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) => _purgeIdlePools());
  }

  /// Get or open an active PostgreSQL connection pool for the given tenant
  Future<Pool> getPoolForTenant(TenantConfig config) async {
    final slug = config.slug;

    if (_pools.containsKey(slug)) {
      final entry = _pools[slug]!;
      entry.lastUsed = DateTime.now();
      return entry.pool;
    }

    final endpoint = Endpoint(
      host: config.dbHost,
      port: config.dbPort,
      database: config.dbName,
      username: config.dbUsername,
      password: config.dbPassword,
    );

    final pool = Pool.withEndpoints(
      [endpoint],
      settings: const PoolSettings(
        maxConnectionCount: 15,
        sslMode: SslMode.disable, // Use SslMode.require in SSL environments
      ),
    );

    _pools[slug] = TenantPoolEntry(pool);
    print('🔌 Opened new DB connection pool for tenant database: ${config.dbName}');
    return pool;
  }

  /// Purge connection pools that have been idle for > 15 minutes
  void _purgeIdlePools() async {
    final now = DateTime.now();
    const idleThreshold = Duration(minutes: 15);
    final keysToRemove = <String>[];

    _pools.forEach((slug, entry) {
      if (now.difference(entry.lastUsed) > idleThreshold) {
        keysToRemove.add(slug);
      }
    });

    for (final slug in keysToRemove) {
      final entry = _pools.remove(slug);
      if (entry != null) {
        await entry.pool.close();
        print('🔒 Closed idle connection pool for tenant: $slug');
      }
    }
  }

  /// Close all active pools during server shutdown
  Future<void> shutdown() async {
    _cleanupTimer?.cancel();
    for (final entry in _pools.values) {
      await entry.pool.close();
    }
    _pools.clear();
    print('🛑 All tenant database pools shut down successfully.');
  }
}
