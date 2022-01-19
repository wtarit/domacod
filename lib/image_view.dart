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
  bool showButton = true;

  get primary => null;

  get child => null;

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

  Widget? _showBottomSheet() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25), topRight: Radius.circular(25)),
              color: Colors.black,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Info",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      const WidgetSpan(
                        child: Icon(Icons.photo_outlined,
                            color: Colors.white60, size: 30),
                      ),
                      TextSpan(
                        text:
                            "   File Name: ${getAbsolutePath(null, widget.assets[currentIndex].title)}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 3),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      const WidgetSpan(
                        child: Icon(Icons.folder_open,
                            color: Colors.white60, size: 30),
                      ),
                      TextSpan(
                        text:
                            "   File Path: ${getAbsolutePath(widget.assets[currentIndex].relativePath, null)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      onPrimary: Colors.white,
      primary: Colors.black.withOpacity(0.05),
      alignment: Alignment.center,
      fixedSize: Size(70, 70));

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          PhotoViewGallery.builder(
            itemCount: widget.assets.length,
            builder: _buildItem,
            pageController: widget.pageController,
            onPageChanged: onPageChanged,
          ),
          showButton
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton(
                      style: buttonStyle,
                      onPressed: shareImage,
                      child: const Icon(Icons.share),
                    ),
                    ElevatedButton(
                      style: buttonStyle,
                      onPressed: deleteImage,
                      child: const Icon(Icons.delete),
                    ),
                    ElevatedButton(
                      style: buttonStyle,
                      onPressed: _showBottomSheet,
                      child: const Icon(Icons.info_outline),
                    )
                  ],
                )
              : Container(),
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
          return InkWell(
            onTap: () {
              setState(() {
                showButton = !showButton;
              });
            },
            child: PhotoView(
              imageProvider: FileImage(file),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 4,
            ),
          );
        },
      ),
    );
  }
}
