import 'package:flutter/material.dart';

class FotoCarousel extends StatelessWidget {
  final List<String> fotos;
  const FotoCarousel({Key? key, required this.fotos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (fotos.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.image, color: Colors.grey)),
      );
    }
    return PageView.builder(
      itemCount: fotos.length,
      itemBuilder: (context, index) {
        return InteractiveViewer(
          child: Image.network(
            fotos[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
            ),
          ),
        );
      },
    );
  }
}
