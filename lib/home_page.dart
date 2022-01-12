import 'dart:io';

import 'package:domacod/grid_image_view.dart';
import 'package:domacod/objectbox.g.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:objectbox/objectbox.dart';
import 'image_data_models.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key, required this.assetBox}) : super(key: key);

  final Box<ImageData> assetBox;
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool busy = true;
  late double screenWidth = MediaQuery.of(context).size.width;
  late double screenHeight = MediaQuery.of(context).size.height;
  List<AssetEntity> assets = [];

  void _fetchAssets() async {
    // Set onlyAll to true, to fetch only the 'Recent' album
    // which contains all the photos/videos in the storage
    final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image, onlyAll: true);
    if (albums.isNotEmpty) {
      final recentAlbum = albums.first;
      // Now that we got the album, fetch all the assets it contains
      final recentAssets = await recentAlbum.getAssetListRange(
        start: 0, // start at index 0
        end: recentAlbum.assetCount, // end at max number of assets
      );
      // Update the state and notify UI
      setState(() => assets = recentAssets);
    }
  }

  @override
  void initState() {
    _fetchAssets();
    super.initState();
  }

  void printDB() {
    List<ImageData> a = widget.assetBox.getAll();
    Query<ImageData> query =
        widget.assetBox.query(ImageData_.category.contains("Document")).build();
    ImageData? doc = query.findFirst();
    if (doc != null) {
      print(doc);
    }
  }

  String queryImage(String queryCategory) {
    if (queryCategory == "Recent") {
      ImageData? data = widget.assetBox.query().build().findFirst();
      if (data != null) {
        return data.imagePath;
      } else {
        return "";
      }
    }
    Query<ImageData> query = widget.assetBox
        .query(ImageData_.category.contains(queryCategory))
        .build();
    ImageData? doc = query.findFirst();
    if (doc != null) {
      return doc.imagePath;
    }
    return "";
  }

  Widget categoryGrid() {
    List<String> categories = [
      "Recent",
      "Document",
      "Cat",
      "Dog",
      "Bird",
      "Animal",
      "Person",
      "Car",
      "Bicycle",
      "Motorcycle",
      "Airplane",
    ];
    List<Widget> gridElement = [];
    for (String category in categories) {
      String imgPath = queryImage(category);
      late Widget img;
      if (imgPath.isNotEmpty) {
        img = Image.file(File(imgPath));
      } else {
        img = Image.asset("assets/question_mark.png");
      }
      gridElement.add(InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GridImageView(
                        assets: assets,
                        assetBox: widget.assetBox,
                        category: category,
                      )));
        },
        child: GridTile(
          child: img,
          footer: GridTileBar(
            backgroundColor: Colors.black,
            title: Text(category),
          ),
        ),
      ));
    }
    if (busy) {
      gridElement.add(Container(
        height: screenHeight,
      ));
    }
    gridElement.add(ElevatedButton(onPressed: printDB, child: Text("test")));
    return GridView.count(
      // shrinkWrap: true,
      crossAxisCount: 2,
      children: gridElement,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Domacod"),
      ),
      body: Stack(children: [
        categoryGrid(),
        Positioned(
          bottom: 0,
          child: busy
              ? Container(
                  margin: const EdgeInsets.all(5.0),
                  width: screenWidth,
                  height: screenHeight * 0.1,
                  color: Colors.white,
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      CircularProgressIndicator(),
                      Spacer(),
                      Text("Indexed 0 of 10"),
                      Spacer(
                        flex: 2,
                      ),
                    ],
                  ),
                )
              : Container(),
        ),
      ]),
    );
  }
}
