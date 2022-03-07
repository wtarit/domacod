import 'package:domacod/objectbox.g.dart';
import 'package:domacod/providers/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'image_data_models.dart';
import 'widgets/thumbnail_view.dart';
import 'package:sticky_headers/sticky_headers.dart';

class DocumentImageView extends StatefulWidget {
  const DocumentImageView({
    Key? key,
    required this.category,
  }) : super(key: key);
  final String category;

  @override
  State<DocumentImageView> createState() => _DocumentImageViewState();
}

class _DocumentImageViewState extends State<DocumentImageView> {
  List<AssetEntity> toShow = [];
  String dropdownValue = "All subject";

  void fetchImageToShow() {
    Box<ImageData> assetsBox = context.watch<DatabaseProvider>().getDB;
    List<AssetEntity> assets = context.watch<DatabaseProvider>().assets;
    if (widget.category == "Recent") {
      toShow = assets;
    } else {
      Query<ImageData> query = assetsBox
          .query(ImageData_.category.contains(widget.category))
          .build();
      List<String> toShowIDs = query.property(ImageData_.imageID).find();
      toShow = assets.where((e) => toShowIDs.contains(e.id)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    fetchImageToShow();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
      ),
      body: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              const Text("Filter Subject\t\t"),
              DropdownButton(
                value: dropdownValue,
                items: <String>[
                  "All subject",
                  "Math",
                  "Chemistry",
                  "Physics",
                  "Biology",
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    dropdownValue = newValue!;
                  });
                },
              ),
            ],
          ),
          Scrollbar(
            child: GridView.builder(
              shrinkWrap: true,
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
          ),
        ],
      ),
    );
  }
}
