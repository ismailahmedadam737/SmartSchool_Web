// lib/src/middleware/identify_tenant_middleware.dart
import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import '../services/tenant_database_service.dart';

class IdentifyTenantMiddleware {
  final Pool centralPool;

  IdentifyTenantMiddleware(this.centralPool);

  Middleware get middleware {
    return (Handler innerHandler) {
      return (Request request) async {
        String? slug;
        final host = request.headers['host'] ?? '';
        final headerSlug = request.headers['x-tenant-slug'] ?? request.headers['x-school-slug'];

        if (headerSlug != null && headerSlug.trim().isNotEmpty) {
          slug = headerSlug.toLowerCase().trim();
        } else if (host.contains('.')) {
          final parts = host.split('.');
          if (parts.length >= 3) {
            slug = parts.first.toLowerCase().trim();
          }
        }

        // Allow central admin or root status routes without tenant slug
        if (request.url.path.startsWith('api/admin/') || slug == null || slug == 'www' || slug == 'api') {
          return innerHandler(request);
        }

        // Query Central DB for Tenant Credentials
        try {
          final result = await centralPool.execute(
            Sql.named('''
              SELECT s.*, sub.status as sub_status, sub.expires_at 
              FROM schools s
              LEFT JOIN school_subscriptions sub ON s.id = sub.school_id
              WHERE LOWER(s.slug) = @slug
            '''),
            parameters: {'slug': slug},
          );

          if (result.isEmpty) {
            return Response.notFound(
              '{"error": "Iskuulka la raadinayo lama helin (Tenant not found for slug: $slug)"}',
              headers: {'content-type': 'application/json'},
            );
          }

          final row = result.first.toColumnMap();
          final config = TenantConfig(
            id: row['id'] as int,
            name: row['name'] as String,
            slug: row['slug'] as String,
            dbHost: row['db_host'] as String,
            dbPort: row['db_port'] as int,
            dbName: row['db_name'] as String,
            dbUsername: row['db_username'] as String,
            dbPassword: row['db_password'] as String,
            status: row['status'] as String,
          );

          // Context Attachment
          final updatedRequest = request.change(
            context: {
              'tenantConfig': config,
              'subscriptionStatus': row['sub_status'] ?? 'active',
              'subscriptionExpiresAt': row['expires_at'],
            },
          );

          return innerHandler(updatedRequest);
        } catch (e) {
          return Response.internalServerError(
            body: '{"error": "Central tenant routing error: ${e.toString()}"}',
            headers: {'content-type': 'application/json'},
          );
        }
      };
    };
  }
}
