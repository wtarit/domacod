import 'package:domacod/grid_image_view.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'dart:io';
import 'utils/path_utils.dart';
import 'package:share_plus/share_plus.dart';

class GalleryPhotoViewWrapper extends StatefulWidget {
  GalleryPhotoViewWrapper({
    Key? key,
    required this.assets,
    required this.index,
  })  : pageController = PageController(initialPage: index),
        super(key: key);
  final List<AssetEntity> assets;
  final int index;
  final PageController pageController;
  @override
  _GalleryPhotoViewWrapperState createState() =>
      _GalleryPhotoViewWrapperState();
}

class _GalleryPhotoViewWrapperState extends State<GalleryPhotoViewWrapper> {
  late int currentIndex = widget.index;

  get primary => null;

  void shareImage() {
    Share.shareFiles([
      getAbsolutePath(widget.assets[currentIndex].relativePath,
          widget.assets[currentIndex].title)
    ]);
  }

  void deleteImage() async {
    final file = File(getAbsolutePath(widget.assets[currentIndex].relativePath,
        widget.assets[currentIndex].title));
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Error in getting access to the file.
    }
  }

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
    onPrimary: Colors.white,
    primary: Colors.black.withOpacity(0.05),
    alignment: Alignment.center,
    minimumSize: Size(130, 70),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: widget.assets.length,
            builder: _buildItem,
            pageController: widget.pageController,
            onPageChanged: onPageChanged,
          ),
          Positioned(
            bottom: 0,
            left: 5,
            right: 5,
            child: Row(
              children: [
                ElevatedButton(
                    style: raisedButtonStyle,
                    onPressed: shareImage,
                    child: Icon(Icons.share)),
                ElevatedButton(
                  style: raisedButtonStyle,
                  onPressed: deleteImage,
                  child: Icon(Icons.delete),
                ),
                ElevatedButton(
                  style: raisedButtonStyle,
                  onPressed: shareImage,
                  child: Icon(Icons.info_outline),
                )
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
        future: widget.assets[index].file,
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
