// lib/src/middleware/auth_guard_middleware.dart
import 'package:shelf/shelf.dart';
import '../services/auth_service.dart';

/// Middleware that validates JWT tokens and attaches user context to requests
Middleware authGuardMiddleware({
  required AuthService authService,
  bool requireSuperAdmin = false,
}) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'] ?? '';

      if (!authHeader.startsWith('Bearer ')) {
        return Response.unauthorized(
          '{"error": "Token la\'aanta - fadlan gal nidaamka (Unauthorized)"}',
          headers: {'content-type': 'application/json'},
        );
      }

      final token = authHeader.substring(7);
      final payload = authService.verifyToken(token);

      if (payload == null) {
        return Response.forbidden(
          '{"error": "Token-ku waa been ama waqtigiisii waa dhacay (Invalid or Expired Token)"}',
          headers: {'content-type': 'application/json'},
        );
      }

      // Enforce Super Admin restriction if required
      if (requireSuperAdmin && payload['isSuperAdmin'] != true) {
        return Response.forbidden(
          '{"error": "Amar kani waxaa kaliya geli kara Super Admin (Super Admin access required)"}',
          headers: {'content-type': 'application/json'},
        );
      }

      // Validate tenant slug scoping: ensure the JWT tenant matches the current tenant context
      final jwtTenantSlug = payload['tenantSlug'] as String?;
      final requestTenantSlug = (request.context['tenantConfig'] as dynamic)?.slug as String?;
      final isSuperAdmin = payload['isSuperAdmin'] == true;

      if (!isSuperAdmin &&
          requestTenantSlug != null &&
          jwtTenantSlug != null &&
          jwtTenantSlug != requestTenantSlug) {
        return Response.forbidden(
          '{"error": "Ma geli kartid macluumaadka iskuul kale (Cross-tenant access denied)"}',
          headers: {'content-type': 'application/json'},
        );
      }

      // Attach JWT payload to request context
      final updatedRequest = request.change(
        context: {
          ...request.context,
          'currentUser': payload,
          'isSuperAdmin': isSuperAdmin,
          'isImpersonating': payload['isImpersonating'] == true,
        },
      );

      return innerHandler(updatedRequest);
    };
  };
}
