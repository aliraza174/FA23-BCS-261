import 'package:flutter/material.dart';
import '../utils/database_service.dart';
import '../features/admin/data/models/menu_image_model.dart';
import 'menu_gallery_view.dart';

class DynamicMenuPage extends StatefulWidget {
  const DynamicMenuPage({Key? key}) : super(key: key);

  @override
  State<DynamicMenuPage> createState() => _DynamicMenuPageState();
}

class _DynamicMenuPageState extends State<DynamicMenuPage> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  List<MenuImage> _menuImages = [];

  @override
  void initState() {
    super.initState();
    _loadMenuImages();
  }

  Future<void> _loadMenuImages() async {
    try {
      final images = await _databaseService.getMenuImages();
      setState(() {
        _menuImages = images;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading menu images: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _menuImages.isEmpty
              ? const Center(child: Text('No menu images found'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _menuImages.length,
                  itemBuilder: (context, index) {
                    final menuImage = _menuImages[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () {
                          // Group images by title to show all images for a menu item
                          final relatedImages = _menuImages
                              .where((img) => img.title == menuImage.title)
                              .map((img) => img.imageUrl)
                              .toList();
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MenuGalleryView(
                                title: menuImage.title,
                                images: relatedImages,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      menuImage.imageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.orange,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.restaurant_menu,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                    // Multiple images indicator
                                    Builder(
                                      builder: (context) {
                                        final relatedImagesCount = _menuImages
                                            .where((img) => img.title == menuImage.title)
                                            .length;
                                        
                                        if (relatedImagesCount > 1) {
                                          return Positioned(
                                            right: 8,
                                            bottom: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                                                    '$relatedImagesCount',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    menuImage.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to view menu images',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}