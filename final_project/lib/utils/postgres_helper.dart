import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';

class PostgresHelper {
  // Connection string from MCP config
  static const String connectionString =
      'postgresql://postgres.xfvbgpybpjumgdvfuidk:AnsAsghar777@aws-0-ap-south-1.pooler.supabase.com:5432/postgres';

  static Future<bool> testConnection() async {
    try {
      // Parse the connection string
      final Uri uri =
          Uri.parse(connectionString.replaceFirst('postgresql://', 'http://'));
      final userInfo = uri.userInfo.split(':');

      final endpoint = Endpoint(
        host: uri.host,
        port: uri.port,
        database: uri.path.substring(1), // Remove leading slash
        username: userInfo[0],
        password: userInfo[1],
      );

      final connection = await Connection.open(endpoint);
      debugPrint('PostgreSQL connection successful');

      // Test query
      final result = await connection.execute('SELECT current_timestamp');
      debugPrint('Query result: $result');

      await connection.close();
      return true;
    } catch (e) {
      debugPrint('PostgreSQL connection failed: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> listTables() async {
    try {
      // Parse the connection string
      final Uri uri =
          Uri.parse(connectionString.replaceFirst('postgresql://', 'http://'));
      final userInfo = uri.userInfo.split(':');

      final endpoint = Endpoint(
        host: uri.host,
        port: uri.port,
        database: uri.path.substring(1), // Remove leading slash
        username: userInfo[0],
        password: userInfo[1],
      );

      final connection = await Connection.open(endpoint);

      final results = await connection.execute(
        'SELECT table_name FROM information_schema.tables WHERE table_schema = @schema',
        parameters: {'schema': 'public'},
      );

      await connection.close();

      // Convert to a simpler format
      final tables = <Map<String, dynamic>>[];
      for (final row in results) {
        tables.add({'table_name': row[0]});
      }

      return tables;
    } catch (e) {
      debugPrint('Error listing tables: $e');
      return [];
    }
  }
}
