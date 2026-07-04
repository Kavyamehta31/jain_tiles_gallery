import 'dart:io';

import 'package:flutter/material.dart';

class ImagePickerCard extends StatelessWidget {
  final List<File> images;
  final VoidCallback onPickImages;
  final void Function(int index)? onRemoveImage;

  const ImagePickerCard({
    super.key,
    required this.images,
    required this.onPickImages,
    this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: onPickImages,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text("Add Images"),
        ),
        const SizedBox(height: 12),
        if (images.isEmpty)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text("No images selected")),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        images[index],
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (onRemoveImage != null)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: InkWell(
                          onTap: () => onRemoveImage!(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
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
              },
            ),
          ),
      ],
    );
  }
}
