import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

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
      body: Column(
        children: [
          FutureBuilder<File?>(
            future: widget.asset.file,
            builder: (_, snapshot) {
              final file = snapshot.data;
              if (file == null) return Container();
              return Image.file(file);
            },
          ),
          Text(getAbsolutePath(
            widget.asset.relativePath,
            widget.asset.title,
          )),
        ],
      ),
    );
  }
}
