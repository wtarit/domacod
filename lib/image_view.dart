import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'dart:io';
import 'utils/path_utils.dart';

class ImageView extends StatefulWidget {
  const ImageView({Key? key, required this.asset}) : super(key: key);
  final AssetEntity asset;
  @override
  _ImageViewState createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image"),
      ),
      body: FutureBuilder<File?>(
        future: widget.asset.file,
        builder: (_, snapshot) {
          final file = snapshot.data;
          if (file == null) {
            return Container();
          }
          return PhotoView(imageProvider: FileImage(file));
        },
      ),
    );
  }
}

class GalleryPhotoViewWrapper extends StatefulWidget {
  const GalleryPhotoViewWrapper({Key? key, required this.asset})
      : super(key: key);
  final AssetEntity asset;
  @override
  _GalleryPhotoViewWrapperState createState() =>
      _GalleryPhotoViewWrapperState();
}

class _GalleryPhotoViewWrapperState extends State<GalleryPhotoViewWrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // TODO: make it changable
          PhotoViewGallery.builder(itemCount: 1, builder: _buildItem),
          Positioned(
            bottom: 0,
            // TODO: implement share button
            child: Row(
              children: [
                ElevatedButton(
                    onPressed: () {
                      print("pressed");
                    },
                    child: Text("share")),
                Text(
                  "data",
                  style: TextStyle(backgroundColor: Colors.yellow),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    return PhotoViewGalleryPageOptions.customChild(
      child: FutureBuilder<File?>(
        future: widget.asset.file,
        builder: (_, snapshot) {
          final file = snapshot.data;
          if (file == null) {
            return Container();
          }
          return PhotoView(
            imageProvider: FileImage(file),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4,
          );
        },
      ),
    );
  }
}
