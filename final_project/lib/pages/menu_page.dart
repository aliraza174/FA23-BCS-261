import 'package:flutter/material.dart';
import 'menu_gallery_view.dart';
import '../widgets/animated_filter_chip.dart';
import '../widgets/animated_menu_card.dart';
import '../widgets/restaurant_menu_gallery.dart';
import '../widgets/menu_image_slider.dart';
import '../widgets/enhanced_header.dart';
import '../widgets/full_screen_header.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart' show getWebSafeTextStyle;
import '../core/widgets/admin_edit_overlay.dart';
import '../core/widgets/admin_toggle.dart';
import '../core/widgets/theme_toggle.dart';
import '../core/services/admin_data_service.dart';
import '../core/widgets/admin_fab.dart';
import '../core/providers/admin_mode_provider.dart';
import '../core/services/admin_crud_service.dart';
import '../core/utils/image_picker_util.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import '../utils/database_service.dart';
import '../theme/app_theme.dart';

class MenuItem {
  final String id;
  final String title;
  final List<String> images;
  final Color color;
  final List<String> categories;
  final List<String> searchTags;

  const MenuItem({
    required this.id,
    required this.title,
    required this.images,
    required this.color,
    required this.categories,
    required this.searchTags,
  });

  // Create MenuItem from database row with proper field mapping
  factory MenuItem.fromDatabase(Map<String, dynamic> data) {
    return MenuItem(
      id: data['id']?.toString() ?? '',
      title: data['name']?.toString() ?? 'Unknown Restaurant',
      images:
          data['image_url'] != null && data['image_url'].toString().isNotEmpty
              ? [data['image_url'].toString()]
              : ['assets/images/restaurant1.jpg'],
      color: Color(data['color'] ?? const Color(0xFFF5B041).value),
      categories: data['categories'] != null
          ? _parseCategories(data['categories'])
          : ['Fast Food'],
      searchTags: data['search_tags'] != null
          ? _parseSearchTags(data['search_tags'])
          : [],
    );
  }

  static List<String> _parseCategories(dynamic categoriesValue) {
    if (categoriesValue is List) {
      return List<String>.from(categoriesValue);
    } else if (categoriesValue is String) {
      return categoriesValue.split(',').map((s) => s.trim()).toList();
    }
    return ['Fast Food'];
  }

  static List<String> _parseSearchTags(dynamic searchTagsValue) {
    if (searchTagsValue is List) {
      return List<String>.from(searchTagsValue);
    } else if (searchTagsValue is String) {
      return searchTagsValue.split(',').map((s) => s.trim()).toList();
    }
    return [];
  }

  // Convert to database payload format (camelCase -> snake_case)
  Map<String, dynamic> toDatabase() {
    return {
      'name': title,
      'image_url': images.isNotEmpty ? images.first : '',
      'color': color.value,
      'categories': categories,
      'search_tags': searchTags,
    };
  }
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final String _searchQuery = '';
  String _selectedCategory = 'All';
  final bool _showMoreOptions = false;
  final TextEditingController _searchController = TextEditingController();
  final AdminDataService _adminDataService = AdminDataService();
  final AdminCRUDService _crudService = AdminCRUDService();

  List<MenuItem> _dynamicMenuItems = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final Color _allButtonColor = Colors.grey;
  final Color _fastFoodButtonColor = Colors.grey;
  final Color _desiFoodButtonColor = Colors.grey;
  final Color _pizzaButtonColor = Colors.grey;
  final Color _burgerButtonColor = Colors.grey;

  final TextStyle _headerTextStyle = getWebSafeTextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  final TextStyle _subHeaderTextStyle = getWebSafeTextStyle(
    fontSize: 20,
    color: Colors.white,
  );

  final TextStyle _buttonTextStyle = getWebSafeTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  final Color _headerGradientStart = const Color(0xFFF5B041).withOpacity(0.7);
  final Color _headerGradientEnd = Colors.black.withOpacity(0.5);

  final Color _buttonSelectedColor = const Color(0xFFF5B041);
  final Color _buttonUnselectedColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Load menu categories from database
      final menuCategories = await _crudService.getMenuCategories();

      // Load additional menu images from menu_images table
      List<dynamic> menuImages = [];
      try {
        final databaseService = DatabaseService();
        final images = await databaseService.getMenuImages();
        menuImages = images
            .map((img) {
              // Handle database JSON directly
              String imageName =
                  img['name']?.toString() ?? img['title']?.toString() ?? '';
              String imageUrl = img['image_url']?.toString() ??
                  img['imageUrl']?.toString() ??
                  '';

              return {
                'name': imageName,
                'image_url': imageUrl,
                'display_order': img['display_order'] ?? 0,
              };
            })
            .where((img) =>
                (img['name'] as String).isNotEmpty &&
                (img['image_url'] as String).isNotEmpty)
            .toList();
        debugPrint(
            '🖼️ Loaded ${menuImages.length} additional menu images from database');

        // Debug: Print all menu images loaded
        for (final img in menuImages) {
          debugPrint(
              '  📸 Menu image: "${img['name']}" -> ${img['image_url']}');
        }
      } catch (e) {
        debugPrint('❌ Failed to load menu images: $e');
        menuImages = [];
      }

      // COMPREHENSIVE DEBUG: Match menu images to specific menu items by name
      debugPrint(
          '🎯 COMPREHENSIVE DEBUG: Matching ${menuImages.length} menu images to ${menuCategories.length} menu categories');
      debugPrint('=== ALL MENU CATEGORIES ===');
      for (int i = 0; i < menuCategories.length; i++) {
        final cat = menuCategories[i];
        debugPrint(
            'Category $i: name="${cat['name']}", id="${cat['id']}", description="${cat['description']}"');
      }
      debugPrint('=== ALL MENU IMAGES ===');
      for (int i = 0; i < menuImages.length; i++) {
        final img = menuImages[i];
        debugPrint(
            'Image $i: name="${img['name']}", url="${img['image_url']}"');
      }
      debugPrint('=== STARTING NAME MATCHING ===');

      // Convert database items to MenuItem objects with matched images
      final List<MenuItem> dynamicItems = menuCategories.map((item) {
        // Get the base MenuItem from database
        final baseMenuItem = MenuItem.fromDatabase(item);
        final itemName = item['name']?.toString().toLowerCase().trim() ?? '';

        debugPrint('');
        debugPrint('🔍 Processing menu category: "$itemName"');
        debugPrint('   Original name from DB: "${item['name']}"');
        debugPrint('   Processed name: "$itemName"');
        debugPrint('   Base MenuItem images: ${baseMenuItem.images}');

        // Find matching images from menu_images table
        debugPrint(
            '   🔎 Searching for matches in ${menuImages.length} menu images...');

        final matchingImages = menuImages
            .where((img) {
              final imgName =
                  img['name']?.toString().toLowerCase().trim() ?? '';
              final originalImgName = img['name']?.toString() ?? '';

              debugPrint('      Comparing: "$imgName" vs "$itemName"');

              // ENHANCED NORMALIZATION: Remove common words and normalize
              String normalizeForMatching(String text) {
                return text
                    .toLowerCase()
                    .trim()
                    .replaceAll(
                        RegExp(r'\s+'), ' ') // Multiple spaces to single space
                    .replaceAll(
                        RegExp(r'[^\w\s]'), '') // Remove special characters
                    .replaceAll(
                        RegExp(
                            r'\b(menu|new|restaurant|hotel|the|and|bros?|brother)\b'),
                        '') // Remove common words
                    .replaceAll(RegExp(r'\s+'), ' ') // Clean up spaces again
                    .trim();
              }

              final normalizedImgName = normalizeForMatching(imgName);
              final normalizedItemName = normalizeForMatching(itemName);

              debugPrint('         Original img name: "$originalImgName"');
              debugPrint('         Processed img name: "$imgName"');
              debugPrint('         Normalized img name: "$normalizedImgName"');
              debugPrint(
                  '         Normalized item name: "$normalizedItemName"');

              // Try multiple matching strategies
              final exactMatch = imgName == itemName;
              final normalizedExactMatch =
                  normalizedImgName == normalizedItemName &&
                      normalizedImgName.isNotEmpty;
              final containsMatch =
                  imgName.contains(itemName) || itemName.contains(imgName);
              final normalizedContainsMatch =
                  (normalizedImgName.contains(normalizedItemName) ||
                          normalizedItemName.contains(normalizedImgName)) &&
                      normalizedImgName.isNotEmpty &&
                      normalizedItemName.isNotEmpty;

              // Word-based matching with improved logic
              final imgWords = normalizedImgName
                  .split(' ')
                  .where((w) => w.length > 2)
                  .toList();
              final itemWords = normalizedItemName
                  .split(' ')
                  .where((w) => w.length > 2)
                  .toList();

              bool wordMatch = false;
              int matchingWords = 0;
              if (imgWords.isNotEmpty && itemWords.isNotEmpty) {
                for (final imgWord in imgWords) {
                  for (final itemWord in itemWords) {
                    if (imgWord == itemWord) {
                      matchingWords++;
                      break;
                    }
                  }
                }
                wordMatch = matchingWords > 0 &&
                    (matchingWords >= (itemWords.length * 0.5).ceil());
              }

              // Fuzzy matching - check if one is a substring of the other after removing spaces
              final compactImgName = normalizedImgName.replaceAll(' ', '');
              final compactItemName = normalizedItemName.replaceAll(' ', '');
              final fuzzyMatch = (compactImgName.contains(compactItemName) ||
                      compactItemName.contains(compactImgName)) &&
                  compactImgName.isNotEmpty &&
                  compactItemName.isNotEmpty;

              final isMatch = exactMatch ||
                  normalizedExactMatch ||
                  containsMatch ||
                  normalizedContainsMatch ||
                  wordMatch ||
                  fuzzyMatch;

              debugPrint('         Exact match: $exactMatch');
              debugPrint(
                  '         Normalized exact match: $normalizedExactMatch');
              debugPrint('         Contains match: $containsMatch');
              debugPrint(
                  '         Normalized contains match: $normalizedContainsMatch');
              debugPrint(
                  '         Word match: $wordMatch ($matchingWords/${itemWords.length} words)');
              debugPrint('         Fuzzy match: $fuzzyMatch');
              debugPrint('         Final result: $isMatch');

              if (isMatch) {
                debugPrint(
                    '      ✅ MATCHED image: "$originalImgName" -> ${img['image_url']}');
              } else {
                debugPrint('      ❌ No match');
              }

              return isMatch;
            })
            .map((img) => img['image_url']?.toString() ?? '')
            .where((url) => url.isNotEmpty)
            .toList();

        // ENHANCED FALLBACK STRATEGIES: Multiple approaches for robust image display
        if (matchingImages.isEmpty && menuImages.isNotEmpty) {
          debugPrint(
              '   🔄 No specific matches found, trying fallback strategies...');

          // Strategy 1: Try partial word matching with lower threshold
          debugPrint('   📋 Fallback Strategy 1: Relaxed word matching');
          final relaxedMatches = menuImages
              .where((img) {
                final imgName =
                    img['name']?.toString().toLowerCase().trim() ?? '';
                final imgWords =
                    imgName.split(' ').where((w) => w.length > 1).toList();
                final itemWords =
                    itemName.split(' ').where((w) => w.length > 1).toList();

                for (final imgWord in imgWords) {
                  for (final itemWord in itemWords) {
                    if (imgWord.contains(itemWord) ||
                        itemWord.contains(imgWord)) {
                      debugPrint(
                          '      📌 Relaxed match found: "$imgWord" ~ "$itemWord"');
                      return true;
                    }
                  }
                }
                return false;
              })
              .map((img) => img['image_url']?.toString() ?? '')
              .where((url) => url.isNotEmpty)
              .toList();

          if (relaxedMatches.isNotEmpty) {
            debugPrint(
                '   ✅ Found ${relaxedMatches.length} images via relaxed matching');
            matchingImages.addAll(relaxedMatches);
          }

          // Strategy 2: If still no matches, add images with similar length names
          if (matchingImages.isEmpty) {
            debugPrint(
                '   📋 Fallback Strategy 2: Similar name length matching');
            final targetLength = itemName.length;
            final lengthMatches = menuImages
                .where((img) {
                  final imgName =
                      img['name']?.toString().toLowerCase().trim() ?? '';
                  final lengthDiff = (imgName.length - targetLength).abs();
                  return lengthDiff <=
                      5; // Names within 5 characters of each other
                })
                .take(3)
                .map((img) => img['image_url']?.toString() ?? '')
                .where((url) => url.isNotEmpty)
                .toList();

            if (lengthMatches.isNotEmpty) {
              debugPrint(
                  '   ✅ Found ${lengthMatches.length} images via length matching');
              matchingImages.addAll(lengthMatches);
            }
          }

          // Strategy 3: Last resort - add all available menu images if we have very few items
          if (matchingImages.isEmpty && menuImages.length <= 5) {
            debugPrint(
                '   📋 Fallback Strategy 3: Adding all available images (${menuImages.length} total)');
            final allMenuImages = menuImages
                .map((img) => img['image_url']?.toString() ?? '')
                .where((url) => url.isNotEmpty)
                .toList();
            matchingImages.addAll(allMenuImages);
            debugPrint(
                '   ✅ Added all ${allMenuImages.length} available menu images');
          }

          // Strategy 4: Ultimate fallback - add first few images
          if (matchingImages.isEmpty) {
            debugPrint(
                '   📋 Fallback Strategy 4: Adding first menu image as ultimate fallback');
            final fallbackImage =
                menuImages.first['image_url']?.toString() ?? '';
            if (fallbackImage.isNotEmpty) {
              matchingImages.add(fallbackImage);
              debugPrint('   ✅ Added fallback image: $fallbackImage');
            }
          }

          debugPrint(
              '   🎯 Total fallback images added: ${matchingImages.length}');
        }

        // Combine base image with matching images, ensuring no duplicates
        final Set<String> imageUrls = {};

        // Add base images first
        for (final url in baseMenuItem.images) {
          if (url.isNotEmpty) {
            imageUrls.add(url);
          }
        }

        // Add matching images, avoiding duplicates
        for (final url in matchingImages) {
          if (url.isNotEmpty && !imageUrls.contains(url)) {
            imageUrls.add(url);
          }
        }

        final allImages = imageUrls.toList();

        debugPrint(
            '   🎯 Final images for "$itemName": ${allImages.length} total');
        debugPrint('   📋 All final URLs: $allImages');
        debugPrint('   🎨 Base color: ${baseMenuItem.color}');
        debugPrint('   🏷️ Categories: ${baseMenuItem.categories}');
        debugPrint('   🔍 Search tags: ${baseMenuItem.searchTags}');

        // Create enhanced MenuItem with matched images
        final finalMenuItem = MenuItem(
          id: baseMenuItem.id,
          title: baseMenuItem.title,
          images: allImages,
          color: baseMenuItem.color,
          categories: baseMenuItem.categories,
          searchTags: baseMenuItem.searchTags,
        );

        debugPrint(
            '   🎯 Created MenuItem with ${finalMenuItem.images.length} images');
        return finalMenuItem;
      }).toList();

      setState(() {
        _dynamicMenuItems = dynamicItems;
        _isLoading = false;
      });

      debugPrint('');
      debugPrint(
          '✅ Loaded ${dynamicItems.length} menu categories from database');
      debugPrint('📊 FINAL COMPREHENSIVE SUMMARY:');
      debugPrint('=== GALLERY DISPLAY RESULTS ===');

      // Debug: Print detailed info for each item with emphasis on gallery functionality
      for (int i = 0; i < dynamicItems.length; i++) {
        final item = dynamicItems[i];
        debugPrint('');
        debugPrint('MenuItem ${i + 1}/${dynamicItems.length}: "${item.title}"');
        debugPrint('   🆔 ID: ${item.id}');
        debugPrint('   📸 Total Images: ${item.images.length}');
        debugPrint(
            '   🖼️ Gallery will show: ${item.images.length}/${item.images.length}');
        if (item.images.length > 1) {
          debugPrint('   🎯 MULTIPLE IMAGES DETECTED - Gallery should work!');
        } else {
          debugPrint('   ⚠️  SINGLE IMAGE - Gallery will show 1/1');
        }
        for (int j = 0; j < item.images.length; j++) {
          debugPrint('      Image ${j + 1}: ${item.images[j]}');
        }
        debugPrint('   🏷️ Categories: ${item.categories}');
        debugPrint('   🔍 Search Tags: ${item.searchTags}');
        debugPrint('   🎨 Color: ${item.color}');
        debugPrint('   ==========================================');
      }

      debugPrint('');
      debugPrint('🔍 TROUBLESHOOTING INFO:');
      debugPrint('   Total menu categories: ${menuCategories.length}');
      debugPrint('   Total menu images: ${menuImages.length}');
      debugPrint('   Successfully created MenuItems: ${dynamicItems.length}');
      debugPrint(
          '   MenuItems with multiple images: ${dynamicItems.where((item) => item.images.length > 1).length}');
      debugPrint(
          '   MenuItems with single image: ${dynamicItems.where((item) => item.images.length == 1).length}');
      debugPrint('=== END DEBUG LOGGING ===');

      // If no dynamic items found, use static items as fallback
      if (dynamicItems.isEmpty) {
        setState(() {
          _dynamicMenuItems = allMenuItems;
        });
        debugPrint('No dynamic menu items found, using static fallback');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading menu categories: $e';
        _isLoading = false;
        _dynamicMenuItems = allMenuItems; // Fallback to static data
      });
      debugPrint('Error loading menu categories: $e');
    }
  }

  final List<MenuItem> allMenuItems = [
    const MenuItem(
      id: 'static-1',
      title: 'Pizza Slice',
      images: [
        'assets/images/pizzaslice1.jpg',
        'assets/images/pizzaslice2.jpg'
      ],
      color: Color(0xFFFF8C00),
      categories: ['Pizza'],
      searchTags: ['pizza slice', 'pizzas', 'fast food'],
    ),
    const MenuItem(
      id: 'static-2',
      title: 'Khana Khazana',
      images: [
        'assets/images/khanakhazana1.jpg',
        'assets/images/khanakhazana2.jpg'
      ],
      color: Color(0xFF4CAF50),
      categories: ['Desi'],
      searchTags: ['khana khazana', 'desi food'],
    ),
    const MenuItem(
      id: 'static-3',
      title: 'Meet N Eat',
      images: ['assets/images/meetneat1.jpg', 'assets/images/meetneat2.jpg'],
      color: Color(0xFF2196F3),
      categories: ['Fast Food'],
      searchTags: ['meet n eat', 'fast food'],
    ),
    const MenuItem(
      id: 'static-4',
      title: 'Crust Bros Menu',
      images: ['assets/images/crustbros1.jpg', 'assets/images/CrustBros2.jpg'],
      color: Color(0xFFFF8C00),
      categories: ['Pizza', 'Burger', 'Pasta'],
      searchTags: [
        'crust bros',
        'pizza',
        'burger',
        'pasta',
        'fries',
        'calzone',
        'chunks',
        'shawarma',
        'wraps',
        'mexican wraps',
        'wings',
        'special platter',
        'hot shots',
        'sandwiches',
        'fast food'
      ],
    ),
    const MenuItem(
      id: 'static-5',
      title: 'Meeran Jee Restaurant Menu',
      images: ['assets/images/mfc.jpg', 'assets/images/mfc2.jpg'],
      color: Color(0xFF2196F3),
      categories: ['Pizza', 'Burger'],
      searchTags: ['meeran jee', 'pizza', 'burger', 'fast food'],
    ),
    const MenuItem(
      id: 'static-6',
      title: 'EatWay Menu',
      images: ['assets/images/eatway1.jpg', 'assets/images/eatway2.jpg'],
      color: Color(0xFF4CAF50),
      categories: ['Pizza', 'Burger'],
      searchTags: ['eatway', 'pizza', 'burger', 'fast food'],
    ),
    const MenuItem(
      id: 'static-7',
      title: 'Nawab Hotel Menu',
      images: [
        'assets/images/nawab.jpg',
        'assets/images/nawab1.jpg',
        'assets/images/nawab2.jpg',
        'assets/images/nawab3.jpg'
      ],
      color: Color(0xFFE91E63),
      categories: ['Desi'],
      searchTags: [
        'nawab hotel',
        'desi food',
        'karhai',
        'chicken',
        'chinese',
        'pulao',
        'biryani',
        'rice',
        'soup',
        'bbq',
        'ice cream',
        'hot drinks',
        'traditional'
      ],
    ),
  ];

  List<MenuItem> get filteredMenuItems {
    final List<MenuItem> itemsToFilter =
        _dynamicMenuItems.isNotEmpty ? _dynamicMenuItems : allMenuItems;

    if (_selectedCategory == 'All') {
      return itemsToFilter;
    } else if (_selectedCategory == 'Fast Food') {
      return itemsToFilter
          .where((item) => item.categories.contains('Fast Food'))
          .toList();
    } else if (_selectedCategory == 'Desi Food') {
      return itemsToFilter
          .where((item) =>
              item.categories.contains('Desi Food') ||
              item.categories.contains('Desi'))
          .toList();
    } else if (_selectedCategory == 'Pizza') {
      return itemsToFilter
          .where((item) => item.categories.contains('Pizza'))
          .toList();
    } else if (_selectedCategory == 'Burger') {
      return itemsToFilter
          .where((item) => item.categories.contains('Burger'))
          .toList();
    }
    return itemsToFilter;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = AppTheme.backgroundColor(context);
    final isDarkMode = AppTheme.isDarkMode(context);
    final buttonSelectedColor = AppTheme.getButtonSelectedColor(context);
    final buttonUnselectedColor = AppTheme.getButtonUnselectedColor(context);
    final cardColor = AppTheme.cardColor(context);
    final textColor = AppTheme.textColor(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: Consumer<AdminModeProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isAdminLoggedIn &&
              adminProvider.isEditModeEnabled) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Refresh button
                FloatingActionButton(
                  onPressed: () async {
                    debugPrint('🔄 Manual refresh triggered');
                    await _loadMenuItems();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Menu refreshed!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  heroTag: 'refresh_fab',
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 16),
                // Add menu button
                FloatingActionButton.extended(
                  onPressed: () => _showCreateMenuItemDialog(),
                  backgroundColor: const Color(0xFFF5B041),
                  foregroundColor: Colors.white,
                  elevation: 8,
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant_menu, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add Menu',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  heroTag: 'admin_fab_menu',
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: Column(
        children: [
          // Full-Screen Header with Pizza Background
          Stack(
            children: [
              FullScreenHeader(
                title: 'Restaurant Menus',
                subtitle: 'Explore delicious food options',
                backgroundImage: 'assets/images/pizza_bg.jpg',
                height: MediaQuery.of(context).size.width < 600
                    ? 240
                    : 300, // Responsive height
                overlayColors: [
                  const Color(0xFFF5B041).withOpacity(0.15), // Orange
                  const Color(0xFFE67E22).withOpacity(0.25), // Darker orange
                  const Color(0xFFFF8C00).withOpacity(0.20), // Light orange
                ],
              ),
              // Theme toggle and Admin toggle positioned over the header
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 20,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Theme toggle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const ThemeToggle(compact: true),
                    ),
                    const SizedBox(width: 8),
                    // Admin toggle
                    Consumer<AdminModeProvider>(
                      builder: (context, adminProvider, child) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const AdminToggle(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Enhanced Filter Buttons
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'All';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedCategory == 'All'
                          ? buttonSelectedColor
                          : buttonUnselectedColor,
                      foregroundColor:
                          _selectedCategory == 'All' ? Colors.white : textColor,
                      elevation: isDarkMode ? 2 : 8,
                      shadowColor: isDarkMode ? Colors.black54 : Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                        side: BorderSide(
                            color: buttonSelectedColor.withOpacity(0.5),
                            width: 1),
                      ),
                    ),
                    child: Text(
                      'All',
                      style: _buttonTextStyle,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'Fast Food';
                      });
                    },
                    icon: Image.asset(
                      'assets/images/pizza_icon.png',
                      height: 18,
                      width: 18,
                    ),
                    label: Text(
                      'Fast Food',
                      style: _buttonTextStyle,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedCategory == 'Fast Food'
                          ? buttonSelectedColor
                          : buttonUnselectedColor,
                      foregroundColor: _selectedCategory == 'Fast Food'
                          ? Colors.white
                          : textColor,
                      elevation: isDarkMode ? 2 : 8,
                      shadowColor: isDarkMode ? Colors.black54 : Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                        side: BorderSide(
                            color: buttonSelectedColor.withOpacity(0.5),
                            width: 1),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'Desi Food';
                      });
                    },
                    icon: Image.asset(
                      'assets/images/biryani_icon.png',
                      height: 18,
                      width: 18,
                    ),
                    label: Text(
                      'Desi Food',
                      style: _buttonTextStyle,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedCategory == 'Desi Food'
                          ? buttonSelectedColor
                          : buttonUnselectedColor,
                      foregroundColor: _selectedCategory == 'Desi Food'
                          ? Colors.white
                          : textColor,
                      elevation: isDarkMode ? 2 : 8,
                      shadowColor: isDarkMode ? Colors.black54 : Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                        side: BorderSide(
                            color: buttonSelectedColor.withOpacity(0.5),
                            width: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Restaurant Grid with Loading State
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFFF5B041),
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading menu items...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading menu items',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMenuItems,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF5B041),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMenuItems,
                        child: GridView.count(
                          crossAxisCount: 2,
                          padding: const EdgeInsets.all(16),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.85,
                          children: filteredMenuItems
                              .map((item) => _buildRestaurantCard(item))
                              .toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(
          Icons.restaurant,
          size: 40,
          color: Colors.grey,
        ),
      );
    }

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(
              Icons.restaurant,
              size: 40,
              color: Colors.grey,
            ),
          );
        },
      );
    } else if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(
              Icons.restaurant,
              size: 40,
              color: Colors.grey,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFF5B041),
              ),
            ),
          );
        },
      );
    } else {
      // Invalid URL, show fallback
      return Container(
        color: Colors.grey[300],
        child: const Icon(
          Icons.restaurant,
          size: 40,
          color: Colors.grey,
        ),
      );
    }
  }

  Widget _buildRestaurantCard(MenuItem item) {
    // Convert MenuItem to Map for AdminEditOverlay with proper snake_case keys
    final Map<String, dynamic> itemData = {
      'name': item.title,
      'categories': item.categories,
      'search_tags': item.searchTags,
      'image_url': item.images.isNotEmpty ? item.images.first : '',
      'color': item.color.value,
    };

    return AdminEditOverlay(
      itemId: item.id, // Use proper database ID
      itemType: 'menu_categories', // Use proper table name
      itemData: itemData,
      onEdit: _handleEditMenuItem,
      onDelete: _handleDeleteMenuItem,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MenuGalleryView(
                  title: item.title.replaceAll(' Menu', ''),
                  images: item.images,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(item.images[0]),
                      // Cool gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.3),
                              item.color.withOpacity(0.5),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      // Multiple images indicator
                      if (item.images.length > 1)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.photo_library,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.images.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.replaceAll(' Menu', ''),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color.fromARGB(255, 248, 202, 20),
                          size: 16,
                        ),
                        Text(
                          item.title == 'Pizza Slice'
                              ? ' 4.6'
                              : item.title == 'Meet N Eat'
                                  ? ' 4.7'
                                  : item.title == 'Khana Khazana'
                                      ? ' 4.7'
                                      : item.title == 'Nawab Hotel Menu'
                                          ? ' 4.1'
                                          : item.title == 'EatWay Menu'
                                              ? ' 4.3'
                                              : item.title ==
                                                      'Meeran Jee Restaurant Menu'
                                                  ? ' 4.2'
                                                  : item.title ==
                                                          'Crust Bros Menu'
                                                      ? ' 4.3'
                                                      : ' 4.5',
                          style: const TextStyle(
                            color: Color.fromARGB(190, 117, 117, 117),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on,
                            color: Color.fromARGB(188, 117, 117, 117),
                            size: 16),
                        Expanded(
                          child: Text(
                            item.title == 'Crust Bros Menu'
                                ? 'Loha Bazar, Jahanian'
                                : item.title == 'EatWay Menu'
                                    ? 'Rehmat Villas, Phase 1, Canal Road, Jahanian'
                                    : item.title == 'Meeran Jee Restaurant Menu'
                                        ? 'Branch 1: Near Ice Factory Rahim Shah Road, Jahanian'
                                        : item.title == 'Nawab Hotel Menu'
                                            ? 'Bypass'
                                            : item.title == 'Pizza Slice'
                                                ? 'Main Khanewall Highway Road Infront of Qudas Masjid Jahanian'
                                                : item.title == 'Khana Khazana'
                                                    ? 'Main Super Highway Bahawal Pur Road Near Total Petrol Pump Jahanian'
                                                    : item.title == 'Meet N Eat'
                                                        ? 'Opposite Nadra Office, Multan Road, Jahanian'
                                                        : 'Bypass',
                            style: const TextStyle(
                              color: Color.fromARGB(181, 103, 102, 102),
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  // Menu item handlers - Use AdminCRUDService directly for consistency
  Future<void> _handleEditMenuItem(
      String itemType, String itemId, Map<String, dynamic> data) async {
    debugPrint(
        'Ã°Å¸ÂÂ½Ã¯Â¸Â Attempting to update menu item: $itemId with data: $data');

    try {
      final success = await _crudService.updateMenuCategory(itemId, data);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Menu category updated successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Reload menu items to show the updated item
        await _loadMenuItems();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Failed to update menu category. Please try again.'),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Exception in _handleEditMenuItem: $e');
      debugPrint(
          'Ã°Å¸â€œÂ± Mobile Debug - Menu edit error type: ${e.runtimeType}');

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
            backgroundColor: const Color(0xFFF5B041),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteMenuItem(String itemType, String itemId) async {
    debugPrint('Ã°Å¸ÂÂ½Ã¯Â¸Â Attempting to delete menu item: $itemId');

    try {
      final success = await _crudService.deleteMenuCategory(itemId);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Menu category deleted successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Reload menu items to reflect the deletion
        await _loadMenuItems();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Failed to delete menu category. Please try again.'),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Exception in _handleDeleteMenuItem: $e');
      debugPrint(
          'Ã°Å¸â€œÂ± Mobile Debug - Menu delete error type: ${e.runtimeType}');

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
            backgroundColor: const Color(0xFFF5B041),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Show create menu item dialog
  void _showCreateMenuItemDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateMenuItemDialog(
        onMenuItemCreated: _handleMenuItemCreated,
        adminCRUDService: _crudService,
      ),
    );
  }

  // Handle new menu item creation - Use AdminCRUDService for consistency
  Future<void> _handleMenuItemCreated(Map<String, dynamic> menuItemData) async {
    try {
      final result = await _crudService.createMenuCategory(
        name: menuItemData['name'],
        description: menuItemData['description'] ?? 'New menu category',
        imageUrl: menuItemData['imageUrl'],
        sortOrder: allMenuItems.length + 1,
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        'New menu category "${menuItemData['name']}" created successfully!')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Reload menu items to show the new item
        await _loadMenuItems();
      } else {
        throw Exception('Failed to create menu category');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error creating menu category: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Create Menu Item Dialog Widget
class _CreateMenuItemDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onMenuItemCreated;
  final AdminCRUDService adminCRUDService;

  const _CreateMenuItemDialog({
    required this.onMenuItemCreated,
    required this.adminCRUDService,
  });

  @override
  State<_CreateMenuItemDialog> createState() => _CreateMenuItemDialogState();
}

class _CreateMenuItemDialogState extends State<_CreateMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _searchTagsController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  double _rating = 4.0;
  Color _selectedColor = const Color(0xFFF5B041);
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _selectedPreviews = [];
  bool _isUploading = false;

  final List<String> _categories = [
    'Fast Food',
    'Desi Food',
    'Pizza',
    'Burger'
  ];
  final Set<String> _selectedCategories = {};

  final List<Color> _colorOptions = [
    const Color(0xFFF5B041),
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF5B041),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_menu,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add New Restaurant Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Restaurant Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Restaurant Name *',
                          hintText: 'Enter restaurant name',
                          prefixIcon: const Icon(Icons.restaurant),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Restaurant name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Brief description of the restaurant',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Address
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          hintText: 'Restaurant location',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Categories Section
                      const Text(
                        'Categories',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _categories.map((category) {
                          final isSelected =
                              _selectedCategories.contains(category);
                          return FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                              });
                            },
                            selectedColor:
                                const Color(0xFFF5B041).withOpacity(0.3),
                            checkmarkColor: const Color(0xFFF5B041),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Search Tags
                      TextFormField(
                        controller: _searchTagsController,
                        decoration: InputDecoration(
                          labelText: 'Search Tags',
                          hintText:
                              'pizza, burger, fast food (comma-separated)',
                          prefixIcon: const Icon(Icons.tag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Rating Section
                      const Text(
                        'Rating',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 24,
                            );
                          }),
                          const SizedBox(width: 12),
                          Text(
                            _rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Slider(
                        value: _rating,
                        min: 1.0,
                        max: 5.0,
                        divisions: 40,
                        activeColor: const Color(0xFFF5B041),
                        onChanged: (value) {
                          setState(() {
                            _rating = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Color Theme Section
                      const Text(
                        'Color Theme',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _colorOptions.map((color) {
                          final isSelected = _selectedColor == color;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = color;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.grey.shade300,
                                  width: isSelected ? 3 : 1,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Menu Images Upload Section
                      const Text(
                        'Menu Images',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.shade300, width: 2),
                            ),
                            child: _selectedPreviews.isNotEmpty
                                ? Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(
                                        _selectedPreviews.length, (index) {
                                      final bytes = _selectedPreviews[index];
                                      return Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.memory(
                                              bytes,
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: -6,
                                            right: -6,
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _selectedPreviews
                                                      .removeAt(index);
                                                  _selectedImages
                                                      .removeAt(index);
                                                });
                                              },
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                padding:
                                                    const EdgeInsets.all(4),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cloud_upload,
                                          size: 40, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text('Add menu images',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Text('JPG, PNG supported',
                                          style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12)),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _pickFromGalleryMulti,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF5B041),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Add from Gallery'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _captureFromCamera,
                                  icon: const Icon(Icons.camera_alt,
                                      color: Colors.black87),
                                  label: const Text('Camera',
                                      style: TextStyle(color: Colors.black87)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ), // Action Buttons
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(20)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed:
                                    _isUploading ? null : _createMenuItem,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF5B041),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isUploading
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Create Menu',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createMenuItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category'),
          backgroundColor: Color(0xFFF5B041),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload selected images (if any) to Supabase
      final List<String> uploadedUrls = [];
      if (_selectedImages.isNotEmpty) {
        final nameSlug = _nameController.text.trim().isEmpty
            ? 'menu'
            : _nameController.text
                .trim()
                .toLowerCase()
                .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                .replaceAll(RegExp(r'-+'), '-');
        final folder = 'restaurant-menus/$nameSlug';
        final supabase = Supabase.instance.client;

        for (int i = 0; i < _selectedImages.length; i++) {
          final x = _selectedImages[i];
          final bytes = await x.readAsBytes();
          final sanitizedName =
              x.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\._-]+'), '-');
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
          final filePath = '$folder/$fileName';
          await supabase.storage.from('public').uploadBinary(filePath, bytes);
          final url = supabase.storage.from('public').getPublicUrl(filePath);
          uploadedUrls.add(url);
        }
      }

      final String? coverUrl =
          uploadedUrls.isNotEmpty ? uploadedUrls.first : null;

      // Create menu item data
      final menuItemName = _nameController.text.trim().isEmpty
          ? 'New Menu Item'
          : _nameController.text.trim();

      final menuItemData = {
        'name': menuItemName,
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'categories': _selectedCategories.toList(),
        'searchTags': _searchTagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
        'rating': _rating,
        'color': _selectedColor.value,
        'imageUrl': coverUrl ?? '',
      };

      // Call the parent callback
      widget.onMenuItemCreated(menuItemData);

      // Persist gallery rows
      if (uploadedUrls.isNotEmpty) {
        debugPrint(
            '🍽️ Creating ${uploadedUrls.length} menu_images entries with name: "$menuItemName"');

        for (int i = 0; i < uploadedUrls.length; i++) {
          try {
            await widget.adminCRUDService.createItem('menu_images', {
              'name': menuItemName,
              'image_url': uploadedUrls[i],
              'display_order': i,
            });
            debugPrint(
                '✅ Successfully created menu_image ${i + 1}/${uploadedUrls.length}');
          } catch (e) {
            debugPrint('❌ Failed to create menu_image ${i + 1}: $e');
            // Continue with other images even if one fails
          }
        }
      }

      // Close dialog
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating menu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Multi-image helpers
  Future<void> _pickFromGalleryMulti() async {
    try {
      final images = await _imagePicker.pickMultiImage(
          imageQuality: 85, maxWidth: 1920, maxHeight: 1080);
      if (images.isNotEmpty) {
        final previews = <Uint8List>[];
        for (final img in images) {
          previews.add(await img.readAsBytes());
        }
        setState(() {
          _selectedImages.addAll(images);
          _selectedPreviews.addAll(previews);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to pick images: $e')));
      }
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      final image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImages.add(image);
          _selectedPreviews.add(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to capture image: $e')));
      }
    }
  }
}
