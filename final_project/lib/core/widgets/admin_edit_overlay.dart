import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/admin_service.dart';
import '../providers/admin_mode_provider.dart';
import '../services/hybrid_image_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class AdminEditOverlay extends StatefulWidget {
  final Widget child;
  final String itemId;
  final String itemType; // 'food_item', 'deal', 'restaurant', etc.
  final Map<String, dynamic>? itemData;
  final Function(String itemType, String itemId, Map<String, dynamic> data)? onEdit;
  final Function(String itemType, String itemId)? onDelete;

  const AdminEditOverlay({
    Key? key,
    required this.child,
    required this.itemId,
    required this.itemType,
    this.itemData,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  State<AdminEditOverlay> createState() => _AdminEditOverlayState();
}

class _AdminEditOverlayState extends State<AdminEditOverlay> with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  // Gallery state for menu categories
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  final bool _loadingGallery = false;
  final List<Map<String, dynamic>> _gallery = [];
  final AdminModeProvider _adminProvider = AdminModeProvider();
  bool _showOverlay = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _adminProvider,
      builder: (context, child) {
        // Show overlays if admin is authenticated
        // Edit mode should be automatically enabled when admin logs in
        if (!_adminProvider.isAdmin) {
          return widget.child;
        }
        
        // If admin is authenticated but edit mode is somehow disabled, enable it
        if (_adminProvider.isAdmin && !_adminProvider.isEditMode) {
          debugPrint('AdminEditOverlay: Admin logged in but edit mode disabled, auto-enabling...');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _adminProvider.enableEditMode();
          });
        }

        return GestureDetector(
          onLongPress: () {
            debugPrint('AdminEditOverlay: Long press on ${widget.itemType} ${widget.itemId}');
            _showEditDialog();
          },
          onTap: () {
            if (_showOverlay) {
              setState(() => _showOverlay = false);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.orange.withOpacity(0.8),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                widget.child,
                // Animated edit indicator in corner
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(_pulseAnimation.value),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                // Prominent "EDIT" button - always visible for admin
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: _showEditDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'EDIT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Secondary long press hint (smaller)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Long press also works',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => _EditDialog(
        itemType: widget.itemType,
        itemId: widget.itemId,
        itemData: widget.itemData,
        onSave: (data) async {
          if (widget.onEdit != null) {
            debugPrint('AdminEditOverlay: Calling onEdit for ${widget.itemType} ${widget.itemId}');
            await widget.onEdit!(widget.itemType, widget.itemId, data);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Edit functionality for ${widget.itemType} not implemented yet'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          Navigator.of(context).pop();
        },
        onDelete: widget.onDelete != null ? () async {
          debugPrint('AdminEditOverlay: Calling onDelete for ${widget.itemType} ${widget.itemId}');
          if (widget.onDelete != null) {
            await widget.onDelete!(widget.itemType, widget.itemId);
          }
          Navigator.of(context).pop();
        } : null,
      ),
    );
  }
}

class _EditDialog extends StatefulWidget {
  final String itemType;
  final String itemId;
  final Map<String, dynamic>? itemData;
  final Function(Map<String, dynamic>) onSave;
  final Future<void> Function()? onDelete;

  const _EditDialog({
    Key? key,
    required this.itemType,
    required this.itemId,
    this.itemData,
    required this.onSave,
    this.onDelete,
  }) : super(key: key);

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  final HybridImageService _imageService = HybridImageService();
  String? _currentImageUrl;
  String? _newImageUrl;

  // Gallery support
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  bool _loadingGallery = false;
  List<Map<String, dynamic>> _gallery = [];
  @override
  void initState() {
    super.initState();
    _controllers = {};
    _initializeControllers();
    _loadMenuGallery();
  }

  void _initializeControllers() {
    final data = widget.itemData ?? {};
    
    // Initialize current image URL
    _currentImageUrl = data['image_url']?.toString() ?? 
                      data['imageUrl']?.toString() ?? 
                      data['image']?.toString();
    
    switch (widget.itemType) {
      case 'food_item':
        _controllers['name'] = TextEditingController(text: data['name']?.toString() ?? '');
        _controllers['price'] = TextEditingController(text: data['price']?.toString() ?? '');
        _controllers['description'] = TextEditingController(text: data['description']?.toString() ?? '');
        _controllers['restaurant'] = TextEditingController(text: data['restaurant']?.toString() ?? '');
        break;
      case 'deal':
        _controllers['title'] = TextEditingController(text: data['title']?.toString() ?? '');
        _controllers['description'] = TextEditingController(text: data['description']?.toString() ?? '');
        _controllers['price'] = TextEditingController(text: data['price']?.toString() ?? '');
        _controllers['discount_percentage'] = TextEditingController(text: data['discount_percentage']?.toString() ?? '');
        break;
      case 'restaurant':
        _controllers['name'] = TextEditingController(text: data['name']?.toString() ?? '');
        _controllers['description'] = TextEditingController(text: data['description']?.toString() ?? '');
        _controllers['address'] = TextEditingController(text: data['address']?.toString() ?? '');
        _controllers['contact_number'] = TextEditingController(text: data['contact_number']?.toString() ?? data['phone']?.toString() ?? '');
        break;
      case 'menu_category':
        _controllers['name'] = TextEditingController(text: data['name']?.toString() ?? '');
        break;
      default:
        _controllers['name'] = TextEditingController(text: data['name']?.toString() ?? '');
        _controllers['description'] = TextEditingController(text: data['description']?.toString() ?? '');
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Edit ${_getItemTypeName()}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ID: ${widget.itemId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Image section
                _buildImageSection(),
                const SizedBox(height: 20),
                if (widget.itemType == 'menu_categories' || widget.itemType == 'menu_category')
                  ...[_buildMenuGallerySection()],
                
                // Form fields
                ..._buildFormFields(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          ElevatedButton.icon(
            onPressed: () => _showDeleteConfirmation(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
          icon: const Icon(Icons.save, size: 18),
          label: const Text('Save Changes'),
        ),
      ],
    );
  }

  List<Widget> _buildFormFields() {
    final fields = <Widget>[];
    
    for (final entry in _controllers.entries) {
      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: entry.value,
            decoration: InputDecoration(
              labelText: _getFieldLabel(entry.key),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: _getFieldIcon(entry.key),
            ),
            keyboardType: entry.key == 'price' ? TextInputType.number : TextInputType.text,
            maxLines: entry.key == 'description' ? 3 : 1,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter ${_getFieldLabel(entry.key).toLowerCase()}';
              }
              if (entry.key == 'price') {
                final price = double.tryParse(value!);
                if (price == null || price <= 0) {
                  return 'Please enter a valid price';
                }
              }
              return null;
            },
          ),
        ),
      );
    }
    
    return fields;
  }

  String _getFieldLabel(String fieldName) {
    switch (fieldName) {
      case 'name':
        return 'Name';
      case 'title':
        return 'Title';
      case 'description':
        return 'Description';
      case 'price':
        return 'Price (Rs)';
      case 'address':
        return 'Address';
      case 'phone':
      case 'contact_number':
        return 'Contact Number';
      case 'discount_percentage':
        return 'Discount %';
      case 'restaurant':
        return 'Restaurant';
      default:
        return fieldName.substring(0, 1).toUpperCase() + fieldName.substring(1);
    }
  }

  Icon? _getFieldIcon(String fieldName) {
    switch (fieldName) {
      case 'name':
      case 'title':
        return const Icon(Icons.label, color: Colors.orange);
      case 'description':
        return const Icon(Icons.description, color: Colors.orange);
      case 'price':
        return const Icon(Icons.attach_money, color: Colors.orange);
      case 'address':
        return const Icon(Icons.location_on, color: Colors.orange);
      case 'phone':
      case 'contact_number':
        return const Icon(Icons.phone, color: Colors.orange);
      case 'discount_percentage':
        return const Icon(Icons.percent, color: Colors.orange);
      case 'restaurant':
        return const Icon(Icons.restaurant, color: Colors.orange);
      default:
        return const Icon(Icons.info, color: Colors.orange);
    }
  }

  String _getItemTypeName() {
    switch (widget.itemType) {
      case 'food_item':
        return 'Food Item';
      case 'deal':
        return 'Deal';
      case 'restaurant':
        return 'Restaurant';
      case 'menu_category':
        return 'Category';
      default:
        return 'Item';
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      final data = <String, dynamic>{};
      for (final entry in _controllers.entries) {
        if (entry.key == 'price' || entry.key == 'discount_percentage') {
          final value = double.tryParse(entry.value.text);
          if (value != null) {
            data[entry.key] = value;
          }
        } else {
          data[entry.key] = entry.value.text;
        }
      }
      
      // Add image URL if updated (only send image_url, not imageUrl)
      if (_newImageUrl != null) {
        data['image_url'] = _newImageUrl;
      } else if (_currentImageUrl != null) {
        data['image_url'] = _currentImageUrl;
      }
      
      debugPrint('_EditDialog: Calling onSave with data: ${data.keys.join(', ')}');
      await widget.onSave(data);
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_getItemTypeName()}'),
        content: Text('Are you sure you want to delete this ${_getItemTypeName().toLowerCase()}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close confirmation
              debugPrint('_EditDialog: Calling onDelete');
              await widget.onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final String currentImage = _newImageUrl ?? _currentImageUrl ?? '';
    
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.image, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Item Image',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (currentImage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        _imageService.getStorageTypeDescription(currentImage),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectNewImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: Text(currentImage.isEmpty ? 'Add Photo' : 'Change Photo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Image preview
          if (currentImage.isNotEmpty)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: currentImage.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: currentImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(color: Colors.orange),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Local image', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No image selected',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "Add Photo" to select an image',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          
          if (_newImageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'New image uploaded and ready to save',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }



  // Menu Gallery management (for menu categories)
  Widget _buildMenuGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.photo_library, color: Colors.orange),
            const SizedBox(width: 8),
            const Text(
              'Menu Gallery',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addGalleryImages,
              icon: const Icon(Icons.add, color: Colors.orange),
              label: const Text('Add Images'),
            )
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _loadingGallery
              ? const Center(child: CircularProgressIndicator(color: Colors.orange))
              : _gallery.isEmpty
                  ? Text('No gallery images yet', style: TextStyle(color: Colors.grey[600]))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _gallery.map((img) {
                        final url = (img['image_url'] ?? '').toString();
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 90,
                                height: 90,
                                child: url.startsWith('http')
                                    ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
                                    : Container(color: Colors.grey[300], child: const Icon(Icons.image)),
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: InkWell(
                                onTap: () => _removeGalleryImage(url),
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
        ),
      ],
    );
  }

  Future<void> _loadMenuGallery() async {
    if (!(widget.itemType == 'menu_categories' || widget.itemType == 'menu_category')) return;
    final name = _controllers['name']?.text.trim() ?? '';
    if (name.isEmpty) return;
    setState(() => _loadingGallery = true);
    try {
      final rows = await _supabase.from('menu_images').select().eq('name', name).order('display_order');
      setState(() {
        _gallery = List<Map<String, dynamic>>.from(rows);
        _loadingGallery = false;
      });
    } catch (e) {
      setState(() => _loadingGallery = false);
    }
  }

  Future<void> _addGalleryImages() async {
    try {
      final name = _controllers['name']?.text.trim() ?? '';
      if (name.isEmpty) return;
      final picked = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 1920, maxHeight: 1080);
      if (picked.isEmpty) return;

      final nameSlug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'-+'), '-');
      final folder = 'restaurant-menus/$nameSlug';

      int startIndex = _gallery.length;
      for (int i = 0; i < picked.length; i++) {
        final x = picked[i];
        final bytes = await x.readAsBytes();
        final sanitized = x.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\._-]+'), '-');
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$sanitized';
        final path = '$folder/$fileName';
        await _supabase.storage.from('public').uploadBinary(path, bytes);
        final url = _supabase.storage.from('public').getPublicUrl(path);
        await _supabase.from('menu_images').insert({
          'name': name,
          'image_url': url,
          'display_order': startIndex + i,
        });
      }
      await _loadMenuGallery();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Images added'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add images: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeGalleryImage(String url) async {
    try {
      await _supabase.from('menu_images').delete().eq('image_url', url);
      await _loadMenuGallery();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  Future<void> _selectNewImage() async {
    final String folder = _getFolderForItemType(widget.itemType);
    
    final String? imageUrl = await _imageService.selectAndProcessImage(
      context,
      folder: folder,
      existingImageUrl: _currentImageUrl,
    );
    
    if (imageUrl != null) {
      setState(() {
        _newImageUrl = imageUrl;
      });
    }
  }

  String _getFolderForItemType(String itemType) {
    switch (itemType) {
      case 'food_item':
        return 'food_items';
      case 'deal':
        return 'deals';
      case 'restaurant':
        return 'restaurants';
      case 'menu_category':
        return 'menu_categories';
      default:
        return 'general';
    }
  }
}




