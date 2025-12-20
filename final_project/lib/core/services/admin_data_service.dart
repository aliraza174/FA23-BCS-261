import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'admin_crud_service.dart';

class AdminDataService {
  static final AdminDataService _instance = AdminDataService._internal();
  factory AdminDataService() => _instance;
  AdminDataService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Delegate to comprehensive AdminCRUDService for all operations
  final AdminCRUDService _crudService = AdminCRUDService();

  // Generic update method - delegates to AdminCRUDService
  Future<bool> updateItem(
    String table,
    String itemId,
    Map<String, dynamic> data,
  ) async {
    debugPrint('🔗 AdminDataService.updateItem delegating to AdminCRUDService');
    return await _crudService.updateItem(table, itemId, data);
  }

  // Generic delete method - delegates to AdminCRUDService
  Future<bool> deleteItem(String table, String itemId) async {
    debugPrint('🔗 AdminDataService.deleteItem delegating to AdminCRUDService');
    return await _crudService.deleteItem(table, itemId);
  }

  // Food Items - Delegate to AdminCRUDService
  Future<bool> updateFoodItem(String itemId, Map<String, dynamic> data) async {
    debugPrint(
        '🍔 AdminDataService.updateFoodItem delegating to AdminCRUDService | ID: $itemId');
    return await _crudService.updateFoodItem(itemId, data);
  }

  Future<bool> deleteFoodItem(String itemId) async {
    debugPrint(
        '🍔 AdminDataService.deleteFoodItem delegating to AdminCRUDService | ID: $itemId');
    return await _crudService.deleteFoodItem(itemId);
  }

  // Deals
  Future<bool> updateDeal(String itemId, Map<String, dynamic> data) async {
    return updateItem('deals', itemId, data);
  }

  Future<bool> deleteDeal(String itemId) async {
    return deleteItem('deals', itemId);
  }

  // Restaurants
  Future<bool> updateRestaurant(
      String itemId, Map<String, dynamic> data) async {
    return updateItem('restaurants', itemId, data);
  }

  Future<bool> deleteRestaurant(String itemId) async {
    return deleteItem('restaurants', itemId);
  }

  // Menu Categories
  Future<bool> updateMenuCategory(
      String itemId, Map<String, dynamic> data) async {
    return updateItem('menu_categories', itemId, data);
  }

  Future<bool> deleteMenuCategory(String itemId) async {
    return deleteItem('menu_categories', itemId);
  }

  // Create methods - delegate to AdminCRUDService
  Future<Map<String, dynamic>?> createMenuCategory({
    required String name,
    required String description,
    String? imageUrl,
    int? sortOrder,
  }) async {
    debugPrint(
        '🍽️ AdminDataService.createMenuCategory delegating to AdminCRUDService');
    return await _crudService.createMenuCategory(
      name: name,
      description: description,
      imageUrl: imageUrl,
      sortOrder: sortOrder,
    );
  }

  Future<Map<String, dynamic>?> createFoodItem({
    required String name,
    required String description,
    required double price,
    required String restaurant,
    String? imageUrl,
  }) async {
    debugPrint(
        '🍔 AdminDataService.createFoodItem delegating to AdminCRUDService');
    return await _crudService.createFoodItem(
      name: name,
      description: description,
      price: price,
      restaurant: restaurant,
      imageUrl: imageUrl,
    );
  }

  Future<Map<String, dynamic>?> createDeal({
    required String title,
    required String description,
    required double price,
    int? discountPercentage,
    bool? isFeatured,
    String? imageUrl,
    String? restaurantId,
  }) async {
    debugPrint('🎯 AdminDataService.createDeal delegating to AdminCRUDService');
    return await _crudService.createDeal(
      title: title,
      description: description,
      price: price,
      discountPercentage: discountPercentage,
      isFeatured: isFeatured,
      imageUrl: imageUrl,
      restaurantId: restaurantId,
    );
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
    debugPrint(
        '🏠 AdminDataService.createRestaurant delegating to AdminCRUDService');
    return await _crudService.createRestaurant(
      name: name,
      description: description,
      address: address,
      contactNumber: contactNumber,
      phone: phone,
      imageUrl: imageUrl,
      rating: rating,
    );
  }

  // Get single item by ID and table
  Future<Map<String, dynamic>?> getItem(String table, String itemId) async {
    try {
      final response =
          await _supabase.from(table).select().eq('id', itemId).maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error getting $table item: $e');
      return null;
    }
  }
}
