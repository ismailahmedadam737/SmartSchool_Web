// lib/src/controllers/super_admin_controller.dart
import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';
import '../services/provisioning_pipeline.dart';

class SuperAdminController {
  final Pool centralPool;
  final AuthService authService;
  final ProvisioningPipeline provisioningPipeline;

  SuperAdminController({
    required this.centralPool,
    required this.authService,
    required this.provisioningPipeline,
  });

  Router get router {
    final r = Router();

    // ──────────── POST /api/admin/login ────────────
    r.post('/admin/login', _login);

    // ──────────── GET /api/admin/metrics ────────────
    r.get('/admin/metrics', _getMetrics);

    // ──────────── GET /api/admin/schools ────────────
    r.get('/admin/schools', _listSchools);

    // ──────────── POST /api/admin/schools ────────────
    r.post('/admin/schools', _provisionSchool);

    // ──────────── PATCH /api/admin/schools/<id>/status ────────────
    r.patch('/admin/schools/<id>/status', _updateSchoolStatus);

    // ──────────── POST /api/admin/schools/<id>/renew ────────────
    r.post('/admin/schools/<id>/renew', _renewSubscription);

    // ──────────── POST /api/admin/schools/<id>/impersonate ────────────
    r.post('/admin/schools/<id>/impersonate', _impersonateSchool);

    // ──────────── DELETE /api/admin/schools/<id> ────────────
    r.delete('/admin/schools/<id>', _deleteSchool);

    return r;
  }

  // ─────────────────────────── HANDLERS ───────────────────────────

  Future<Response> _login(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final email = body['email'] as String? ?? '';
      final password = body['password'] as String? ?? '';

      final result = await authService.loginSuperAdmin(
        centralPool: centralPool,
        email: email,
        password: password,
      );

      if (result == null) {
        return Response.unauthorized(
          '{"error": "Email ama password khalad ah (Invalid credentials)"}',
          headers: {'content-type': 'application/json'},
        );
      }

      return Response.ok(jsonEncode(result), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: '{"error": "${e.toString()}"}', headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _getMetrics(Request request) async {
    try {
      final result = await centralPool.execute('''
        SELECT
          COUNT(*) AS total_schools,
          COUNT(CASE WHEN s.status = 'active' THEN 1 END) AS active_schools,
          COUNT(CASE WHEN s.status = 'suspended' THEN 1 END) AS suspended_schools,
          COUNT(CASE WHEN sub.expires_at < NOW() THEN 1 END) AS expired_schools,
          COALESCE(SUM(CASE WHEN sub.status = 'active' THEN sub.monthly_fee END), 0) AS estimated_mrr
        FROM schools s
        LEFT JOIN school_subscriptions sub ON s.id = sub.school_id
      ''');

      final row = result.first.toColumnMap();
      return Response.ok(
        jsonEncode({
          'totalSchools': int.parse(row['total_schools'].toString()),
          'activeSchools': int.parse(row['active_schools'].toString()),
          'suspendedSchools': int.parse(row['suspended_schools'].toString()),
          'expiredSchools': int.parse(row['expired_schools'].toString()),
          'estimatedMrr': double.parse(row['estimated_mrr'].toString()),
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: '{"error": "${e.toString()}"}', headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _listSchools(Request request) async {
    try {
      final result = await centralPool.execute('''
        SELECT s.id, s.name, s.slug, s.db_name, s.status, s.created_at,
               sub.status AS sub_status, sub.expires_at, sp.monthly_price
        FROM schools s
        LEFT JOIN school_subscriptions sub ON s.id = sub.school_id
        LEFT JOIN subscription_plans sp ON sub.plan_id = sp.id
        ORDER BY s.id DESC
      ''');

      final schools = result.map((row) => row.toColumnMap()).toList();
      return Response.ok(jsonEncode(schools), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: '{"error": "${e.toString()}"}', headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _provisionSchool(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final result = await provisioningPipeline.provisionSchool(
        schoolName: body['name'] as String,
        slug: body['slug'] as String,
        adminUsername: body['admin_username'] as String,
        adminPassword: body['admin_password'] as String,
        adminEmail: body['admin_email'] as String? ?? '',
        planId: body['plan_id'] as int? ?? 1,
        billingDays: body['billing_days'] as int? ?? 30,
        monthlyFee: double.tryParse(body['monthly_fee'].toString()) ?? 50.0,
      );

      return Response(201, body: jsonEncode(result), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: '{"error": "Provisioning failed: ${e.toString()}"}', headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _updateSchoolStatus(Request request, String id) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final status = body['status'] as String;

      await centralPool.execute(
        Sql.named('UPDATE schools SET status = @status WHERE id = @id'),
        parameters: {'status': status, 'id': int.parse(id)},
      );

      return Response.ok('{"message": "Status updated to $status"}', headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: '{"error": "${e.toString()}"}', headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _renewSubscription(Request request, String id) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final days = body['days'] as int? ?? 30;

      await centralPool.execute(
        Sql.named('''
          UPDATE school_subscriptions
          SET status = 'active',
              expires_at = GREATEST(expires_at, NOW()) + INTERVAL '$days days'
          WHERE school_id = @id
        '''),
        parameters: {'id': int.parse(id)},
      );

      await centralPool.execute(
        Sql.named("UPDATE schools SET status = 'active' WHERE id = @id"),
        parameters: {'id': int.parse(id)},
      );

      return Response.ok('{"message": "Subscription renewed for $days days"}', headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: '{"error": "${e.toString()}"}', headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _impersonateSchool(Request request, String id) async {
    try {
      final schoolResult = await centralPool.execute(
        Sql.named('SELECT name, slug FROM schools WHERE id = @id'),
        parameters: {'id': int.parse(id)},
      );

      if (schoolResult.isEmpty) {
        return Response.notFound('{"error": "School not found"}', headers: {'content-type': 'application/json'});
      }

      final row = schoolResult.first.toColumnMap();
      final currentUser = request.context['currentUser'] as Map<String, dynamic>? ?? {};

      final token = authService.generateImpersonationToken(
        superAdminEmail: currentUser['username'] as String? ?? 'superadmin',
        targetSlug: row['slug'] as String,
        targetSchoolName: row['name'] as String,
      );

      return Response.ok(
        jsonEncode({
          'token': token,
          'schoolSlug': row['slug'],
          'schoolName': row['name'],
          'isImpersonating': true,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: '{"error": "${e.toString()}"}', headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _deleteSchool(Request request, String id) async {
    try {
      await centralPool.execute(
        Sql.named('DELETE FROM schools WHERE id = @id'),
        parameters: {'id': int.parse(id)},
      );
      return Response.ok('{"message": "School system deleted permanently"}', headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: '{"error": "${e.toString()}"}', headers: {'content-type': 'application/json'});
    }
  }
}
