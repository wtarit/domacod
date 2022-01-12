import 'dart:typed_data';

import 'image_view.dart';
import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:photo_manager/photo_manager.dart';
import 'image_data_models.dart';

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

class GridImageView extends StatefulWidget {
  const GridImageView({
    Key? key,
    required this.assets,
    required this.assetBox,
    required this.category,
  }) : super(key: key);
  final List<AssetEntity> assets;
  final String category;
  final Box<ImageData> assetBox;

  @override
  State<GridImageView> createState() => _GridImageViewState();
}

class _GridImageViewState extends State<GridImageView> {
  List<AssetEntity> toShow = [];
  void fetchImageToShow() {
    // TODO: select image base on category.
    if (widget.category == "Recent") {
      toShow = widget.assets;
    }
  }

  @override
  void initState() {
    fetchImageToShow();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recent"),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          // A grid view with 3 items per row
          crossAxisCount: 3,
        ),
        itemCount: toShow.length,
        itemBuilder: (_, index) {
          return AssetThumbnail(
            assets: toShow,
            index: index,
          );
        },
      ),
    );
  }
}
