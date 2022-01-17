import '../image_view.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';

// Use to create individual thumbnail
class AssetThumbnail extends StatelessWidget {
  const AssetThumbnail({
    Key? key,
    required this.assets,
    required this.index,
  }) : super(key: key);

  final List<AssetEntity> assets;
  final int index;

  @override
  Widget build(BuildContext context) {
    // We're using a FutureBuilder since thumbData is a future
    return FutureBuilder<Uint8List?>(
      future: assets[index].thumbData,
      builder: (_, snapshot) {
        final bytes = snapshot.data;
        // If we have no data, display a spinner
        if (bytes == null) return const CircularProgressIndicator();
        // If there's data, display it as an image
        return InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => GalleryPhotoViewWrapper(
                            assets: assets,
                            index: index,
                          )));
            },
            child: Image.memory(bytes, fit: BoxFit.cover));
      },
    );
  }
}
