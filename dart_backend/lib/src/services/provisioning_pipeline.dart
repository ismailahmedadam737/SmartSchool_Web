// lib/src/services/provisioning_pipeline.dart
import 'dart:async';
import 'package:postgres/postgres.dart';

class ProvisioningPipeline {
  final Pool centralPool;
  final Endpoint postgresAdminEndpoint; // Postgres superuser endpoint

  ProvisioningPipeline({
    required this.centralPool,
    required this.postgresAdminEndpoint,
  });

  Future<Map<String, dynamic>> provisionSchool({
    required String schoolName,
    required String slug,
    required String adminUsername,
    required String adminPassword,
    required String adminEmail,
    required int planId,
    int billingDays = 30,
    double monthlyFee = 50.0,
  }) async {
    final cleanSlug = slug.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    final dbName = 'school_$cleanSlug';
    final expiresAt = DateTime.now().add(Duration(days: billingDays));

    // Step 1: Programmatically create PostgreSQL Database (Must run outside transaction)
    final adminPool = Pool.withEndpoints([postgresAdminEndpoint]);
    try {
      await adminPool.execute('CREATE DATABASE "$dbName"');
      print('✅ Programmatically created database: "$dbName"');
    } catch (e) {
      print('Note: Database "$dbName" creation output: ${e.toString()}');
    } finally {
      await adminPool.close();
    }

    // Step 2: Register Tenant in Central Database
    final centralResult = await centralPool.execute(
      Sql.named('''
        INSERT INTO schools (name, slug, db_host, db_port, db_name, db_username, db_password, status)
        VALUES (@name, @slug, @host, @port, @dbName, @username, @password, 'active')
        RETURNING id
      '''),
      parameters: {
        'name': schoolName,
        'slug': cleanSlug,
        'host': postgresAdminEndpoint.host,
        'port': postgresAdminEndpoint.port,
        'dbName': dbName,
        'username': postgresAdminEndpoint.username,
        'password': postgresAdminEndpoint.password,
      },
    );

    final schoolId = centralResult.first.first as int;

    // Step 3: Record Subscription in Central Database
    await centralPool.execute(
      Sql.named('''
        INSERT INTO school_subscriptions (school_id, plan_id, status, expires_at)
        VALUES (@schoolId, @planId, 'active', @expiresAt)
      '''),
      parameters: {
        'schoolId': schoolId,
        'planId': planId,
        'expiresAt': expiresAt,
      },
    );

    // Step 4: Run Tenant Schema Migrations & Initial Seed Data on Tenant Database
    final tenantEndpoint = Endpoint(
      host: postgresAdminEndpoint.host,
      port: postgresAdminEndpoint.port,
      database: dbName,
      username: postgresAdminEndpoint.username,
      password: postgresAdminEndpoint.password,
    );

    final tenantPool = Pool.withEndpoints([tenantEndpoint]);
    try {
      // Execute Tenant DDL Schema
      await tenantPool.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id SERIAL PRIMARY KEY,
          username VARCHAR(100) NOT NULL UNIQUE,
          email VARCHAR(150),
          password_hash VARCHAR(255) NOT NULL,
          role VARCHAR(30) NOT NULL,
          created_at TIMESTAMPTZ DEFAULT NOW()
        );

        CREATE TABLE IF NOT EXISTS students (
          id SERIAL PRIMARY KEY,
          first_name VARCHAR(50) NOT NULL,
          last_name VARCHAR(50) NOT NULL,
          admission_number VARCHAR(50) UNIQUE NOT NULL,
          grade_level VARCHAR(20),
          created_at TIMESTAMPTZ DEFAULT NOW()
        );

        CREATE TABLE IF NOT EXISTS teachers (
          id SERIAL PRIMARY KEY,
          full_name VARCHAR(100) NOT NULL,
          phone VARCHAR(30),
          subject_specialty VARCHAR(100),
          created_at TIMESTAMPTZ DEFAULT NOW()
        );

        CREATE TABLE IF NOT EXISTS expenses (
          id SERIAL PRIMARY KEY,
          title VARCHAR(150) NOT NULL,
          amount NUMERIC(10, 2) NOT NULL,
          date DATE DEFAULT CURRENT_DATE,
          created_at TIMESTAMPTZ DEFAULT NOW()
        );
      ''');

      // Create Initial School Admin inside Tenant DB
      await tenantPool.execute(
        Sql.named('''
          INSERT INTO users (username, email, password_hash, role)
          VALUES (@username, @email, @password, 'SchoolAdmin')
          ON CONFLICT (username) DO UPDATE SET password_hash = @password
        '''),
        parameters: {
          'username': adminUsername,
          'email': adminEmail,
          'password': adminPassword,
        },
      );

      print('🎉 Tenant "$schoolName" ($cleanSlug) fully provisioned and seeded.');
    } finally {
      await tenantPool.close();
    }

    return {
      'schoolId': schoolId,
      'schoolName': schoolName,
      'slug': cleanSlug,
      'dbName': dbName,
      'adminUsername': adminUsername,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}
