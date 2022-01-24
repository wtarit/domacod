import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:domacod/objectbox.g.dart';
import 'image_data_models.dart';
import 'utils/path_utils.dart';
import 'widgets/thumbnail_view.dart';
import 'providers/database_provider.dart';
import 'package:provider/provider.dart';

class SearchResultView extends StatefulWidget {
  const SearchResultView({
    Key? key,
    required this.assets,
    required this.query,
  }) : super(key: key);
  final String query;
  final List<AssetEntity> assets;

  @override
  _SearchResultViewState createState() => _SearchResultViewState();
}

class _SearchResultViewState extends State<SearchResultView> {
  List<AssetEntity> toShow = [];
  void fetchImageToShow() {
    Box<ImageData> assetsBox = context.watch<DatabaseProvider>().getDB;
    Query<ImageData> query = assetsBox
        .query(ImageData_.text.contains(widget.query, caseSensitive: false))
        .build();
    List<String> filename = query.property(ImageData_.imagePath).find();
    toShow = widget.assets
        .where(
            (e) => filename.contains(getAbsolutePath(e.relativePath, e.title)))
        .toList();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    fetchImageToShow();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.query),
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
