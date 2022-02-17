import 'package:domacod/providers/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'dart:io';
import 'utils/path_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
  }

  void shareImage() async {
    final Size size = MediaQuery.of(context).size;
    File? imgFile = await widget.assets[currentIndex].file;
    if (imgFile != null) {
      Share.shareFiles(
        [
          imgFile.path,
        ],
        // sharePositionOrigin: Rect.fromLTWH(0, 0, size.width, size.height / 4),
      );
    }
  }

  void _showDeleteConfirmation() async {
    String deleteID = widget.assets[currentIndex].id;
    final List<String> result = await PhotoManager.editor.deleteWithIds([
      deleteID,
    ]);
    widget.assets.removeWhere((element) => element.id == deleteID);
    if (result.isNotEmpty) {
      context.read<DatabaseProvider>().deleteDBbyID(deleteID);
      if (widget.assets.isEmpty) {
        Navigator.pop(context);
      }
      setState(() {
        if (currentIndex == widget.assets.length) {
          currentIndex--;
        }
      });
    }
  }

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  Widget? _showBottomSheet() {
    AssetEntity currentAsset = widget.assets[currentIndex];
    List<String> categories =
        context.read<DatabaseProvider>().queryCategory(currentAsset.id);
    String categoryDisplay = "  ";
    if (categories.isNotEmpty) {
      for (int i = 0; i < categories.length; i++) {
        categoryDisplay += categories[i];
        if (i < categories.length - 1) {
          categoryDisplay += ", ";
        }
      }
    } else {
      categoryDisplay += "Coming Soon...";
    }
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
            child: ListView(
              //crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      const WidgetSpan(
                        child: Icon(Icons.photo_outlined,
                            color: Colors.white60, size: 20),
                      ),
                      TextSpan(
                        text:
                            "   ${getAbsolutePath(null, widget.assets[currentIndex].title)}\n",
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 3),
                      ),
                      const WidgetSpan(
                        child: Icon(Icons.folder_open_rounded,
                            color: Colors.white60, size: 20),
                      ),
                      TextSpan(
                        text:
                            "   ${getAbsolutePath(widget.assets[currentIndex].relativePath, null)}\n",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 3,
                        ),
                      ),
                      const WidgetSpan(
                        child: Icon(Icons.photo_size_select_large_rounded,
                            color: Colors.white60, size: 20),
                      ),
                      TextSpan(
                        text:
                            "   ${widget.assets[currentIndex].width} X ${widget.assets[currentIndex].height}\n",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 3,
                        ),
                      ),
                      const WidgetSpan(
                        child: Icon(Icons.access_time_rounded,
                            color: Colors.white60, size: 20),
                      ),
                      TextSpan(
                        text:
                            "   ${widget.assets[currentIndex].createDateTime}\n",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 3,
                        ),
                      ),
                      // If latitude and longitude is 0, it means that no positioning information was obtained. And don't show this part.
                      widget.assets[currentIndex].latitude != 0.0
                          ? const WidgetSpan(
                              child: Icon(Icons.location_on_outlined,
                                  color: Colors.white60, size: 20),
                            )
                          : const TextSpan(),
                      widget.assets[currentIndex].latitude != 0.0
                          ? TextSpan(
                              text:
                                  "   ${widget.assets[currentIndex].latitude} X ${widget.assets[currentIndex].longitude}\n",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 3,
                              ),
                            )
                          : const TextSpan(),
                      const WidgetSpan(
                        child: Icon(Icons.tag_rounded,
                            color: Colors.white60, size: 20),
                      ),
                      TextSpan(
                        text: categoryDisplay,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
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

  final ButtonStyle buttonStyle = TextButton.styleFrom(
    primary: Colors.white,
    alignment: Alignment.center,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      appBar: showButton
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.05),
            )
          : null,
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
              ? Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Expanded(
                        child: TextButton(
                          style: buttonStyle,
                          onPressed: shareImage,
                          child: const Icon(Icons.share),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          style: buttonStyle,
                          onPressed: _showDeleteConfirmation,
                          child: const Icon(Icons.delete),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          style: buttonStyle,
                          onPressed: _showBottomSheet,
                          child: const Icon(Icons.info_outline),
                        ),
                      )
                    ],
                  ),
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
          return PhotoView(
            imageProvider: FileImage(file),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4,
            onTapDown: (context, details, controllerValue) {
              setState(() {
                showButton = !showButton;
                if (showButton) {
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                      overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
                } else {
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                      overlays: []);
                }
              });
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top],
    );
    super.dispose();
  }
}
