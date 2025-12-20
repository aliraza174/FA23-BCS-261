import 'package:flutter/material.dart';
import '../services/admin_crud_service.dart';

/// Enhanced restaurant selector with dropdown and auto-completion
/// Provides better UX for selecting restaurants with fallback to text input
class RestaurantSelector extends StatefulWidget {
  final TextEditingController controller;
  final String? initialValue;
  final Function(String?)? onChanged;
  final String? Function(String?)? validator;

  const RestaurantSelector({
    super.key,
    required this.controller,
    this.initialValue,
    this.onChanged,
    this.validator,
  });

  @override
  State<RestaurantSelector> createState() => _RestaurantSelectorState();
}

class _RestaurantSelectorState extends State<RestaurantSelector> {
  final AdminCRUDService _crudService = AdminCRUDService();
  List<Map<String, dynamic>> _restaurants = [];
  List<Map<String, dynamic>> _filteredRestaurants = [];
  bool _isLoading = true;
  bool _showDropdown = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    if (widget.initialValue != null) {
      widget.controller.text = widget.initialValue!;
    }
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final query = widget.controller.text;
    setState(() {
      _searchQuery = query;
      _filterRestaurants(query);
      _showDropdown = query.isNotEmpty && _filteredRestaurants.isNotEmpty;
    });
    widget.onChanged?.call(query);
  }

  Future<void> _loadRestaurants() async {
    try {
      final restaurants = await _crudService.getRestaurants();
      setState(() {
        _restaurants = restaurants;
        _filteredRestaurants = restaurants;
        _isLoading = false;
      });
      debugPrint('🏠 Loaded ${restaurants.length} restaurants for selector');
    } catch (e) {
      debugPrint('❌ Failed to load restaurants: $e');
      setState(() {
        _isLoading = false;
        // Provide fallback restaurant options if database fails
        _restaurants = _getFallbackRestaurants();
        _filteredRestaurants = _restaurants;
      });
    }
  }

  List<Map<String, dynamic>> _getFallbackRestaurants() {
    return [
      {'id': 'fallback-1', 'name': 'Meet N Eat'},
      {'id': 'fallback-2', 'name': 'Crust Bros'},
      {'id': 'fallback-3', 'name': 'Khana Khazana'},
      {'id': 'fallback-4', 'name': 'Miran Jee Food Club (MFC)'},
      {'id': 'fallback-5', 'name': 'Pizza Slice'},
      {'id': 'fallback-6', 'name': 'Nawab Hotel'},
      {'id': 'fallback-7', 'name': 'Beba\'s Kitchen'},
      {'id': 'fallback-8', 'name': 'EatWay'},
    ];
  }

  void _filterRestaurants(String query) {
    if (query.isEmpty) {
      _filteredRestaurants = _restaurants;
    } else {
      _filteredRestaurants = _restaurants.where((restaurant) {
        final name = restaurant['name']?.toString().toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();
    }
  }

  void _selectRestaurant(Map<String, dynamic> restaurant) {
    setState(() {
      widget.controller.text = restaurant['name'];
      _showDropdown = false;
    });
    widget.onChanged?.call(restaurant['name']);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: 'Restaurant Name',
            prefixIcon: const Icon(Icons.restaurant, color: Colors.orange),
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: Icon(_showDropdown ? Icons.expand_less : Icons.expand_more),
                    onPressed: () {
                      setState(() {
                        _showDropdown = !_showDropdown;
                        if (_showDropdown) {
                          _filterRestaurants(widget.controller.text);
                        }
                      });
                    },
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            hintText: 'Select or type restaurant name',
          ),
          validator: widget.validator,
          onTap: () {
            setState(() {
              _showDropdown = true;
              _filterRestaurants(widget.controller.text);
            });
          },
        ),
        if (_showDropdown && _filteredRestaurants.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredRestaurants.length,
              itemBuilder: (context, index) {
                final restaurant = _filteredRestaurants[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    restaurant['name'] ?? 'Unknown Restaurant',
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: restaurant['address'] != null
                      ? Text(
                          restaurant['address'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  leading: const Icon(Icons.restaurant, size: 20, color: Colors.orange),
                  onTap: () => _selectRestaurant(restaurant),
                );
              },
            ),
          ),
        ],
        if (_restaurants.isEmpty && !_isLoading)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No restaurants found. You can still type a restaurant name.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Popular restaurants: ${_restaurants.take(3).map((r) => r['name']).join(', ')}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}