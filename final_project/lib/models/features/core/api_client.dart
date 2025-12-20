import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class ApiClient {
  final SupabaseClient _supabaseClient;

  ApiClient({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  // Singleton instance
  static final ApiClient _instance = ApiClient(
    supabaseClient: Supabase.instance.client,
  );

  static ApiClient get instance => _instance;

  // Restaurant APIs
  Future<List<Map<String, dynamic>>> getRestaurants() async {
    final response = await _supabaseClient
        .from('restaurants')
        .select()
        .order('name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Deals APIs
  Future<List<Map<String, dynamic>>> getDeals({String? restaurantId}) async {
    var query = _supabaseClient
        .from('deals')
        .select('*, restaurants:restaurant_id(name)');

    if (restaurantId != null) {
      query = query.eq('restaurant_id', restaurantId);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Menu Images APIs
  Future<List<Map<String, dynamic>>> getMenuImages() async {
    final response = await _supabaseClient
        .from('menu_images')
        .select()
        .order('display_order', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Food Items APIs (formerly Eatables)
  Future<List<Map<String, dynamic>>> getEatables({String? restaurantId}) async {
    var query = _supabaseClient
        .from('food_items')
        .select('*, restaurants:restaurant_id(name)');

    if (restaurantId != null) {
      query = query.eq('restaurant_id', restaurantId);
    }

    final response = await query.order('name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // AI Settings APIs
  Future<Map<String, dynamic>?> getAISettings() async {
    try {
      final response =
          await _supabaseClient.from('ai_settings').select().single();

      return response;
    } catch (e) {
      return null;
    }
  }

  // Favorites APIs
  Future<List<int>> getUserFavorites() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) return []; // Return empty list for anonymous users

    final response = await _supabaseClient
        .from('favorites')
        .select('deal_id')
        .eq('user_id', user.id);

    return List<int>.from(
      response.map((favorite) => favorite['deal_id'] as int),
    );
  }

  Future<void> addFavorite(int dealId) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) return; // Allow anonymous users - handled in UI layer

    await _supabaseClient.from('favorites').insert({
      'user_id': user.id,
      'deal_id': dealId,
    });
  }

  Future<void> removeFavorite(int dealId) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) return; // Allow anonymous users - handled in UI layer

    await _supabaseClient
        .from('favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('deal_id', dealId);
  }

  // Storage APIs
  Future<String> uploadImage(
      String bucket, String filePath, List<int> fileBytes) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';

    await _supabaseClient.storage
        .from(bucket)
        .uploadBinary(fileName, Uint8List.fromList(fileBytes));

    return _supabaseClient.storage.from(bucket).getPublicUrl(fileName);
  }

  Future<void> deleteImage(String bucket, String imageUrl) async {
    try {
      final fileName = imageUrl.split('/').last;
      await _supabaseClient.storage.from(bucket).remove([fileName]);
    } catch (e) {
      // Ignore errors if file doesn't exist
    }
  }
}
