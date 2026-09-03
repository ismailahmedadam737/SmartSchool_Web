// lib/src/middleware/subscription_check_middleware.dart
import 'package:shelf/shelf.dart';
import '../services/tenant_database_service.dart';

Middleware subscriptionCheckMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final tenantConfig = request.context['tenantConfig'] as TenantConfig?;
      final isSuperAdmin = request.context['isSuperAdmin'] == true;

      // Bypass if not tenant-scoped request or if SuperAdmin
      if (tenantConfig == null || isSuperAdmin) {
        return innerHandler(request);
      }

      final subStatus = request.context['subscriptionStatus'] as String?;
      final expiresAt = request.context['subscriptionExpiresAt'] as DateTime?;

      final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());

      if (tenantConfig.status != 'active' || subStatus != 'active' || isExpired) {
        return Response(
          402, // Payment Required
          body: '''{
            "error": "Waqtigii adeegga iskuulkan waa dhacay (Subscription Expired). Fadlan la xiriir Super Admin si aad u kordhiso.",
            "code": "SUBSCRIPTION_EXPIRED",
            "school": "${tenantConfig.name}",
            "expiresAt": "${expiresAt?.toIso8601String() ?? 'N/A'}"
          }''',
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      return innerHandler(request);
    };
  };
}
