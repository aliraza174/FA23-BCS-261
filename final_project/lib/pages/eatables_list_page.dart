import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';
import '../models/food_item.dart';
import '../core/widgets/admin_edit_overlay.dart';
import '../core/services/admin_crud_service.dart';
import '../core/widgets/admin_fab.dart';
import 'package:provider/provider.dart';
import '../core/providers/admin_mode_provider.dart';
import '../theme/app_theme.dart';

class EatablesListPage extends StatefulWidget {
  const EatablesListPage({super.key});

  @override
  State<EatablesListPage> createState() => _EatablesListPageState();
}

class _EatablesListPageState extends State<EatablesListPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final AdminCRUDService _crudService = AdminCRUDService();
  Set<String> _favorites = {};
  bool _showOnlyFavorites = false;
  List<FoodItem> foodItems = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final Map<String, AnimationController> _controllers = {};
  final Map<String, Animation<double>> _scaleAnimations = {};

  Map<String, String> foodImages = {
    'Burger': '',
    'Pizza': '',
    'Fries': '',
    'Nuggets': '',
    'Shawarma': '',
    'Pasta': '',
    'Samosa': '',
    'Kabab': '',
    'Biryani': '',
    'Karahi': '',
    'Nihari': '',
    'Gulab Jamun': '',
    'Rasmalai': '',
    'Kheer': '',
    'Club': '',
    'Sub': '',
    'Roll': '',
    'Spring Rolls': '',
    'Tikka': '',
    'Paneer': '',
    'Rogan Josh': '',
  };

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadFoodItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = Set<String>.from(prefs.getStringList('favorites') ?? []);
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites.toList());
  }

  AnimationController _createAnimationController() {
    return AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _ensureAnimationExists(String itemName) {
    if (!_controllers.containsKey(itemName)) {
      _controllers[itemName] = _createAnimationController();
      _scaleAnimations[itemName] = Tween<double>(begin: 1.0, end: 1.5).animate(
        CurvedAnimation(
          parent: _controllers[itemName]!,
          curve: Curves.elasticOut,
        ),
      );
    }
  }

  void _toggleFavorite(String itemName) {
    setState(() {
      _ensureAnimationExists(itemName);
      if (_favorites.contains(itemName)) {
        _favorites.remove(itemName);
        _controllers[itemName]?.reverse();
      } else {
        _favorites.add(itemName);
        _controllers[itemName]?.forward();
      }
      _saveFavorites();
    });
  }

  List<FoodItem> _getFilteredItems(String query) {
    if (_showOnlyFavorites) {
      return foodItems
          .where((item) =>
              _favorites.contains(item.name) &&
              (query.isEmpty ||
                  item.name.toLowerCase().contains(query.toLowerCase())))
          .toList();
    }
    if (query.isEmpty) {
      return foodItems;
    }
    return foodItems
        .where((item) =>
            item.name.toLowerCase().contains(query.toLowerCase()) ||
            item.description.toLowerCase().contains(query.toLowerCase()) ||
            item.restaurant.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Load food items from database with enhanced error handling
  Future<void> _loadFoodItems() async {
    debugPrint(' Starting to load food items from database...');
    debugPrint(' Mobile Debug - Platform: $defaultTargetPlatform');

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Get food items with restaurant data via JOIN query
      final foodItemsData = await _crudService.getFoodItems();

      debugPrint(' Raw database response: ${foodItemsData.length} items');
      if (foodItemsData.isNotEmpty) {
        debugPrint(' First item sample: ${foodItemsData.first}');
      } else {
        debugPrint(
            ' No food items returned from database - this might indicate a connection issue');
      }

      final loadedItems = foodItemsData.map((item) {
        final foodItem = FoodItem.fromDatabase(item);

        debugPrint(
            ' Created FoodItem: ${foodItem.name} at ${foodItem.restaurant}');
        return foodItem;
      }).toList();

      setState(() {
        foodItems = loadedItems;
        _isLoading = false;
      });

      debugPrint(
          ' Successfully loaded ${foodItems.length} food items from database');
      debugPrint(
          ' Food items: ${foodItems.map((item) => '${item.name} (${item.restaurant})').join(', ')}');
    } catch (e, stackTrace) {
      debugPrint(' Error loading food items: $e');
      debugPrint(' Stack trace: $stackTrace');
      debugPrint(' Mobile Debug - Error type: ${e.runtimeType}');

      // Enhanced mobile-specific error analysis
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('network') ||
          errorString.contains('connection')) {
        debugPrint(' MOBILE ISSUE: Network connectivity problem');
        debugPrint('   Check: Internet connection, Supabase URL in .env file');
      }
      if (errorString.contains('authentication') ||
          errorString.contains('unauthorized')) {
        debugPrint(' MOBILE ISSUE: Authentication problem');
        debugPrint('   Check: Supabase ANON_KEY in .env file');
      }
      if (errorString.contains('timeout')) {
        debugPrint(' MOBILE ISSUE: Request timeout');
        debugPrint('   Check: Network speed, Supabase service status');
      }

      setState(() {
        _errorMessage = 'Failed to load food items from database';
        _isLoading = false;
        // Use static fallback data if database fails
        foodItems = _getStaticFoodItems();
      });

      debugPrint(' Using ${foodItems.length} static fallback food items');
    }
  }

  /// Resolve restaurant name from database item (with JOIN query data)
  String _resolveRestaurantName(Map<String, dynamic> item) {
    // With JOIN query, we now get restaurant_name directly
    final restaurantName = item['restaurant_name']?.toString() ??
        item['restaurant']?.toString() ??
        'Unknown Restaurant';

    debugPrint(' Resolved restaurant for "${item['name']}": $restaurantName');
    return restaurantName;
  }

  /// Fallback static food items if database fails - mirrors web content
  List<FoodItem> _getStaticFoodItems() {
    debugPrint(' Using static fallback food items (database unavailable)');

    return [
      FoodItem(
        id: 'static-1',
        name: 'Zinger Burger',
        restaurant: 'Crust Bros',
        description: 'Crispy chicken with mayo and lettuce in sesame bun',
        price: 399.0,
        imageUrl: '',
      ),
      FoodItem(
        id: 'static-2',
        name: 'Chicken Pizza',
        restaurant: 'Crust Bros',
        description: 'Fresh and hot pizza with chicken and special toppings',
        price: 649.0,
        imageUrl: '',
      ),
      FoodItem(
        id: 'static-3',
        name: 'Chicken Biryani',
        restaurant: 'Nawab Hotel',
        description: 'Special biryani with aromatic rice and spices',
        price: 500.0,
        imageUrl: '',
      ),
      FoodItem(
        id: 'static-4',
        name: 'Chicken Karahi',
        restaurant: 'Nawab Hotel',
        description: 'Traditional karahi with fresh ingredients',
        price: 700.0,
        imageUrl: '',
      ),
      FoodItem(
        id: 'static-5',
        name: 'Sample Drink',
        restaurant: 'Unknown Restaurant',
        description: 'Refreshing beverage',
        price: 99.0,
        imageUrl: '',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = AppTheme.backgroundColor(context);
    final isDarkMode = AppTheme.isDarkMode(context);
    final cardColor = AppTheme.cardColor(context);
    final textColor = AppTheme.textColor(context);
    final headerGradient = AppTheme.getHeaderGradient(context);
    final searchBarColor = AppTheme.getSearchBarColor(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: AdminFAB(
        itemType: 'food_items',
        onItemCreated: _handleItemCreated,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: headerGradient,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => const MainScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Expanded(
                            child: Text(
                              'List of eatables Jahanian',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _showOnlyFavorites
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _showOnlyFavorites
                                    ? Colors.red
                                    : Colors.white,
                                size: 24,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showOnlyFavorites = !_showOnlyFavorites;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Integrated Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: searchBarColor,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isDarkMode ? 0.3 : 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: 'What are you looking for?',
                            hintStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey),
                            prefixIcon: Icon(Icons.search,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  /// Build the main body  with loading/error states
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Loading food items...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Food Items',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFoodItems,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    List<FoodItem> items = _getFilteredItems(_searchController.text);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Food Items Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try adjusting your search'
                  : 'No food items available',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Find the list of items in jahanian',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              Consumer<AdminModeProvider>(
                builder: (context, adminProvider, child) {
                  if (adminProvider.isAdminLoggedIn &&
                      adminProvider.isEditModeEnabled) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 16, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'EDIT MODE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildFoodItemCard(item);
            },
          ),
        ),
      ],
    );
  }

  /// Handle when a new item is created
  void _handleItemCreated(String itemType, Map<String, dynamic> newItem) {
    if (!mounted) return;

    debugPrint(' New $itemType created: ${newItem['id']} - ${newItem['name']}');

    if (itemType == 'food_items') {
      // Convert to FoodItem and add immediately for instant display
      final foodItem = FoodItem.fromDatabase(newItem);

      // Optimistic UI update
      setState(() {
        foodItems.insert(0, foodItem); // Add at the beginning
      });

      debugPrint(
          ' Food item added to UI immediately. Total items: ${foodItems.length}');
    }

    // Background refresh
    _loadFoodItems();
  }

  Widget _buildFoodItemCard(FoodItem item) {
    _ensureAnimationExists(item.name);
    final bool isFavorite = _favorites.contains(item.name);
    final isDarkMode = AppTheme.isDarkMode(context);
    final cardColor = AppTheme.cardColor(context);
    final textColor = AppTheme.textColor(context);
    final textSecondary = AppTheme.textSecondary(context);
    final accentColor = AppTheme.getAccentColor(context);

    final Map<String, dynamic> itemData = {
      'name': item.name,
      'restaurant': item.restaurant,
      'description': item.description,
      'price': item.price,
      'image_url': item.imageUrl,
      'restaurant_id': item.restaurantId,
    };

    return AdminEditOverlay(
      itemId: item.id,
      itemType: 'food_items',
      itemData: itemData,
      onEdit: _handleEditFoodItem,
      onDelete: _handleDeleteFoodItem,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + overlays
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    child: item.imageUrl.isNotEmpty
                        ? Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.restaurant,
                                size: 40,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                          )
                        : Icon(Icons.restaurant,
                            size: 40,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600]),
                  ),
                ),
                // Favorite
                Positioned(
                  top: 8,
                  right: 8,
                  child: ScaleTransition(
                    scale: _scaleAnimations[item.name]!,
                    child: InkWell(
                      onTap: () => _toggleFavorite(item.name),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cardColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isDarkMode ? 0.3 : 0.12),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                // Price badge
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      item.formattedPrice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Texts
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.restaurant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  } // Admin functionality handlers - Use AdminCRUDService directly for consistency

  Future<void> _handleEditFoodItem(
      String itemType, String itemId, Map<String, dynamic> data) async {
    debugPrint('Attempting to update food item: $itemId with data: $data');

    try {
      // Use AdminCRUDService directly for consistency with create operations
      final success = await _crudService.updateFoodItem(itemId, data);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Food item updated successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh the food items list from database
          _loadFoodItems();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          'Failed to update food item. Please try again.')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Exception in _handleEditFoodItem: $e');
      debugPrint(' Mobile Debug - Edit error type: ${e.runtimeType}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Update error: $e')),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteFoodItem(String itemType, String itemId) async {
    try {
      // Use AdminCRUDService directly for consistency with create operations
      final success = await _crudService.deleteFoodItem(itemId);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Food item deleted successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Refresh the food items list from database
        _loadFoodItems();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Failed to delete food item. Please try again.'),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Exception in _handleDeleteFoodItem: $e');
      debugPrint(' Mobile Debug - Delete error type: ${e.runtimeType}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Delete error: $e')),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
