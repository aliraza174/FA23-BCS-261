import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/deal_fullscreen_viewer.dart';
import '../widgets/restaurant_menu_gallery.dart';
import '../models/restaurant_data_model.dart';
import '../core/widgets/admin_edit_overlay.dart';
import '../core/widgets/admin_fab.dart';
import '../core/widgets/loading_widget.dart';
import '../core/widgets/error_handler.dart';
import '../features/admin/presentation/bloc/restaurant/restaurant_bloc.dart';
import '../features/admin/presentation/bloc/restaurant/restaurant_event.dart';
import '../features/admin/presentation/bloc/restaurant/restaurant_state.dart';
import '../features/admin/domain/entities/restaurant.dart';
import '../theme/app_theme.dart';

class RestaurantDetailsPage extends StatefulWidget {
  final String? restaurantId;

  const RestaurantDetailsPage({super.key, this.restaurantId});

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  List<Restaurant> _restaurants = [];
  final Map<String, List<Map<String, dynamic>>> _restaurantDeals = {};
  final Map<String, List<Map<String, dynamic>>> _restaurantMenuItems = {};

  @override
  void initState() {
    super.initState();
    context.read<RestaurantBloc>().add(const RestaurantEvent.loadRestaurants());
  }

  void _loadRestaurantsFromState(List<Restaurant> restaurants) {
    setState(() {
      _restaurants = restaurants;
    });

    // Load details for each restaurant
    for (var restaurant in restaurants) {
      _fetchRestaurantDetails(restaurant.id, restaurant.name);
    }
  }

  Future<void> _fetchRestaurantDetails(
      String restaurantId, String restaurantName) async {
    try {
      // For now, we'll use local data. In the future, this can be enhanced with proper data loading
      final menuItems = _getMenuItemsFromDataset(restaurantName);
      final deals = _getDealsFromDataset(restaurantName);

      if (mounted) {
        setState(() {
          _restaurantMenuItems[restaurantId] = menuItems;
          _restaurantDeals[restaurantId] = deals;
        });
      }

      debugPrint(
          'Restaurant $restaurantName loaded with ${menuItems.length} menu items and ${deals.length} deals');
    } catch (e) {
      debugPrint('Error fetching restaurant details: $e');
    }
  }

  // Helper method to generate menu items based on restaurant name
  List<Map<String, dynamic>> _getMenuItemsFromDataset(String restaurantName) {
    final List<Map<String, dynamic>> items = [];
    int itemId = 1;
    final lowerName = restaurantName.toLowerCase();

    // Find matching restaurant in allRestaurants
    final restaurantModel = allRestaurants.firstWhere(
      (r) =>
          r.name.toLowerCase().contains(lowerName) ||
          lowerName.contains(r.name.toLowerCase()),
      orElse: () => allRestaurants.first,
    );

    // Add menu items from restaurant model first
    for (var category in restaurantModel.menuCategories) {
      items.add({
        'id': itemId++,
        'name': category.name,
        'description': '${category.description} - Rs. ${category.price}',
        'category': 'Main Menu',
        'price': category.price,
        'image_url':
            'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38',
        'restaurants': {
          'id': int.tryParse(restaurantModel.id) ?? 1,
          'name': restaurantName
        },
      });
    }

    return items;
  }

  // Helper method to generate deals based on restaurant name
  List<Map<String, dynamic>> _getDealsFromDataset(String restaurantName) {
    final List<Map<String, dynamic>> deals = [];
    int dealId = 1;
    final lowerName = restaurantName.toLowerCase();

    // Find matching restaurant in allRestaurants
    final restaurantModel = allRestaurants.firstWhere(
      (r) =>
          r.name.toLowerCase().contains(lowerName) ||
          lowerName.contains(r.name.toLowerCase()),
      orElse: () => allRestaurants.first,
    );

    // Add sample deals
    deals.add({
      'id': dealId++,
      'title': 'Special Deal',
      'description': 'Great combo deal with amazing value',
      'price': 999,
      'is_featured': true,
      'discount_percentage': 15,
      'image_url':
          'https://images.unsplash.com/photo-1571091718767-18b5b1457add',
      'restaurants': {
        'id': int.tryParse(restaurantModel.id) ?? 1,
        'name': restaurantName
      },
    });

    return deals;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = AppTheme.backgroundColor(context);
    final headerGradient = AppTheme.getHeaderGradient(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.textColor(context);
    final accentColor = AppTheme.getAccentColor(context);
    final cardColor = AppTheme.cardColor(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: AdminFAB(
        itemType: 'restaurants',
        onItemCreated: _handleItemCreated,
      ),
      body: BlocConsumer<RestaurantBloc, RestaurantState>(
        listener: (context, state) {
          state.maybeWhen(
            loaded: (restaurants) {
              _loadRestaurantsFromState(restaurants);
            },
            error: (failure) {
              context.showError(failure);
            },
            success: () {
              context
                  .showSuccess('Restaurant operation completed successfully!');
              context
                  .read<RestaurantBloc>()
                  .add(const RestaurantEvent.loadRestaurants());
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          return Column(
            children: [
              // Modern Header with Orange Gradient
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: headerGradient,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Restaurants Guide',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.restaurant_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Explore restaurants in Jahanian with detailed info',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: LoadingOverlay(
                  isLoading: state.maybeWhen(
                    loading: () => true,
                    orElse: () => false,
                  ),
                  child: Container(
                    color: isDarkMode
                        ? AppTheme.darkSurface
                        : const Color(0xFFFAF8F4),
                    child: state.maybeWhen(
                      loaded: (restaurants) => _restaurants.isEmpty
                          ? _buildEmptyState(isDarkMode, textColor, accentColor)
                          : _buildAllRestaurantsView(
                              isDarkMode, textColor, accentColor, cardColor),
                      error: (failure) => _buildErrorState(failure.toString(),
                          isDarkMode, textColor, accentColor),
                      orElse: () =>
                          _buildEmptyState(isDarkMode, textColor, accentColor),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode, Color textColor, Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant,
              size: 64, color: isDarkMode ? Colors.grey[600] : Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No restaurants available',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Add restaurants to get started',
            style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      String error, bool isDarkMode, Color textColor, Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(fontSize: 16, color: textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context
                .read<RestaurantBloc>()
                .add(const RestaurantEvent.loadRestaurants()),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildAllRestaurantsView(
      bool isDarkMode, Color textColor, Color accentColor, Color cardColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _restaurants[index];
        return _buildRestaurantCard(
            restaurant, isDarkMode, textColor, accentColor, cardColor);
      },
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant, bool isDarkMode,
      Color textColor, Color accentColor, Color cardColor) {
    // Find restaurant in allRestaurants model if possible
    final String restaurantName = restaurant.name;
    final lowerName = restaurantName.toLowerCase();

    // Try to find a matching restaurant in our model
    final restaurantModel = allRestaurants.firstWhere(
      (r) =>
          r.name.toLowerCase().contains(lowerName) ||
          lowerName.contains(r.name.toLowerCase()),
      orElse: () => allRestaurants.first,
    );

    return AdminEditOverlay(
      itemId: restaurant.id,
      itemType: 'restaurant',
      itemData: {
        'id': restaurant.id,
        'name': restaurant.name,
        'description': restaurant.description,
        'address': restaurant.address,
        'phone': restaurant.phone,
        'logo_url': restaurant.logoUrl,
      },
      onEdit: _handleEditRestaurant,
      onDelete: _handleDeleteRestaurant,
      child: Card(
        margin: const EdgeInsets.only(bottom: 24),
        elevation: 4,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Restaurant Image with gradient overlay
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  // Restaurant Image
                  Image.asset(
                    restaurantModel.imageAsset.isNotEmpty
                        ? restaurantModel.imageAsset
                        : 'assets/images/restaurant1.jpg',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: isDarkMode
                            ? AppTheme.darkSurface
                            : Colors.grey[300],
                        child: Icon(Icons.restaurant,
                            size: 80,
                            color: isDarkMode ? Colors.grey[600] : Colors.grey),
                      );
                    },
                  ),
                  // Gradient overlay
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Restaurant name and rating
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          restaurantName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Rating stars
                            ...List.generate(
                              (restaurantModel.basicInfo.googleRating ?? 4)
                                  .floor(),
                              (index) => const Icon(Icons.star,
                                  color: Colors.amber, size: 20),
                            ),
                            const SizedBox(width: 8),
                            // Rating number
                            Text(
                              '${restaurantModel.basicInfo.googleRating ?? 4.0}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Restaurant Details Tabs
            DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    labelColor: isDarkMode ? Colors.white : Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: accentColor,
                    tabs: const [
                      Tab(text: 'Info'),
                      Tab(text: 'Menu'),
                      Tab(text: 'Deals'),
                    ],
                  ),
                  SizedBox(
                    height: 400, // Fixed height for tab content
                    child: TabBarView(
                      children: [
                        // Info Tab
                        _buildInfoTab(restaurant, restaurantModel, isDarkMode,
                            textColor, accentColor),

                        // Menu Tab
                        _buildMenuTab(restaurant, restaurantModel, isDarkMode,
                            textColor, accentColor),

                        // Deals Tab
                        _buildDealsTab(restaurant, restaurantModel, isDarkMode,
                            textColor, accentColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Quick Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final address = restaurant.address ??
                            restaurantModel.contactDetails.address;
                        final url =
                            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        }
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showContactOptions(restaurant, restaurantModel);
                      },
                      icon: const Icon(Icons.call),
                      label: const Text('Contact'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab(
      Restaurant restaurant,
      RestaurantDataModel restaurantModel,
      bool isDarkMode,
      Color textColor,
      Color accentColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Section
          Card(
            elevation: 3,
            color: isDarkMode ? AppTheme.darkCardColor : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: accentColor, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  Divider(
                      height: 24, color: isDarkMode ? Colors.grey[700] : null),
                  Text(
                    restaurant.description ??
                        'Established in ${restaurantModel.basicInfo.established ?? "recent years"}, ${restaurantModel.basicInfo.fullName} is a ${restaurantModel.basicInfo.type} restaurant offering a variety of delicious menu items.',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Contact Information Card
          Card(
            elevation: 3,
            color: isDarkMode ? AppTheme.darkCardColor : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.contact_phone, color: accentColor, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  Divider(
                      height: 24, color: isDarkMode ? Colors.grey[700] : null),

                  // Address
                  _buildInfoRow(
                    icon: Icons.location_on,
                    title: 'Address',
                    value: restaurant.address ??
                        restaurantModel.contactDetails.address,
                    isDarkMode: isDarkMode,
                    textColor: textColor,
                    accentColor: accentColor,
                  ),

                  // Phone
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.phone,
                    title: 'Phone',
                    value: restaurant.phone ??
                        restaurantModel.contactDetails.phone,
                    isPhone: true,
                    isDarkMode: isDarkMode,
                    textColor: textColor,
                    accentColor: accentColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool isPhone = false,
    required bool isDarkMode,
    required Color textColor,
    required Color accentColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accentColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              isPhone
                  ? GestureDetector(
                      onTap: () {
                        launchUrl(Uri.parse('tel:$value'));
                      },
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTab(
      Restaurant restaurant,
      RestaurantDataModel restaurantModel,
      bool isDarkMode,
      Color textColor,
      Color accentColor) {
    // Get menu items for this restaurant
    final restaurantId = restaurant.id;
    final menuItems = _restaurantMenuItems[restaurantId] ?? [];

    // Check if there are menu images available
    final hasMenuImages = restaurantModel.menuImages.isNotEmpty;

    // Group menu items by category
    final Map<String, List<Map<String, dynamic>>> categorizedItems = {};
    for (var item in menuItems) {
      final category = item['category'] ?? 'Uncategorized';
      if (!categorizedItems.containsKey(category)) {
        categorizedItems[category] = [];
      }
      categorizedItems[category]!.add(item);
    }

    return Column(
      children: [
        // Menu Images Button
        if (hasMenuImages)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RestaurantMenuGallery(
                      restaurantName: restaurant.name,
                      menuImages: restaurantModel.menuImages,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book),
              label: const Text('View Menu Images'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),

        // Menu Items List
        Expanded(
          child: menuItems.isEmpty
              ? Center(
                  child: Text(
                    'No menu items available for ${restaurant.name}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (var category in categorizedItems.keys)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Header
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: accentColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),

                          // Category Items
                          ...categorizedItems[category]!
                              .map((item) => AdminEditOverlay(
                                    itemId: item['id']?.toString() ?? '',
                                    itemType: 'food_item',
                                    itemData: item,
                                    onEdit: _handleEditFoodItem,
                                    onDelete: _handleDeleteFoodItem,
                                    child: Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      color: isDarkMode
                                          ? AppTheme.darkCardColor
                                          : null,
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.all(12),
                                        leading: CircleAvatar(
                                          radius: 25,
                                          backgroundColor: isDarkMode
                                              ? AppTheme.darkSurface
                                              : Colors.grey[200],
                                          child: Icon(Icons.restaurant_menu,
                                              color: accentColor),
                                        ),
                                        title: Text(
                                          item['name'] ?? 'Menu Item',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: textColor),
                                        ),
                                        subtitle: Text(
                                            item['description'] ?? '',
                                            style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.grey[400]
                                                    : null)),
                                        trailing: Text(
                                          'Rs. ${item['price']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),

                          const SizedBox(height: 16),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildDealsTab(
      Restaurant restaurant,
      RestaurantDataModel restaurantModel,
      bool isDarkMode,
      Color textColor,
      Color accentColor) {
    final restaurantId = restaurant.id;
    final deals = _restaurantDeals[restaurantId] ?? [];

    // Check if there are deal images available
    final hasDealImages = restaurantModel.dealImages.isNotEmpty;

    return Column(
      children: [
        // Deal Images Button
        if (hasDealImages)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                _showDealFullscreen(
                    restaurantModel.dealImages, 0, restaurant.name);
              },
              icon: const Icon(Icons.image),
              label: const Text('View Deal Images'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),

        // Deals List
        Expanded(
          child: deals.isEmpty
              ? Center(
                  child: Text(
                    'No deals available for ${restaurant.name}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: deals.length,
                  itemBuilder: (context, index) {
                    final deal = deals[index];
                    return AdminEditOverlay(
                      itemId: deal['id']?.toString() ?? '',
                      itemType: 'deal',
                      itemData: deal,
                      onEdit: _handleEditDeal,
                      onDelete: _handleDeleteDeal,
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isDarkMode ? AppTheme.darkCardColor : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    deal['title'] ?? 'Special Deal',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Rs. ${deal['price']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                deal['description'] ??
                                    'Special promotional deal',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (deal['discount_percentage'] != null)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${deal['discount_percentage']}% OFF',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  if (deal['is_featured'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accentColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'FEATURED',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showDealFullscreen(
      List<String> images, int initialIndex, String restaurantName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DealFullscreenViewer(
          images: images,
          initialIndex: initialIndex,
          title: '$restaurantName Deal',
        ),
      ),
    );
  }

  void _showContactOptions(
      Restaurant restaurant, RestaurantDataModel restaurantModel) {
    final phoneNumber =
        restaurant.phone ?? restaurantModel.contactDetails.phone;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Contact Restaurant',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Restaurant: ${restaurant.name}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (phoneNumber.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Phone: $phoneNumber',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final Uri phoneUri = Uri.parse('tel:$phoneNumber');
                      try {
                        if (await canLaunchUrl(phoneUri)) {
                          await launchUrl(phoneUri);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not launch phone app'),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error launching phone: $e'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final String firstPhone =
                          phoneNumber.split(',').first.trim();
                      final Uri whatsappUri = Uri.parse(
                        'https://wa.me/92${firstPhone.replaceAll(RegExp(r'[^\d]'), '')}',
                      );
                      try {
                        if (await canLaunchUrl(whatsappUri)) {
                          await launchUrl(whatsappUri);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not launch WhatsApp'),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error launching WhatsApp: $e'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Admin functionality handlers
  Future<void> _handleEditFoodItem(
      String itemType, String itemId, Map<String, dynamic> data) async {
    // TODO: Implement food item editing with proper bloc
    context.showSuccess('Food item editing will be implemented');
  }

  Future<void> _handleDeleteFoodItem(String itemType, String itemId) async {
    // TODO: Implement food item deletion with proper bloc
    context.showSuccess('Food item deletion will be implemented');
  }

  Future<void> _handleEditDeal(
      String itemType, String itemId, Map<String, dynamic> data) async {
    // TODO: Implement deal editing with proper bloc
    context.showSuccess('Deal editing will be implemented');
  }

  Future<void> _handleDeleteDeal(String itemType, String itemId) async {
    // TODO: Implement deal deletion with proper bloc
    context.showSuccess('Deal deletion will be implemented');
  }

  /// Handle when a new item is created
  void _handleItemCreated(String itemType, Map<String, dynamic> newItem) {
    if (!mounted) return;

    debugPrint(
        '📝 New $itemType created: ${newItem['id']} - ${newItem['name']}');

    if (itemType == 'restaurants') {
      // Trigger restaurant reload through BLoC
      context
          .read<RestaurantBloc>()
          .add(const RestaurantEvent.loadRestaurants());
    }
  }

  // Restaurant handlers using RestaurantBloc
  Future<void> _handleEditRestaurant(
      String itemType, String itemId, Map<String, dynamic> data) async {
    context.read<RestaurantBloc>().add(
          RestaurantEvent.updateRestaurant(
            id: itemId,
            name: data['name'] ?? '',
            description: data['description'],
            address: data['address'],
            phone: data['phone'],
            logoUrl: data['logo_url'],
          ),
        );
  }

  Future<void> _handleDeleteRestaurant(String itemType, String itemId) async {
    context.read<RestaurantBloc>().add(
          RestaurantEvent.deleteRestaurant(id: itemId),
        );
  }
}
