import 'package:domacod/objectbox.g.dart';
import 'package:domacod/providers/database_provider.dart';
import 'package:domacod/utils/path_utils.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'image_data_models.dart';
import 'widgets/thumbnail_view.dart';

class GridImageView extends StatefulWidget {
  const GridImageView({
    Key? key,
    required this.assets,
    required this.category,
  }) : super(key: key);
  final List<AssetEntity> assets;
  final String category;

  @override
  State<GridImageView> createState() => _GridImageViewState();
}

class _GridImageViewState extends State<GridImageView> {
  List<AssetEntity> toShow = [];
  void fetchImageToShow() {
    Box<ImageData> assetsBox = context.watch<DatabaseProvider>().getDB;
    if (widget.category == "Recent") {
      toShow = widget.assets;
    } else {
      Query<ImageData> query = assetsBox
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
  Widget build(BuildContext context) {
    fetchImageToShow();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 140),
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
