import 'package:domacod/objectbox.g.dart';
import 'package:domacod/utils/path_utils.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'image_data_models.dart';
import 'widgets/thumbnail_view.dart';

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
    if (widget.category == "Recent") {
      toShow = widget.assets;
    } else {
      Query<ImageData> query = widget.assetBox
          .query(ImageData_.mainCategory.equals(widget.category))
          .build();
      List<String> filename = query.property(ImageData_.imagePath).find();
      toShow = widget.assets
          .where((e) =>
              filename.contains(getAbsolutePath(e.relativePath, e.title)))
          .toList();
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
        title: Text(widget.category),
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
