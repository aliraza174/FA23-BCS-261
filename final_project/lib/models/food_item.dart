/// FoodItem model aligned with database schema
/// Only includes fields that exist in the actual food_items table
class FoodItem {
  final String id; // Database primary key - now required
  final String name;
  final String restaurant; // Display name (resolved from restaurant_id)
  final String? restaurantId; // Foreign key to restaurants table
  final String? restaurantName; // From JOIN query
  final String description;
  final double price; // Numeric price for calculations
  final String imageUrl; // Database column is image_url (snake_case)
  
  // Removed phantom fields that don't exist in database:
  // - size (not in schema)
  // - searchKeywords (not in schema as array)

  FoodItem({
    required this.id,
    required this.name,
    required this.restaurant,
    this.restaurantId,
    this.restaurantName,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  // Parse an individual line from the dataset
  factory FoodItem.fromLine(String line, Map<String, String> imageMap) {
    var data = line.split(
        ','); // Assuming each field in your dataset is separated by commas
    var name = data[0].trim();
    var imageUrl = imageMap[name.split(' ')[0]] ??
        'https://images.pexels.com/photos/default.jpeg';
    
    // Parse price from string format
    final priceString = data[3].trim().replaceAll(RegExp(r'[Rs\.\,\s]'), '');
    final parsedPrice = double.tryParse(priceString) ?? 0.0;
    
    return FoodItem(
      id: 'static-${name.hashCode}', // Generate ID for static data
      name: name,
      restaurant: data[1].trim(),
      description: data[2].trim(),
      price: parsedPrice,
      imageUrl: imageUrl,
    );
  }

  // Format price for display
  String get formattedPrice => 'Rs.${price.toStringAsFixed(0)}';

  // Create FoodItem from database row with proper field mapping
  factory FoodItem.fromDatabase(Map<String, dynamic> data) {
    return FoodItem(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Unnamed Item',
      restaurant: data['restaurant_name']?.toString() ?? 
                 data['restaurant']?.toString() ?? 
                 'Unknown Restaurant',
      restaurantId: data['restaurant_id']?.toString(),
      restaurantName: data['restaurant_name']?.toString(),
      description: data['description']?.toString() ?? 'No description',
      price: _parsePrice(data['price']),
      imageUrl: data['image_url']?.toString() ?? '',
    );
  }

  // Helper to parse price from various formats
  static double _parsePrice(dynamic priceValue) {
    if (priceValue == null) return 0.0;
    
    if (priceValue is double) return priceValue;
    if (priceValue is int) return priceValue.toDouble();
    
    final priceString = priceValue.toString().replaceAll(RegExp(r'[Rs\.\,\s]'), '');
    return double.tryParse(priceString) ?? 0.0;
  }

  bool matchesSearch(String query) {
    final lowercaseQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowercaseQuery) ||
        description.toLowerCase().contains(lowercaseQuery) ||
        restaurant.toLowerCase().contains(lowercaseQuery);
  }

  // Convert to database payload format (camelCase -> snake_case)
  Map<String, dynamic> toDatabase() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'restaurant_id': restaurantId,
    };
  }
}

List<FoodItem> loadFoodItems(String dataset, Map<String, String> imageMap) {
  List<FoodItem> items = [];
  final lines = dataset.split('\n');
  for (var line in lines) {
    items.add(FoodItem.fromLine(line, imageMap));
  }
  return items;
}
