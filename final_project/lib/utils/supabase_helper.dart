import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseHelper {
  // Using the URL from mcp.json
  static const String supabaseUrl = 'https://xfvbgpybpjumgdvfuidk.supabase.co';
  // Updated API key provided by the user
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhmdmJncHlicGp1bWdkdmZ1aWRrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMzMDg4NzYsImV4cCI6MjA1ODg4NDg3Nn0.733PF37TcZDhza5PINnn78B21UWZ_el_4U_IKQW8iLk';

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: true, // Enable debug mode to see more logs
      );
      debugPrint('Supabase initialization successful');
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  // Test basic connection
  static Future<bool> testConnection() async {
    try {
      // Try getting the list of tables
      final result = await client.rpc('get_schema_info');
      debugPrint('Schema info: $result');
      return true;
    } catch (e) {
      debugPrint('RPC method failed: $e');

      try {
        // Try using an SQL query to list tables
        final result = await client.rpc('execute_sql', params: {
          'query':
              "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"
        });
        debugPrint('SQL query result: $result');
        return true;
      } catch (e2) {
        debugPrint('SQL query failed: $e2');

        try {
          // Try checking if Supabase client is initialized
          final currentUser = client.auth.currentUser;
          debugPrint('Current user: ${currentUser != null}');
          return true;
        } catch (e3) {
          debugPrint('Auth check failed: $e3');
          return false;
        }
      }
    }
  }

  // Get all tables in the database
  static Future<List<String>> listTables() async {
    final tables = <String>[];

    try {
      // Try a different method by calling a custom function
      final response = await client.functions.invoke('list-tables');
      if (response.status == 200 && response.data != null) {
        final data = response.data as List<dynamic>;
        for (var item in data) {
          if (item is Map<String, dynamic> && item.containsKey('table_name')) {
            tables.add(item['table_name'] as String);
          }
        }
      }
    } catch (e) {
      debugPrint('Error listing tables via Edge Function: $e');

      // Since we don't have direct SQL access, let's check some common tables
      // that might exist in your Supabase project
      final commonTables = [
        'users',
        'profiles',
        'auth_users',
        'customers',
        'products',
        'orders',
        'items',
        'restaurants',
        'categories',
        'menus',
        'foods',
        'deals'
      ];

      for (final tableName in commonTables) {
        try {
          // Try to get count from each table
          final count = await client.from(tableName).count();
          debugPrint('Table $tableName exists with count: $count');
          tables.add(tableName);
        } catch (e) {
          // Table doesn't exist or can't be accessed, skip
        }
      }
    }

    return tables;
  }

  // Helper function to create the get_tables function in Supabase if it doesn't exist
  static Future<void> createGetTablesFunction() async {
    try {
      // This SQL creates a function that returns all tables in a schema
      const functionSql = '''
      CREATE OR REPLACE FUNCTION get_tables(schema_name text)
      RETURNS TABLE (table_name text) 
      LANGUAGE plpgsql
      AS \$\$
      BEGIN
        RETURN QUERY 
        SELECT information_schema.tables.table_name::text
        FROM information_schema.tables
        WHERE table_schema = schema_name;
      END;
      \$\$;
      ''';

      await client.rpc('exec_sql', params: {'sql': functionSql});
      return;
    } catch (e) {
      debugPrint('Error creating function: $e');
      return;
    }
  }

  // Simpler approach to get tables using direct SQL
  static Future<List<Map<String, dynamic>>> getTablesSimple() async {
    try {
      final response =
          await client.from('_metadata').select('*').eq('type', 'table');

      return response;
    } catch (e) {
      debugPrint('Error fetching tables simple: $e');

      // Try another approach
      try {
        final response = await client.rpc('query', params: {
          'query_text':
              'SELECT table_name FROM information_schema.tables WHERE table_schema = \'public\''
        });
        return response;
      } catch (e2) {
        debugPrint('Error with second approach: $e2');
        return [];
      }
    }
  }
}
