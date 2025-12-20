import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../services/admin_crud_service.dart';
import '../services/hybrid_image_service.dart';
import 'restaurant_selector.dart';

/// Universal create overlay for adding new items
/// Supports food_items, deals, restaurants, menu_categories
class AdminCreateOverlay extends StatefulWidget {
  final String itemType;
  final Function(String itemType, Map<String, dynamic> newItem)? onCreate;

  const AdminCreateOverlay({
    super.key,
    required this.itemType,
    this.onCreate,
  });

  @override
  State<AdminCreateOverlay> createState() => _AdminCreateOverlayState();
}

class _AdminCreateOverlayState extends State<AdminCreateOverlay>
    with SingleTickerProviderStateMixin {
  final AdminCRUDService _crudService = AdminCRUDService();
  final HybridImageService _imageService = HybridImageService();
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  String? _selectedImageUrl;
  final List<String> _selectedImageUrls = []; // Support multiple images for deals
  bool _isLoading = false;

  // Item type specific fields
  Map<String, dynamic> get _fieldDefinitions => {
    'food_items': {
      'name': {'label': 'Item Name', 'required': true, 'icon': Icons.restaurant_menu},
      'description': {'label': 'Description', 'required': true, 'icon': Icons.description, 'maxLines': 3},
      'price': {'label': 'Price (Rs.)', 'required': true, 'icon': Icons.monetization_on, 'keyboardType': TextInputType.number},
      'restaurant': {'label': 'Restaurant Name', 'required': true, 'icon': Icons.store, 'hint': 'Must match existing restaurant name'},
    },
    'deals': {
      'title': {'label': 'Deal Title', 'required': true, 'icon': Icons.local_offer},
      'description': {'label': 'Deal Description', 'required': true, 'icon': Icons.description, 'maxLines': 3},
      'price': {'label': 'Deal Price (Rs.)', 'required': true, 'icon': Icons.monetization_on, 'keyboardType': TextInputType.number},
      'discount_percentage': {'label': 'Discount %', 'required': false, 'icon': Icons.percent, 'keyboardType': TextInputType.number},
    },
    'restaurants': {
      'name': {'label': 'Restaurant Name', 'required': true, 'icon': Icons.restaurant},
      'description': {'label': 'Description', 'required': true, 'icon': Icons.description, 'maxLines': 3},
      'address': {'label': 'Address', 'required': true, 'icon': Icons.location_on},
      'contact_number': {'label': 'Contact Number', 'required': true, 'icon': Icons.phone, 'keyboardType': TextInputType.phone},
      'phone': {'label': 'Alternative Phone', 'required': false, 'icon': Icons.phone_android, 'keyboardType': TextInputType.phone},
      'rating': {'label': 'Rating (1-5)', 'required': false, 'icon': Icons.star, 'keyboardType': const TextInputType.numberWithOptions(decimal: true)},
    },
    'menu_categories': {
      'name': {'label': 'Category Name', 'required': true, 'icon': Icons.category},
      'description': {'label': 'Category Description', 'required': true, 'icon': Icons.description, 'maxLines': 2},
      'sort_order': {'label': 'Sort Order', 'required': false, 'icon': Icons.sort, 'keyboardType': TextInputType.number},
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeControllers();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _animationController.forward();
  }

  void _initializeControllers() {
    final fields = _fieldDefinitions[widget.itemType] as Map<String, dynamic>;
    for (String fieldName in fields.keys) {
      _controllers[fieldName] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  String get _dialogTitle {
    switch (widget.itemType) {
      case 'food_items':
        return 'Add New Food Item';
      case 'deals':
        return 'Create New Deal';
      case 'restaurants':
        return 'Add New Restaurant';
      case 'menu_categories':
        return 'Create Menu Category';
      default:
        return 'Add New Item';
    }
  }

  IconData get _dialogIcon {
    switch (widget.itemType) {
      case 'food_items':
        return Icons.restaurant_menu;
      case 'deals':
        return Icons.local_offer;
      case 'restaurants':
        return Icons.restaurant;
      case 'menu_categories':
        return Icons.category;
      default:
        return Icons.add;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: _buildDialogContent(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.9,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: 24),
                    ..._buildFormFields(),
                  ],
                ),
              ),
            ),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _dialogIcon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dialogTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fill in the details below to create a new ${widget.itemType.replaceAll('_', ' ')}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    // Check if this is a deals item type for multiple image support
    final bool isDeals = widget.itemType == 'deals';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_camera, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                isDeals ? 'Images (Multiple)' : 'Image (Optional)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isDeals) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          
          // Multiple images support for deals
          if (isDeals) ...[
            if (_selectedImageUrls.isNotEmpty) ...[
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _selectedImageUrls[index].startsWith('http')
                                ? Image.network(
                                    _selectedImageUrls[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                                  )
                                : _buildImagePlaceholder(),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImageAtIndex(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickMultipleImages,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add_a_photo, size: 20),
                    label: Text('Add Images (${_selectedImageUrls.length}/5)'),
                  ),
                ),
                if (_selectedImageUrls.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _selectedImageUrls.clear()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear All'),
                  ),
                ],
              ],
            ),
          ] else ...[
            // Single image support for other item types
            if (_selectedImageUrl != null) ...[
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _selectedImageUrl!.startsWith('http')
                      ? Image.network(
                          _selectedImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add_a_photo, size: 20),
                    label: Text(_selectedImageUrl == null ? 'Add Image' : 'Change Image'),
                  ),
                ),
                if (_selectedImageUrl != null) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _selectedImageUrl = null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Remove'),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 50,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Image Preview',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFormFields() {
    final fields = _fieldDefinitions[widget.itemType] as Map<String, dynamic>;
    return fields.entries.map((entry) {
      final fieldName = entry.key;
      final config = entry.value as Map<String, dynamic>;
      
      // Special handling for restaurant field in food items
      if (widget.itemType == 'food_items' && fieldName == 'restaurant') {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: RestaurantSelector(
            controller: _controllers[fieldName]!,
            validator: (value) {
              if (config['required'] && (value == null || value.trim().isEmpty)) {
                return 'Please select or enter a restaurant name';
              }
              return null;
            },
            onChanged: (value) {
              // Optional: Add any additional logic when restaurant changes
              debugPrint('🏠 Restaurant field changed to: $value');
            },
          ),
        );
      }
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: _controllers[fieldName],
          decoration: InputDecoration(
            labelText: config['label'],
            hintText: config['hint'],
            prefixIcon: Icon(config['icon'], color: Colors.orange),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLines: config['maxLines'] ?? 1,
          keyboardType: config['keyboardType'],
          validator: (value) {
            if (config['required'] && (value == null || value.trim().isEmpty)) {
              return 'This field is required';
            }
            
            // Special validation for specific fields
            if (fieldName == 'price' && value != null && value.isNotEmpty) {
              final price = double.tryParse(value);
              if (price == null) {
                return 'Please enter a valid number';
              }
              if (price <= 0) {
                return 'Price must be greater than 0';
              }
              if (price > 99999) {
                return 'Price seems too high, please check';
              }
            }
            
            if (fieldName == 'rating' && value != null && value.isNotEmpty) {
              final rating = double.tryParse(value);
              if (rating == null || rating < 1 || rating > 5) {
                return 'Rating must be between 1 and 5';
              }
            }

            if (fieldName == 'name' && value != null && value.isNotEmpty) {
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              if (value.trim().length > 100) {
                return 'Name is too long (max 100 characters)';
              }
            }

            if (fieldName == 'description' && value != null && value.isNotEmpty) {
              if (value.trim().length < 5) {
                return 'Description must be at least 5 characters';
              }
            }
            
            return null;
          },
        ),
      );
    }).toList();
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Create Item',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final imageUrl = await _imageService.selectAndProcessImage(
        context,
        folder: widget.itemType,
      );
      
      if (imageUrl != null) {
        setState(() {
          _selectedImageUrl = imageUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickMultipleImages() async {
    if (_selectedImageUrls.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 images allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final imageUrl = await _imageService.selectAndProcessImage(
        context,
        folder: widget.itemType,
      );
      
      if (imageUrl != null && !_selectedImageUrls.contains(imageUrl)) {
        setState(() {
          _selectedImageUrls.add(imageUrl);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImageAtIndex(int index) {
    if (index >= 0 && index < _selectedImageUrls.length) {
      setState(() {
        _selectedImageUrls.removeAt(index);
      });
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('🚀 Creating ${widget.itemType} item...');
      
      // Collect form data
      final formData = <String, dynamic>{};
      _controllers.forEach((fieldName, controller) {
        if (controller.text.trim().isNotEmpty) {
          // Handle special data types
          if (fieldName == 'price' || fieldName == 'rating') {
            formData[fieldName] = double.tryParse(controller.text);
          } else if (fieldName == 'discount_percentage' || fieldName == 'sort_order') {
            formData[fieldName] = int.tryParse(controller.text);
          } else {
            formData[fieldName] = controller.text.trim();
          }
        }
      });

      // Add image URL(s) if selected
      if (widget.itemType == 'deals') {
        // For deals, use multiple images if available, otherwise fallback to single image
        if (_selectedImageUrls.isNotEmpty) {
          formData['image_urls'] = _selectedImageUrls;
          formData['image_url'] = _selectedImageUrls.first; // Primary image for backward compatibility
        } else if (_selectedImageUrl != null) {
          formData['image_url'] = _selectedImageUrl;
          formData['image_urls'] = [_selectedImageUrl];
        }
      } else {
        // For other item types, use single image
        if (_selectedImageUrl != null) {
          formData['image_url'] = _selectedImageUrl;
        }
      }

      debugPrint('🚀 Creating ${widget.itemType} with form data: ${formData.keys.join(', ')}');
      debugPrint('🔍 Full form data: $formData');

      // Create the item using the appropriate service method
      Map<String, dynamic>? newItem;
      switch (widget.itemType) {
        case 'food_items':
          newItem = await _crudService.createFoodItem(
            name: formData['name'],
            description: formData['description'],
            price: formData['price'],
            restaurant: formData['restaurant'],
            imageUrl: _selectedImageUrl,
          );
          break;
        case 'deals':
          newItem = await _crudService.createDeal(
            title: formData['title'],
            description: formData['description'],
            price: formData['price'],
            discountPercentage: formData['discount_percentage'],
            isFeatured: false,
            imageUrl: formData['image_url'],
            imageUrls: formData['image_urls'],
          );
          break;
        case 'restaurants':
          newItem = await _crudService.createRestaurant(
            name: formData['name'],
            description: formData['description'],
            address: formData['address'],
            contactNumber: formData['contact_number'],
            phone: formData['phone'],
            imageUrl: _selectedImageUrl,
            rating: formData['rating'],
          );
          break;
        case 'menu_categories':
          newItem = await _crudService.createMenuCategory(
            name: formData['name'],
            description: formData['description'],
            imageUrl: _selectedImageUrl,
            sortOrder: formData['sort_order'],
          );
          break;
      }

      if (newItem != null) {
        debugPrint('✅ Successfully created ${widget.itemType}: ${newItem['id']}');
        
        if (mounted) {
          // Call the onCreate callback for immediate UI update
          widget.onCreate?.call(widget.itemType, newItem);
          
          // Close dialog
          Navigator.of(context).pop();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${_getItemDisplayName()} created successfully!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        debugPrint('❌ Failed to create ${widget.itemType}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Failed to create ${widget.itemType.replaceAll('_', ' ')}. Please try again.'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _handleCreate(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Exception creating ${widget.itemType}: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      
      if (mounted) {
        // Analyze error and provide user-friendly message
        String errorMessage = 'An unexpected error occurred';
        Color backgroundColor = Colors.red;
        
        final errorString = e.toString().toLowerCase();
        
        if (errorString.contains('restaurant')) {
          errorMessage = 'Restaurant not found. Please select a valid restaurant from the list.';
          backgroundColor = Colors.orange;
        } else if (errorString.contains('price')) {
          errorMessage = 'Invalid price. Please enter a valid price amount.';
          backgroundColor = Colors.orange;
        } else if (errorString.contains('network') || errorString.contains('connection')) {
          errorMessage = 'Network connection failed. Please check your internet connection and try again.';
          backgroundColor = Colors.blue;
        } else if (errorString.contains('timeout')) {
          errorMessage = 'Request timed out. Please check your connection and try again.';
          backgroundColor = Colors.blue;
        } else if (errorString.contains('duplicate') || errorString.contains('already exists')) {
          errorMessage = 'This item already exists. Please use a different name.';
          backgroundColor = Colors.orange;
        } else if (errorString.contains('foreign key') || errorString.contains('constraint')) {
          errorMessage = 'Invalid data. Please check all fields and try again.';
          backgroundColor = Colors.orange;
        } else if (errorString.contains('permission') || errorString.contains('unauthorized')) {
          errorMessage = 'You don\'t have permission to create this item. Please contact support.';
          backgroundColor = Colors.red;
        } else if (errorString.contains('validation') || errorString.contains('invalid')) {
          errorMessage = 'Please check all fields - some information may be invalid.';
          backgroundColor = Colors.orange;
        } else if (widget.itemType == 'food_items') {
          errorMessage = 'Failed to create food item. Please check restaurant name and try again.';
          backgroundColor = Colors.red;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Creation Failed',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(errorMessage),
                if (kDebugMode) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Debug: ${e.toString()}',
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ],
            ),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handleCreate(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getItemDisplayName() {
    return _dialogTitle.replaceAll('Add New ', '').replaceAll('Create New ', '').replaceAll('Create ', '');
  }
}