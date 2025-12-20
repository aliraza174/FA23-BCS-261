import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class DealFullscreenViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String title;

  const DealFullscreenViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    required this.title,
  });

  @override
  State<DealFullscreenViewer> createState() => _DealFullscreenViewerState();
}

class _DealFullscreenViewerState extends State<DealFullscreenViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullscreen
          ? null
          : AppBar(
              backgroundColor: Colors.black,
              title: Text(
                widget.title,
                style: const TextStyle(color: Colors.white),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: Icon(
                    _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Colors.white,
                  ),
                  onPressed: _toggleFullscreen,
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    // Share functionality could be added here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sharing is not implemented yet'),
                      ),
                    );
                  },
                ),
              ],
            ),
      body: GestureDetector(
        onTap: _toggleFullscreen,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Main PhotoView Gallery for deal images
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              pageController: _pageController,
              builder: (BuildContext context, int index) {
                final imageUrl = widget.images[index];
                final bool isNetworkImage = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
                
                return PhotoViewGalleryPageOptions(
                  imageProvider: isNetworkImage 
                      ? NetworkImage(imageUrl) as ImageProvider
                      : AssetImage(imageUrl) as ImageProvider,
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              itemCount: widget.images.length,
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),

            // Page indicator at bottom
            if (!_isFullscreen)
              Positioned(
                bottom: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

            // Thumbnails at bottom
            if (!_isFullscreen && widget.images.length > 1)
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.images.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _currentIndex == index
                                  ? Colors.orange
                                  : Colors.transparent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: () {
                              final imageUrl = widget.images[index];
                              final bool isNetworkImage = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
                              
                              return isNetworkImage
                                  ? Image.network(
                                      imageUrl,
                                      height: 60,
                                      width: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 60,
                                          width: 60,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image_not_supported, size: 30),
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      imageUrl,
                                      height: 60,
                                      width: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 60,
                                          width: 60,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image_not_supported, size: 30),
                                        );
                                      },
                                    );
                            }(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Helper function to open deal images in fullscreen
void showDealFullscreen(
    BuildContext context, List<String> images, int initialIndex, String title) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DealFullscreenViewer(
        images: images,
        initialIndex: initialIndex,
        title: title,
      ),
    ),
  );
}
