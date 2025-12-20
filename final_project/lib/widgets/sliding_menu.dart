import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../utils/file_operations_stub.dart'
    if (dart.library.io) '../utils/file_operations_mobile.dart'
    if (dart.library.html) '../utils/file_operations_web.dart';

class SlidingMenu extends StatefulWidget {
  final List<String> images;

  const SlidingMenu({super.key, required this.images});

  @override
  _SlidingMenuState createState() => _SlidingMenuState();
}

class _SlidingMenuState extends State<SlidingMenu> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      if (_pageController.hasClients && _pageController.page != null) {
        final currentPage = _pageController.page!.round();
        if (currentPage >= 0 && currentPage < widget.images.length) {
          setState(() {
            _currentPage = currentPage;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sliding Menu'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // Sliding Menu View
          Expanded(
            child: widget.images.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : PageView.builder(
                    controller: _pageController,
                    itemCount: widget.images.length,
                    itemBuilder: (context, index) {
                      if (index >= 0 && index < widget.images.length) {
                        return GestureDetector(
                          onTap: () {
                            _openFullscreenGallery(index);
                          },
                          child: Image.asset(
                            widget.images[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        );
                      } else {
                        return const Center(child: Text("Image not available"));
                      }
                    },
                  ),
          ),
          const SizedBox(height: 10),
          // Page Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                width: 10.0,
                height: 10.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index ? Colors.orange : Colors.grey,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _openFullscreenGallery(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenGallery(
          images: widget.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class FullscreenGallery extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const FullscreenGallery({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        itemCount: images.length,
        pageController: PageController(initialPage: initialIndex),
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: AssetImage(images[index]),
            heroAttributes: PhotoViewHeroAttributes(tag: images[index]),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
          );
        },
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
