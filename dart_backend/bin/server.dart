// bin/server.dart
import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../lib/src/services/tenant_database_service.dart';
import '../lib/src/services/auth_service.dart';
import '../lib/src/services/provisioning_pipeline.dart';
import '../lib/src/middleware/identify_tenant_middleware.dart';
import '../lib/src/middleware/subscription_check_middleware.dart';
import '../lib/src/middleware/auth_guard_middleware.dart';
import '../lib/src/controllers/super_admin_controller.dart';

Future<void> main() async {
  final env = DotEnv(includePlatformEnvironment: true)..load();

  // ─────────────────────────── CENTRAL DATABASE POOL ───────────────────────────
  final centralPool = Pool.withEndpoints([
    Endpoint(
      host: env['CENTRAL_DB_HOST'] ?? 'localhost',
      port: int.parse(env['CENTRAL_DB_PORT'] ?? '5432'),
      database: env['CENTRAL_DB_NAME'] ?? 'platform_management',
      username: env['CENTRAL_DB_USER'] ?? 'postgres',
      password: env['CENTRAL_DB_PASS'] ?? 'postgres',
    ),
  ], settings: const PoolSettings(maxConnectionCount: 20));

  // Postgres Admin endpoint (superuser) for CREATE DATABASE commands
  final postgresAdminEndpoint = Endpoint(
    host: env['CENTRAL_DB_HOST'] ?? 'localhost',
    port: int.parse(env['CENTRAL_DB_PORT'] ?? '5432'),
    database: 'postgres', // Connect to postgres template DB for CREATE DATABASE
    username: env['CENTRAL_DB_USER'] ?? 'postgres',
    password: env['CENTRAL_DB_PASS'] ?? 'postgres',
  );

  // ─────────────────────────── SERVICES ───────────────────────────
  final tenantService = TenantDatabaseService();
  tenantService.initializeCleanupTimer();

  final authService = AuthService(jwtSecret: env['JWT_SECRET'] ?? 'change_me_in_production');

  final provisioningPipeline = ProvisioningPipeline(
    centralPool: centralPool,
    postgresAdminEndpoint: postgresAdminEndpoint,
  );

  // ─────────────────────────── CONTROLLERS ───────────────────────────
  final superAdminController = SuperAdminController(
    centralPool: centralPool,
    authService: authService,
    provisioningPipeline: provisioningPipeline,
  );

  // ─────────────────────────── MIDDLEWARE STACK ───────────────────────────
  final identifyTenantMW = IdentifyTenantMiddleware(centralPool);
  final superAdminAuthMW = authGuardMiddleware(authService: authService, requireSuperAdmin: true);

  // ─────────────────────────── ROUTER ───────────────────────────
  final app = Router();

  // Super Admin routes (protected by Super Admin auth guard)
  app.mount(
    '/api/admin/',
    Pipeline()
        .addMiddleware(superAdminAuthMW)
        .addHandler(superAdminController.router),
  );

  // Tenant-scoped routes (identified by subdomain/header, subscription checked)
  app.all('/<path|.*>', Pipeline()
      .addMiddleware(identifyTenantMW.middleware)
      .addMiddleware(subscriptionCheckMiddleware())
      .addMiddleware(authGuardMiddleware(authService: authService))
      .addHandler(_tenantRequestHandler(tenantService, authService)));

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addHandler(app.call);

  final port = int.parse(env['PORT'] ?? '8080');
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('🚀 Dart Multi-Tenant SaaS Backend running on http://localhost:$port');
  print('📊 Central DB: ${env['CENTRAL_DB_NAME'] ?? 'platform_management'}');

  // Graceful shutdown
  ProcessSignal.sigterm.watch().listen((_) async {
    await tenantService.shutdown();
    await centralPool.close();
    await server.close();
    print('🛑 Server shut down gracefully.');
  });
}

// ─────────────────────────── TENANT REQUEST HANDLER ───────────────────────────
Handler _tenantRequestHandler(TenantDatabaseService tenantService, AuthService authService) {
  return (Request request) async {
    final tenantConfig = request.context['tenantConfig'] as TenantConfig?;

    if (tenantConfig == null) {
      return Response.notFound(
        '{"error": "Tenant context not found"}',
        headers: {'content-type': 'application/json'},
      );
    }

    // Get the tenant-specific DB pool
    final tenantPool = await tenantService.getPoolForTenant(tenantConfig);

    // Handle Tenant Login (no auth required for login route)
    if (request.method == 'POST' && request.url.path.contains('auth/login')) {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final loginResult = await authService.loginTenantUser(
        tenantPool: tenantPool,
        username: body['username'] as String? ?? '',
        password: body['password'] as String? ?? '',
        tenantConfig: tenantConfig,
      );

      if (loginResult == null) {
        return Response.unauthorized(
          '{"error": "Username ama password khalad ah (Invalid credentials)"}',
          headers: {'content-type': 'application/json'},
        );
      }
      return Response.ok(jsonEncode(loginResult), headers: {'content-type': 'application/json'});
    }

    // Example: GET /api/students
    if (request.method == 'GET' && request.url.path.contains('students')) {
      final result = await tenantPool.execute('SELECT * FROM students ORDER BY id DESC');
      final students = result.map((r) => r.toColumnMap()).toList();
      return Response.ok(jsonEncode(students), headers: {'content-type': 'application/json'});
    }

    return Response.notFound(
      '{"error": "Route not found: ${request.url.path}"}',
      headers: {'content-type': 'application/json'},
    );
  };
}

// ─────────────────────────── CORS MIDDLEWARE ───────────────────────────
Middleware _corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final response = await innerHandler(request);
      return response.change(headers: _corsHeaders);
    };
  };
}

final Map<String, String> _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Tenant-Slug, X-School-Slug',
};
