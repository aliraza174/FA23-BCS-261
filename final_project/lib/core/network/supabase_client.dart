import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
import '../error/failures.dart';
import 'package:dartz/dartz.dart';

class SupabaseClientWrapper {
  static SupabaseClientWrapper? _instance;
  late final SupabaseClient _client;

  SupabaseClientWrapper._() {
    _client = Supabase.instance.client;
  }

  static Future<Either<Failure, SupabaseClientWrapper>> initialize() async {
    if (_instance != null) {
      return Right(_instance!);
    }

    try {
      if (!Env.isValid) {
        return const Left(ValidationFailure('Invalid environment configuration'));
      }

      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
      );

      _instance = SupabaseClientWrapper._();
      return Right(_instance!);
    } catch (e) {
      return Left(
          ServerFailure('Failed to initialize Supabase: ${e.toString()}'));
    }
  }

  static SupabaseClientWrapper get instance {
    if (_instance == null) {
      throw StateError(
          'SupabaseClient not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  GoTrueClient get auth => _client.auth;
  SupabaseClient get client => _client;
  SupabaseStorageClient get storage => _client.storage;
}
