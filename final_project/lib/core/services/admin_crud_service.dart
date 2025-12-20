import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Universal CRUD service for all admin operations
/// Handles Create, Read, Update, Delete for all content types with comprehensive error recovery
class AdminCRUDService {
  static final AdminCRUDService _instance = AdminCRUDService._internal();
  factory AdminCRUDService() => _instance;
  AdminCRUDService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Retry configuration
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 1000);

  /// Classify errors to determine retry strategy
  bool _isRetryableError(dynamic error) {
    if (error is PostgrestException) {
      // Don't retry schema violations, constraint errors, etc.
      final nonRetryableCodes = ['23505', '23503', '42703', '42P01'];
      return !nonRetryableCodes.contains(error.code);
    }

    // Retry network errors, timeouts, etc.
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('socket');
  }

  /// Convert camelCase keys to snake_case for database operations
  Map<String, dynamic> _toSnakeCase(Map<String, dynamic> data) {
    final snakeCaseData = <String, dynamic>{};
    
    for (final entry in data.entries) {
      String key = entry.key;
      
      // Convert common camelCase keys to snake_case
      switch (key) {
        case 'imageUrl':
          key = 'image_url';
          break;
        case 'searchTags':
          key = 'search_tags';
          break;
        case 'restaurantId':
          key = 'restaurant_id';
          break;
        case 'restaurantName':
          key = 'restaurant_name';
          break;
        case 'discountPercentage':
          key = 'discount_percentage';
          break;
        case 'contactNumber':
          key = 'contact_number';
          break;
        case 'sortOrder':
          key = 'sort_order';
          break;
        case 'isFeatured':
          key = 'is_featured';
          break;
        case 'createdAt':
          key = 'created_at';
          break;
        case 'updatedAt':
          key = 'updated_at';
          break;
        // Keep other keys as-is if they're already snake_case or don't need conversion
        default:
          // Convert camelCase to snake_case using regex
          key = key.replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}');
      }
      
      snakeCaseData[key] = entry.value;
    }
    
    return snakeCaseData;
  }

  /// Execute operation with retry logic
  Future<T> _executeWithRetry<T>(
      Future<T> Function() operation, String operationName) async {
    Exception? lastError;

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());

        // Enhanced mobile-specific error logging
        debugPrint('📱 Mobile Debug - $operationName attempt $attempt: $e');
        if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          debugPrint(
              '🌐 Network error detected - check internet connection and Supabase configuration');
        }
        if (e.toString().contains('authentication') ||
            e.toString().contains('unauthorized')) {
          debugPrint(
              '🔐 Authentication error - check Supabase API keys in .env file');
        }

        if (!_isRetryableError(e) || attempt == _maxRetries) {
          debugPrint(
              '❌ $operationName failed permanently after $attempt attempts: $e');
          throw lastError;
        }

        debugPrint(
            '⚠️ $operationName failed (attempt $attempt/$_maxRetries), retrying in ${_retryDelay.inMilliseconds}ms: $e');
        await Future.delayed(_retryDelay * attempt); // Exponential backoff
      }
    }

    throw lastError!;
  }

  /// Lightweight check for authentication only
  bool get isAuthenticated {
    final user = _supabase.auth.currentUser;
    return user != null;
  }

  /// Get current user info for debugging
  Map<String, dynamic>? get currentUserInfo {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    return {
      'id': user.id,
      'email': user.email ?? 'No email',
      'authenticated': true,
    };
  }

  // =============================================
  // GENERIC CRUD OPERATIONS
  // =============================================

  /// Bulletproof restaurant resolution with fallback strategies
  Future<String> _resolveRestaurantIdWithFallback(String value,
      {bool createIfMissing = false}) async {
    try {
      // Check if it's already a UUID
      if (RegExp(
              r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
          .hasMatch(value)) {
        debugPrint('✅ Restaurant value is already UUID: $value');
        return value;
      }

      // Resolve restaurant name to UUID
      final r = await _supabase
          .from('restaurants')
          .select('id')
          .eq('name', value)
          .maybeSingle();

      final resolvedId = r?['id'] as String?;
      if (resolvedId != null) {
        debugPrint('✅ Resolved restaurant "$value" → $resolvedId');
        return resolvedId;
      }

      // Restaurant not found - apply fallback strategy
      debugPrint('⚠️ Restaurant "$value" not found in database');

      if (createIfMissing) {
        // Fallback 1: Create missing restaurant
        debugPrint('🏠 Creating missing restaurant: $value');
        final newRestaurant = await _supabase
            .from('restaurants')
            .insert({
              'name': value,
              'description': 'Auto-created restaurant',
              'address': 'Address not provided',
              'contact_number': '0000000000',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select('id')
            .single();

        final newId = newRestaurant['id'] as String;
        debugPrint('✅ Auto-created restaurant "$value" with ID: $newId');
        return newId;
      } else {
        // Fallback 2: Use default restaurant or throw error
        final defaultRestaurant = await _getDefaultRestaurant();
        if (defaultRestaurant != null) {
          debugPrint('🎯 Using default restaurant: $defaultRestaurant');
          return defaultRestaurant;
        }

        // No fallback available - operation must fail
        throw Exception(
            'Restaurant "$value" not found and no fallback available. Create the restaurant first.');
      }
    } catch (e) {
      debugPrint('❌ Critical error in restaurant resolution: $e');
      rethrow;
    }
  }

  /// Get or create a default restaurant for fallback scenarios
  Future<String?> _getDefaultRestaurant() async {
    try {
      final defaultRestaurants = await _supabase
          .from('restaurants')
          .select('id')
          .eq('name', 'Default Restaurant')
          .limit(1);

      if (defaultRestaurants.isNotEmpty) {
        return defaultRestaurants.first['id'] as String;
      }

      // Create default restaurant if it doesn't exist
      final newDefault = await _supabase
          .from('restaurants')
          .insert({
            'name': 'Default Restaurant',
            'description': 'Default restaurant for system use',
            'address': 'System Default',
            'contact_number': '0000000000',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final defaultId = newDefault['id'] as String;
      debugPrint('🎯 Created new default restaurant: $defaultId');
      return defaultId;
    } catch (e) {
      debugPrint('❌ Failed to get/create default restaurant: $e');
      return null;
    }
  }

  /// Database schema definitions for complete payload sanitization
  static const Map<String, Set<String>> _tableSchemas = {
    'food_items': {
      'id',
      'name',
      'description',
      'price',
      'restaurant_id',
      'image_url',
      'created_at',
      'updated_at'
    },
    'restaurants': {
      'id',
      'name',
      'description',
      'address',
      'contact_number',
      'phone',
      'image_url',
      'rating',
      'created_at',
      'updated_at'
    },
    'deals': {
      'id',
      'title',
      'description',
      'price',
      'discount_percentage',
      'is_featured',
      'image_url',
      'restaurant_id',
      'created_at',
      'updated_at'
    },
    'menu_categories': {
      'id',
      'name',
      'description',
      'image_url',
      'sort_order',
      'created_at',
      'updated_at'
    },
  };

  /// Data type validation and conversion
  dynamic _validateAndConvertType(String key, dynamic value, String table) {
    if (value == null || value == '') return null;

    // Convert string representations to proper types
    switch (key) {
      case 'price':
      case 'rating':
        if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed == null) {
            debugPrint('⚠️ Invalid numeric value for $key: $value');
            return null;
          }
          return parsed;
        }
        return value is num ? value.toDouble() : null;

      case 'discount_percentage':
      case 'sort_order':
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed == null) {
            debugPrint('⚠️ Invalid integer value for $key: $value');
            return null;
          }
          return parsed;
        }
        return value is num ? value.toInt() : null;

      case 'is_featured':
        if (value is String) {
          return value.toLowerCase() == 'true' || value == '1';
        }
        return value is bool ? value : false;

      case 'restaurant_id':
        // Validate UUID format
        final str = value.toString();
        if (!RegExp(
                r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
            .hasMatch(str)) {
          debugPrint('⚠️ Invalid UUID format for $key: $value');
          return null;
        }
        return str;

      default:
        // String fields - trim and validate
        final str = value.toString().trim();
        return str.isEmpty ? null : str;
    }
  }

  /// Comprehensive schema-aware payload sanitization
  Map<String, dynamic> _sanitizePayload(
      Map<String, dynamic> data, String table) {
    final schema = _tableSchemas[table];
    if (schema == null) {
      debugPrint('❌ Unknown table schema: $table');
      return {};
    }

    final clean = <String, dynamic>{};

    // Only include columns that exist in the schema
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (schema.contains(key)) {
        final convertedValue = _validateAndConvertType(key, value, table);
        if (convertedValue != null) {
          clean[key] = convertedValue;
        }
      } else {
        debugPrint('⚠️ Ignoring unknown column for $table: $key');
      }
    }

    debugPrint('✅ Sanitized $table payload: ${clean.keys.join(', ')}');
    return clean;
  }

  /// Generic CREATE operation for any table
  Future<Map<String, dynamic>?> createItem(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      // Work on a mutable copy first
      final original = Map<String, dynamic>.from(data);

      // Convert camelCase to snake_case first
      final snakeCaseData = _toSnakeCase(original);

      // Resolve restaurant name → restaurant_id BEFORE sanitizing (so 'restaurant' isn't dropped)
      if (table == 'food_items' &&
          (snakeCaseData['restaurant'] != null ||
              snakeCaseData['restaurant_name'] != null)) {
        try {
          final restValue =
              (snakeCaseData['restaurant'] ?? snakeCaseData['restaurant_name'])
                  .toString();
          final restaurantId = await _resolveRestaurantIdWithFallback(restValue,
              createIfMissing:
                  true // Auto-create missing restaurants for create operations
              );
          snakeCaseData['restaurant_id'] = restaurantId;
          snakeCaseData.remove('restaurant');
          snakeCaseData.remove('restaurant_name');
          debugPrint(
              '✅ Restaurant resolution successful for food_item creation: $restaurantId');
        } catch (e) {
          debugPrint('❌ CREATE FAILED: Restaurant resolution error: $e');
          throw Exception(
              'Failed to resolve restaurant "${snakeCaseData['restaurant'] ?? snakeCaseData['restaurant_name']}": $e');
        }
      }

      // Now sanitize
      final cleanData = _sanitizePayload(snakeCaseData, table);

      // Add timestamps
      cleanData['created_at'] = DateTime.now().toIso8601String();
      cleanData['updated_at'] = DateTime.now().toIso8601String();

      // Remove null and empty values
      cleanData.removeWhere((key, value) => value == null || value == '');

      debugPrint('🚀 CREATE $table | Keys: ${cleanData.keys.join(', ')}');
      debugPrint('🔍 Payload: $cleanData');

      // Execute database operation with retry logic
      final response = await _executeWithRetry(() async {
        return await _supabase.from(table).insert(cleanData).select().single();
      }, 'CREATE $table');

      debugPrint('✅ CREATE SUCCESS $table | ID: ${response['id']}');
      return response;
    } catch (e) {
      debugPrint('❌ CREATE FAILED $table | Error: $e');

      // Enhanced error logging for mobile debugging
      if (e is PostgrestException) {
        debugPrint(
            'PGERR code=${e.code} message=${e.message} details=${e.details}');
        debugPrint('📱 Mobile Debug - PostgrestException details:');
        debugPrint('   Code: ${e.code}');
        debugPrint('   Message: ${e.message}');
        debugPrint('   Details: ${e.details}');
      } else {
        debugPrint('📱 Mobile Debug - General exception: ${e.runtimeType}');
        debugPrint('   Error: $e');
      }

      // Check for common mobile-specific issues
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('network') ||
          errorString.contains('connection')) {
        debugPrint('🌐 MOBILE ISSUE: Network connectivity problem detected');
        debugPrint(
            '   Solution: Check internet connection and Supabase URL in .env file');
      }
      if (errorString.contains('authentication') ||
          errorString.contains('unauthorized')) {
        debugPrint('🔐 MOBILE ISSUE: Authentication problem detected');
        debugPrint('   Solution: Check Supabase ANON_KEY in .env file');
      }
      if (errorString.contains('timeout')) {
        debugPrint('⏰ MOBILE ISSUE: Request timeout detected');
        debugPrint(
            '   Solution: Check network speed and Supabase service status');
      }

      return null;
    }
  }

  /// Generic READ operations for any table
  Future<List<Map<String, dynamic>>> getAllItems(
    String table, {
    String? orderBy,
    bool ascending = true,
  }) async {
    try {
      if (orderBy != null) {
        final response = await _supabase
            .from(table)
            .select()
            .order(orderBy, ascending: ascending);
        // Filter out null entries to prevent crashes
        return List<Map<String, dynamic>>.from(response)
            .where((item) => item != null)
            .toList();
      } else {
        final response = await _supabase.from(table).select();
        // Filter out null entries to prevent crashes
        return List<Map<String, dynamic>>.from(response)
            .where((item) => item != null)
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching $table items: $e');
      return [];
    }
  }

  /// Generic UPDATE operation for any table
  Future<bool> updateItem(
    String table,
    dynamic itemId,
    Map<String, dynamic> data, {
    String idColumn = 'id',
  }) async {
    try {
      // Work on a mutable copy first
      final original = Map<String, dynamic>.from(data);

      // Convert camelCase to snake_case first
      final snakeCaseData = _toSnakeCase(original);

      // Resolve restaurant name → restaurant_id BEFORE sanitizing (so 'restaurant' isn't dropped)
      if (table == 'food_items' &&
          (snakeCaseData['restaurant'] != null ||
              snakeCaseData['restaurant_name'] != null)) {
        try {
          final restValue =
              (snakeCaseData['restaurant'] ?? snakeCaseData['restaurant_name'])
                  .toString();
          final restaurantId = await _resolveRestaurantIdWithFallback(restValue,
              createIfMissing:
                  false // Don't auto-create for updates, use fallback
              );
          snakeCaseData['restaurant_id'] = restaurantId;
          snakeCaseData.remove('restaurant');
          snakeCaseData.remove('restaurant_name');
          debugPrint(
              '✅ Restaurant resolution successful for food_item update: $restaurantId');
        } catch (e) {
          debugPrint('❌ UPDATE FAILED: Restaurant resolution error: $e');
          throw Exception(
              'Failed to resolve restaurant "${snakeCaseData['restaurant'] ?? snakeCaseData['restaurant_name']}": $e');
        }
      }

      // Now sanitize
      final cleanData = _sanitizePayload(snakeCaseData, table);

      // Add timestamp
      cleanData['updated_at'] = DateTime.now().toIso8601String();

      // Remove null values
      cleanData.removeWhere((key, value) => value == null);

      debugPrint(
          '🔄 UPDATE $table | ID: $itemId | Keys: ${cleanData.keys.join(', ')}');
      debugPrint('🔍 Payload: $cleanData');

      // Execute database operation with retry logic
      await _executeWithRetry(() async {
        await _supabase.from(table).update(cleanData).eq(idColumn, itemId);
      }, 'UPDATE $table ID: $itemId');

      debugPrint('✅ UPDATE SUCCESS $table | ID: $itemId');
      return true;
    } catch (e) {
      debugPrint('❌ UPDATE FAILED $table | ID: $itemId | Error: $e');

      // Enhanced error logging
      if (e is PostgrestException) {
        debugPrint(
            'PGERR code=${e.code} message=${e.message} details=${e.details}');
      }

      return false;
    }
  }

  /// Generic DELETE operation for any table
  Future<bool> deleteItem(
    String table,
    dynamic itemId, {
    String idColumn = 'id',
  }) async {
    try {
      await _supabase.from(table).delete().eq(idColumn, itemId);

      debugPrint('Successfully deleted $table item $itemId');
      return true;
    } catch (e) {
      debugPrint('Error deleting $table item: $e');
      return false;
    }
  }

  /// Fallback update method without image fields
  Future<bool> _updateWithoutImages(
    String table,
    dynamic itemId,
    Map<String, dynamic> originalData,
    String idColumn,
  ) async {
    try {
      final dataWithoutImages = Map<String, dynamic>.from(originalData);
      dataWithoutImages.remove('image_url');
      dataWithoutImages.remove('imageUrl');
      dataWithoutImages['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from(table)
          .update(dataWithoutImages)
          .eq(idColumn, itemId);

      debugPrint(
          'Fallback update successful for $table item $itemId (without images)');
      return true;
    } catch (e) {
      debugPrint('Fallback update also failed for $table item $itemId: $e');
      return false;
    }
  }

  // =============================================
  // SPECIALIZED FOOD ITEMS OPERATIONS
  // =============================================

  /// Get food items with restaurant names via JOIN query
  Future<List<Map<String, dynamic>>> getFoodItems() async {
    try {
      debugPrint('🍔 Loading food items with restaurant data...');

      // Use JOIN query to get restaurant names with food items
      final response = await _executeWithRetry(() async {
        return await _supabase.from('food_items').select('''
                id,
                name,
                description,
                price,
                image_url,
                created_at,
                updated_at,
                restaurant_id,
                restaurants!food_items_restaurant_id_fkey(
                  id,
                  name
                )
              ''').order('name');
      }, 'getFoodItems with restaurant JOIN');

      // Transform the response to flatten restaurant data
      final transformedItems = response.map<Map<String, dynamic>>((item) {
        final restaurant = item['restaurants'];
        return {
          'id': item['id'],
          'name': item['name'],
          'description': item['description'],
          'price': item['price'],
          'image_url': item['image_url'],
          'created_at': item['created_at'],
          'updated_at': item['updated_at'],
          'restaurant_id': item['restaurant_id'],
          'restaurant_name': restaurant?['name'] ?? 'Unknown Restaurant',
        };
      }).toList();

      debugPrint(
          '✅ Loaded ${transformedItems.length} food items with restaurant data');
      debugPrint(
          '🔍 Sample item: ${transformedItems.isNotEmpty ? transformedItems.first : "No items"}');

      return transformedItems;
    } catch (e) {
      debugPrint('❌ getFoodItems failed: $e');

      // Fallback to simple query without JOIN if JOIN fails
      debugPrint('🔄 Falling back to simple food items query...');
      try {
        final fallbackResponse =
            await getAllItems('food_items', orderBy: 'name');
        debugPrint(
            '⚠️ Using fallback query, restaurant names will show as "Unknown Restaurant"');
        return fallbackResponse;
      } catch (fallbackError) {
        debugPrint('❌ Fallback query also failed: $fallbackError');
        return [];
      }
    }
  }

  Future<Map<String, dynamic>?> createFoodItem({
    required String name,
    required String description,
    required double price,
    required String restaurant,
    String? imageUrl,
  }) async {
    debugPrint('\n🍔 =================');
    debugPrint('🍔 CREATING FOOD ITEM');
    debugPrint('🍔 =================');
    debugPrint('🍔 Name: $name');
    debugPrint('🍔 Restaurant: $restaurant');
    debugPrint('🍔 Description: $description');
    debugPrint('🍔 Price: $price');
    debugPrint('🍔 Image URL: ${imageUrl ?? "None"}');
    debugPrint('🍔 =================\n');

    try {
      // Pre-validation checks
      if (name.trim().isEmpty) {
        throw Exception('Food item name cannot be empty');
      }
      if (description.trim().isEmpty) {
        throw Exception('Food item description cannot be empty');
      }
      if (price <= 0) {
        throw Exception('Food item price must be greater than 0');
      }
      if (restaurant.trim().isEmpty) {
        throw Exception('Restaurant name cannot be empty');
      }

      // Check if restaurant exists first
      debugPrint('🏠 Checking if restaurant "$restaurant" exists...');
      final restaurantCheck = await _supabase
          .from('restaurants')
          .select('id, name')
          .eq('name', restaurant)
          .maybeSingle();
      
      if (restaurantCheck == null) {
        debugPrint('⚠️ Restaurant "$restaurant" not found, will auto-create');
      } else {
        debugPrint('✅ Restaurant found: ${restaurantCheck['name']} (${restaurantCheck['id']})');
      }

      final payload = <String, dynamic>{
        'name': name.trim(),
        'description': description.trim(),
        'price': price,
        'restaurant': restaurant.trim(), // Will be resolved to restaurant_id in createItem
      };

      if (imageUrl != null && imageUrl.isNotEmpty) {
        payload['image_url'] = imageUrl;
      }

      debugPrint('🚀 Calling createItem with payload: $payload');
      final result = await createItem('food_items', payload);
      
      if (result != null) {
        debugPrint('✅ Food item created successfully: ${result['id']}');
      } else {
        debugPrint('❌ Food item creation returned null');
      }
      
      return result;
    } catch (e) {
      debugPrint('❌ FOOD ITEM CREATION FAILED');
      debugPrint('❌ Error Type: ${e.runtimeType}');
      debugPrint('❌ Error Message: $e');
      
      // Enhanced error analysis
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('restaurant')) {
        debugPrint('🏠 Restaurant-related error detected');
      }
      if (errorString.contains('price')) {
        debugPrint('💰 Price-related error detected');
      }
      if (errorString.contains('foreign key')) {
        debugPrint('🔗 Foreign key constraint error detected');
      }
      
      rethrow;
    }
  }

  Future<bool> updateFoodItem(dynamic itemId, Map<String, dynamic> data) async {
    debugPrint(
        '🍔 updateFoodItem called | ID: $itemId | Data keys: ${data.keys.join(', ')}');

    // Use generic updateItem with proper id column (no more name-based updates)
    return updateItem('food_items', itemId, data, idColumn: 'id');
  }

  Future<bool> deleteFoodItem(dynamic itemId) async {
    debugPrint('🍔 deleteFoodItem called | ID: $itemId');

    // Use generic deleteItem with proper id column (no more name-based deletes)
    return deleteItem('food_items', itemId, idColumn: 'id');
  }

  // =============================================
  // SPECIALIZED DEALS OPERATIONS
  // =============================================

  Future<List<Map<String, dynamic>>> getDeals() async {
    return getAllItems('deals', orderBy: 'created_at', ascending: false);
  }

  Future<Map<String, dynamic>?> createDeal({
    required String title,
    required String description,
    required double price,
    int? discountPercentage,
    bool? isFeatured,
    String? imageUrl,
    List<String>? imageUrls,
    String? restaurantId,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'description': description,
      'price': price,
      'is_featured': isFeatured ?? false,
    };

    if (discountPercentage != null) {
      payload['discount_percentage'] = discountPercentage;
    }
    
    // Handle multiple images with fallback to single image
    if (imageUrls != null && imageUrls.isNotEmpty) {
      payload['image_urls'] = imageUrls;
      payload['image_url'] = imageUrls.first; // Primary image for backward compatibility
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      payload['image_url'] = imageUrl;
      payload['image_urls'] = [imageUrl]; // Convert single image to array for consistency
    }
    
    if (restaurantId != null) {
      payload['restaurant_id'] = restaurantId;
    }

    return createItem('deals', payload);
  }

  Future<bool> updateDeal(String dealId, Map<String, dynamic> data) async {
    return updateItem('deals', dealId, data);
  }

  Future<bool> deleteDeal(String dealId) async {
    return deleteItem('deals', dealId);
  }

  // =============================================
  // SPECIALIZED RESTAURANTS OPERATIONS
  // =============================================

  Future<List<Map<String, dynamic>>> getRestaurants() async {
    return getAllItems('restaurants', orderBy: 'name');
  }

  Future<Map<String, dynamic>?> createRestaurant({
    required String name,
    required String description,
    required String address,
    required String contactNumber,
    String? phone,
    String? imageUrl,
    double? rating,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'description': description,
      'address': address,
      'contact_number': contactNumber,
    };

    if (phone != null && phone.isNotEmpty) {
      payload['phone'] = phone;
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      payload['image_url'] = imageUrl;
    }
    if (rating != null) {
      payload['rating'] = rating;
    }

    return createItem('restaurants', payload);
  }

  Future<bool> updateRestaurant(
      String restaurantId, Map<String, dynamic> data) async {
    return updateItem('restaurants', restaurantId, data);
  }

  Future<bool> deleteRestaurant(String restaurantId) async {
    return deleteItem('restaurants', restaurantId);
  }

  // =============================================
  // SPECIALIZED MENU CATEGORIES OPERATIONS
  // =============================================

  Future<List<Map<String, dynamic>>> getMenuCategories() async {
    return getAllItems('menu_categories', orderBy: 'sort_order');
  }

  Future<Map<String, dynamic>?> createMenuCategory({
    required String name,
    required String description,
    String? imageUrl,
    int? sortOrder,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'description': description,
    };

    if (imageUrl != null && imageUrl.isNotEmpty) {
      payload['image_url'] = imageUrl;
    }
    if (sortOrder != null) {
      payload['sort_order'] = sortOrder;
    }

    return createItem('menu_categories', payload);
  }

  Future<bool> updateMenuCategory(
      String categoryId, Map<String, dynamic> data) async {
    return updateItem('menu_categories', categoryId, data);
  }

  Future<bool> deleteMenuCategory(String categoryId) async {
    return deleteItem('menu_categories', categoryId);
  }

  // =============================================
  // SEARCH AND FILTER OPERATIONS
  // =============================================

  /// Search items in any table by text query
  Future<List<Map<String, dynamic>>> searchItems(
    String table,
    String query, {
    List<String> searchColumns = const ['name', 'description'],
  }) async {
    try {
      if (query.isEmpty) {
        return getAllItems(table);
      }

      // Build search condition for multiple columns
      String searchCondition =
          searchColumns.map((column) => '$column.ilike.%$query%').join(',');

      final response = await _supabase.from(table).select().or(searchCondition);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error searching $table: $e');
      return [];
    }
  }

  /// Get items by specific field value
  Future<List<Map<String, dynamic>>> getItemsByField(
    String table,
    String fieldName,
    dynamic fieldValue,
  ) async {
    try {
      final response =
          await _supabase.from(table).select().eq(fieldName, fieldValue);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error filtering $table by $fieldName: $e');
      return [];
    }
  }

  // =============================================
  // UTILITY METHODS
  // =============================================

  /// Get single item by ID from any table
  Future<Map<String, dynamic>?> getItemById(
    String table,
    dynamic itemId, {
    String idColumn = 'id',
  }) async {
    try {
      final response = await _supabase
          .from(table)
          .select()
          .eq(idColumn, itemId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error getting $table item by ID: $e');
      return null;
    }
  }

  /// Check if item exists in table
  Future<bool> itemExists(
    String table,
    String fieldName,
    dynamic value,
  ) async {
    try {
      final response = await _supabase
          .from(table)
          .select('id')
          .eq(fieldName, value)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking if $table item exists: $e');
      return false;
    }
  }

  /// Get count of items in table
  Future<int> getItemCount(String table) async {
    try {
      final response = await _supabase.from(table).select('id');

      return response.length;
    } catch (e) {
      debugPrint('Error getting count for $table: $e');
      return 0;
    }
  }
}
