import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> imageUrls; // List of image URLs or paths

  ImageCarousel({required this.imageUrls});

  @override
  _ImageCarouselState createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentIndex = 0; // Current image index

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // CarouselSlider
          CarouselSlider.builder(
            itemCount: widget.imageUrls.length,
            itemBuilder: (BuildContext context, int index, int realIndex) {
              return Image.network(
                widget.imageUrls[index], // Or use Image.asset() for local images
                fit: BoxFit.cover,
              );
            },
            options: CarouselOptions(
              autoPlay: true, // Auto scroll
              enlargeCenterPage: true,
              aspectRatio: 16 / 9,
              viewportFraction: 0.9,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index; // Update the index when the page changes
                });
              },
            ),
          ),
          
          // SmoothPageIndicator (dot indicators)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: AnimatedSmoothIndicator(
              activeIndex: _currentIndex,
              count: widget.imageUrls.length,
              effect: ExpandingDotsEffect(
                dotHeight: 10.0,
                dotWidth: 10.0,
                expansionFactor: 4,
                dotColor: Colors.grey,
                activeDotColor: Colors.blue, // Active dot color
              ),
            ),
          ),
        ],
      );
  }
}
