import 'package:flutter/services.dart';

class DatasetParser {
  /// Singleton instance
  static final DatasetParser _instance = DatasetParser._internal();
  factory DatasetParser() => _instance;
  DatasetParser._internal();

  /// Cache for parsed data
  Map<String, dynamic>? _cachedData;

  /// Load and parse dataset.txt file
  Future<Map<String, dynamic>> loadDataset() async {
    if (_cachedData != null) {
      return _cachedData!;
    }

    try {
      final String data = await rootBundle.loadString('lib/pages/dataset.txt');

      final Map<String, dynamic> result = {
        'restaurants': _parseRestaurants(data),
        'menuItems': _parseMenuItems(data),
        'deals': _parseDeals(data),
      };

      _cachedData = result;
      return result;
    } catch (e) {
      print('Error loading dataset: $e');
      return {
        'restaurants': [],
        'menuItems': [],
        'deals': [],
      };
    }
  }

  /// Parse restaurants from the dataset text
  List<Map<String, dynamic>> _parseRestaurants(String data) {
    final List<Map<String, dynamic>> restaurants = [];
    int id = 1;

    // Split by restaurant sections
    final List<String> sections = data.split('--------------------');

    for (String section in sections) {
      if (section.trim().isEmpty) continue;

      // Find restaurant name (usually at the beginning of a section)
      String? name;
      String description = '';
      String contactInfo = '';
      String address = '';

      // Extract restaurant name
      final nameMatch = RegExp(r'^(.*?)(?:Menu|-+)').firstMatch(section);
      if (nameMatch != null) {
        name = nameMatch.group(1)?.trim();
      }

      // Skip if no name found
      if (name == null || name.isEmpty) continue;

      // Extract contact information
      final contactMatches = RegExp(r'Contact(?:[:\s]+)(.*?)(?:\n|$)',
              caseSensitive: false, multiLine: true)
          .allMatches(section);

      if (contactMatches.isNotEmpty) {
        contactInfo = contactMatches.first.group(1)?.trim() ?? '';
      }

      // Extract address
      final addressMatches = RegExp(r'Location(?:[:\s]+)(.*?)(?:\n|$)',
              caseSensitive: false, multiLine: true)
          .allMatches(section);

      if (addressMatches.isNotEmpty) {
        address = addressMatches.first.group(1)?.trim() ?? '';
      }

      // Extract description
      description = '$name offers a variety of food items in Jahanian.';

      // Create restaurant object
      restaurants.add({
        'id': id++,
        'name': name,
        'description': description,
        'address': address,
        'contact_number': contactInfo,
        'opening_hours': '11:00 AM - 11:00 PM', // Default
        'rating': 4.0 + (id % 10) / 10, // Generate a rating between 4.0 and 4.9
        'image_url':
            'https://images.unsplash.com/photo-${1550000000 + id * 1000}-placeholder',
      });
    }

    return restaurants;
  }

  /// Parse menu items from the dataset text
  List<Map<String, dynamic>> _parseMenuItems(String data) {
    final List<Map<String, dynamic>> menuItems = [];
    int id = 1;

    // Split by restaurant sections
    final List<String> sections = data.split('--------------------');

    for (String section in sections) {
      if (section.trim().isEmpty) continue;

      // Find restaurant name
      String? restaurantName;
      final nameMatch = RegExp(r'^(.*?)(?:Menu|-+)').firstMatch(section);
      if (nameMatch != null) {
        restaurantName = nameMatch.group(1)?.trim();
      }

      // Skip if no restaurant name found
      if (restaurantName == null || restaurantName.isEmpty) continue;

      // Create restaurant reference
      final Map<String, dynamic> restaurant = {
        'id': sections.indexOf(section) + 1,
        'name': restaurantName,
      };

      // Extract food items
      String currentCategory = 'Uncategorized';

      // Split the section into lines
      final lines = section.split('\n');
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();

        // Skip empty lines
        if (line.isEmpty) continue;

        // Check if line is a category
        if (line.endsWith(':') ||
            line.endsWith('PIZZAS') ||
            line.endsWith('MENU') ||
            line.endsWith('DEALS') ||
            line.toUpperCase() == line && line.length > 3) {
          currentCategory = line.replaceAll(':', '').trim();
          continue;
        }

        // Check if line contains an item with price
        final priceMatch = RegExp(r'(.+?)\s*-\s*(?:Rs\.?|₨)?\s*(\d+(?:\.\d+)?)')
            .firstMatch(line);
        if (priceMatch != null) {
          final itemName = priceMatch.group(1)?.trim() ?? '';
          final priceString = priceMatch.group(2) ?? '0';
          final price = double.tryParse(priceString) ?? 0.0;

          // Skip if item name is empty or likely not a food item
          if (itemName.isEmpty ||
              itemName.contains('Contact') ||
              itemName.contains('Location') ||
              itemName.length < 3) {
            continue;
          }

          // Create menu item
          menuItems.add({
            'id': id++,
            'name': itemName,
            'description': '', // No detailed description in dataset
            'category': currentCategory,
            'price': price,
            'image_url': null, // No images in dataset
            'restaurants': restaurant,
          });
        }
      }
    }

    return menuItems;
  }

  /// Parse deals from the dataset text
  List<Map<String, dynamic>> _parseDeals(String data) {
    final List<Map<String, dynamic>> deals = [];
    int id = 1;

    // Split by restaurant sections
    final List<String> sections = data.split('--------------------');

    for (String section in sections) {
      if (section.trim().isEmpty) continue;

      // Find restaurant name
      String? restaurantName;
      final nameMatch = RegExp(r'^(.*?)(?:Menu|-+)').firstMatch(section);
      if (nameMatch != null) {
        restaurantName = nameMatch.group(1)?.trim();
      }

      // Skip if no restaurant name found
      if (restaurantName == null || restaurantName.isEmpty) continue;

      // Create restaurant reference
      final Map<String, dynamic> restaurant = {
        'id': sections.indexOf(section) + 1,
        'name': restaurantName,
      };

      // Look for deal sections
      bool inDealSection = false;
      String dealTitle = '';
      String dealDescription = '';
      double dealPrice = 0.0;

      // Split the section into lines
      final lines = section.split('\n');
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();

        // Skip empty lines
        if (line.isEmpty) continue;

        // Check if we're entering a deal section
        if (line.contains('Deal') ||
            line.contains('DEAL') ||
            line.contains('Platter')) {
          // If we were already in a deal section, save the previous deal
          if (inDealSection && dealTitle.isNotEmpty && dealPrice > 0) {
            deals.add({
              'id': id++,
              'title': dealTitle,
              'description': dealDescription,
              'price': dealPrice,
              'is_featured': id % 3 == 0, // Every third deal is featured
              'discount_percentage':
                  10 + (id % 3) * 5, // 10%, 15%, or 20% discount
              'image_url': null, // No images in dataset
              'restaurants': restaurant,
            });
          }

          // Start a new deal
          inDealSection = true;
          dealTitle = line;
          dealDescription = '';
          dealPrice = 0.0;
          continue;
        }

        // If we're in a deal section, collect description and price
        if (inDealSection) {
          // Check if line contains price
          final priceMatch =
              RegExp(r'(?:Rs\.?|₨)?\s*(\d+(?:\.\d+)?)').firstMatch(line);
          if (priceMatch != null) {
            final priceString = priceMatch.group(1) ?? '0';
            dealPrice = double.tryParse(priceString) ?? 0.0;
          }

          // Add to description
          if (dealDescription.isNotEmpty) {
            dealDescription += ', ';
          }
          dealDescription += line;

          // If next line is empty or starts a new section, save this deal
          if (i == lines.length - 1 ||
              lines[i + 1].trim().isEmpty ||
              lines[i + 1].contains('Deal') ||
              lines[i + 1].contains('DEAL')) {
            if (dealTitle.isNotEmpty && dealPrice > 0) {
              deals.add({
                'id': id++,
                'title': dealTitle,
                'description': dealDescription,
                'price': dealPrice,
                'is_featured': id % 3 == 0, // Every third deal is featured
                'discount_percentage':
                    10 + (id % 3) * 5, // 10%, 15%, or 20% discount
                'image_url': null, // No images in dataset
                'restaurants': restaurant,
              });
            }

            inDealSection = false;
          }
        }
      }
    }

    return deals;
  }
}
