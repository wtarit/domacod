import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:domacod/objectbox.g.dart';
import 'image_data_models.dart';
import 'utils/path_utils.dart';
import 'widgets/thumbnail_view.dart';

class SearchResultView extends StatefulWidget {
  const SearchResultView({
    Key? key,
    required this.assets,
    required this.assetBox,
    required this.query,
  }) : super(key: key);
  final String query;
  final List<AssetEntity> assets;
  final Box<ImageData> assetBox;

  @override
  _SearchResultViewState createState() => _SearchResultViewState();
}

class _SearchResultViewState extends State<SearchResultView> {
  List<AssetEntity> toShow = [];
  void fetchImageToShow() {
    Query<ImageData> query = widget.assetBox
        .query(ImageData_.text.contains(widget.query, caseSensitive: false))
        .build();
    List<String> filename = query.property(ImageData_.imagePath).find();
    print(filename.length);
    toShow = widget.assets
        .where(
            (e) => filename.contains(getAbsolutePath(e.relativePath, e.title)))
        .toList();
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
        title: Text(widget.query),
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
