import 'dart:async';
import 'package:flutter/material.dart';
import 'supabase_helper.dart';
import 'postgres_helper.dart';

class SupabaseTest {
  static Future<void> testConnection() async {
    try {
      // Initialize Supabase
      await SupabaseHelper.initialize();

      // Test Supabase REST API connection
      final isSupabaseConnected = await SupabaseHelper.testConnection();
      debugPrint('Supabase REST API connected: $isSupabaseConnected');

      // Test PostgreSQL direct connection
      final isPostgresConnected = await PostgresHelper.testConnection();
      debugPrint('PostgreSQL direct connection: $isPostgresConnected');

      if (isSupabaseConnected) {
        // List tables using Supabase REST API
        final tables = await SupabaseHelper.listTables();
        debugPrint('Tables via Supabase REST API: $tables');
      }
    } catch (e) {
      debugPrint('Error testing connections: $e');
    }
  }
}
