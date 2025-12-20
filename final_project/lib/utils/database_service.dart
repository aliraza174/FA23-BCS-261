import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'dataset_parser.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatasetParser _datasetParser = DatasetParser();

  // Restaurant Operations
  Future<List<Map<String, dynamic>>> getRestaurants() async {
    try {
      final response =
          await _supabase.from('restaurants').select().order('name');

      final List<Map<String, dynamic>> restaurants =
          List<Map<String, dynamic>>.from(response);

      // If no restaurants are returned, use the dataset parser
      if (restaurants.isEmpty) {
        final datasetData = await _datasetParser.loadDataset();
        return datasetData['restaurants'] as List<Map<String, dynamic>>;
      }

      return restaurants;
    } catch (e) {
      print('Error fetching restaurants: $e');

      // Fallback to dataset parser on error
      try {
        final datasetData = await _datasetParser.loadDataset();
        return datasetData['restaurants'] as List<Map<String, dynamic>>;
      } catch (parserError) {
        print('Error using dataset parser: $parserError');
        return [];
      }
    }
  }

  Future<Map<String, dynamic>?> getRestaurantById(String id) async {
    try {
      final response =
          await _supabase.from('restaurants').select().eq('id', id).single();

      return response;
    } catch (e) {
      print('Error fetching restaurant: $e');

      // Fallback to dataset parser
      try {
        final datasetData = await _datasetParser.loadDataset();
        final restaurants =
            datasetData['restaurants'] as List<Map<String, dynamic>>;
        return restaurants.firstWhere((r) => r['id'] == id, orElse: () => {});
      } catch (parserError) {
        print('Error using dataset parser: $parserError');
        return null;
      }
    }
  }

  // Deals Operations
  Future<List<Map<String, dynamic>>> getDeals() async {
    try {
      final response = await _supabase
          .from('deals')
          .select('*, restaurants:restaurant_id(name)')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> deals =
          List<Map<String, dynamic>>.from(response);

      // If no deals are returned, use the dataset parser
      if (deals.isEmpty) {
        final datasetData = await _datasetParser.loadDataset();
        return datasetData['deals'] as List<Map<String, dynamic>>;
      }

      return deals;
    } catch (e) {
      print('Error fetching deals: $e');

      // Fallback to dataset parser on error
      try {
        final datasetData = await _datasetParser.loadDataset();
        return datasetData['deals'] as List<Map<String, dynamic>>;
      } catch (parserError) {
        print('Error using dataset parser: $parserError');
        return [];
      }
    }
  }

  Future<Map<String, dynamic>?> getDealById(String id) async {
    try {
      final response = await _supabase
          .from('deals')
          .select('*, restaurants:restaurant_id(name)')
          .eq('id', id)
          .single();

      return response;
    } catch (e) {
      print('Error fetching deal: $e');

      // Fallback to dataset parser
      try {
        final datasetData = await _datasetParser.loadDataset();
        final deals = datasetData['deals'] as List<Map<String, dynamic>>;
        return deals.firstWhere((d) => d['id'] == id, orElse: () => {});
      } catch (parserError) {
        print('Error using dataset parser: $parserError');
        return null;
      }
    }
  }

  // Menu Images Operations
  Future<List<Map<String, dynamic>>> getMenuImages() async {
    try {
      final response = await _supabase
          .from('menu_images')
          .select()
          .order('created_at', ascending: false);

      // Return raw JSON data to handle null values gracefully
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching menu images: $e');
      return []; // Return empty list instead of throwing
    }
  }

  // Eatables Operations
  Future<List<Map<String, dynamic>>> getEatables() async {
    try {
      final response = await _supabase
          .from('food_items')
          .select('*, restaurants:restaurant_id(name)')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> eatables =
          List<Map<String, dynamic>>.from(response);

      // If no eatables are returned, use the dataset parser
      if (eatables.isEmpty) {
        final datasetData = await _datasetParser.loadDataset();
        return datasetData['menuItems'] as List<Map<String, dynamic>>;
      }

      return eatables;
    } catch (e) {
      print('Error fetching eatables: $e');

      // Fallback to dataset parser on error
      try {
        final datasetData = await _datasetParser.loadDataset();
        return datasetData['menuItems'] as List<Map<String, dynamic>>;
      } catch (parserError) {
        print('Error using dataset parser: $parserError');
        return [];
      }
    }
  }

  // AI Settings Operations
  Future<Map<String, dynamic>?> getAISettings() async {
    try {
      final response = await _supabase.from('ai_settings').select().single();

      return response;
    } catch (e) {
      print('Error fetching AI settings: $e');
      return null;
    }
  }

  Future<bool> updateAISettings(Map<String, dynamic> settings) async {
    try {
      if (settings.containsKey('id')) {
        final id = settings['id'];
        await _supabase.from('ai_settings').update(settings).eq('id', id);
      } else {
        await _supabase.from('ai_settings').insert(settings);
      }
      return true;
    } catch (e) {
      print('Error updating AI settings: $e');
      return false;
    }
  }

  // Favorites Operations
  Future<Set<String>> getUserFavorites() async {
    try {
      final user = _supabase.auth.currentUser;

      // Use device ID or a persistent local ID for anonymous users
      if (user == null) {
        // For anonymous users, we'll use local storage instead
        // This will be implemented in the UI layer
        return {};
      }

      final response = await _supabase
          .from('favorites')
          .select('deal_id')
          .eq('user_id', user.id);

      return Set<String>.from(
        response.map((item) => item['deal_id'] as String),
      );
    } catch (e) {
      print('Error fetching user favorites: $e');
      return {};
    }
  }

  Future<bool> toggleFavorite(String dealId) async {
    try {
      final user = _supabase.auth.currentUser;

      // Allow anonymous favorites (implementation will be in the UI layer)
      if (user == null) {
        // Return true to indicate favorite was added
        // The actual persistence will be handled in the UI layer
        return true;
      }

      final existingFavorites = await _supabase
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .eq('deal_id', dealId);

      if (existingFavorites.isNotEmpty) {
        await _supabase
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('deal_id', dealId);
        return false;
      } else {
        await _supabase.from('favorites').insert({
          'user_id': user.id,
          'deal_id': dealId,
          'created_at': DateTime.now().toIso8601String(),
        });
        return true;
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      // Don't throw the error, just return a default value
      return false;
    }
  }

  // Storage Operations
  Future<String> uploadImage(
      String bucket, String filePath, List<int> fileBytes) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';

      await _supabase.storage
          .from(bucket)
          .uploadBinary(fileName, Uint8List.fromList(fileBytes));

      return _supabase.storage.from(bucket).getPublicUrl(fileName);
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  Future<void> deleteImage(String bucket, String imageUrl) async {
    try {
      final fileName = imageUrl.split('/').last;
      await _supabase.storage.from(bucket).remove([fileName]);
    } catch (e) {
      print('Error deleting image: $e');
      // Ignore errors if file doesn't exist
    }
  }
}
