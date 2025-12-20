import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class RestaurantMenuGallery extends StatefulWidget {
  final String restaurantName;
  final List<String> menuImages;
  final int initialIndex;

  const RestaurantMenuGallery({
    super.key,
    required this.restaurantName,
    required this.menuImages,
    this.initialIndex = 0,
  });

  @override
  State<RestaurantMenuGallery> createState() => _RestaurantMenuGalleryState();
}

class _RestaurantMenuGalleryState extends State<RestaurantMenuGallery> {
  late PageController _pageController;
  late int _currentIndex;

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

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '${widget.restaurantName} Menu',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            pageController: _pageController,
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: AssetImage(widget.menuImages[index]),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            itemCount: widget.menuImages.length,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
            onPageChanged: _onPageChanged,
          ),
          Container(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              '${_currentIndex + 1} / ${widget.menuImages.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17.0,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
