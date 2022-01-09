import 'package:domacod/grid_image_view.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

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

  Widget categoryGrid() {
    List<String> categories = [
      "Recent",
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
      gridElement.add(InkWell(
        // onTap: () {
        //   Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //           builder: (context) => GridImageView(
        //               assets: assets, assetBox: assetBox, category: category)));
        // },
        child: GridTile(
          child: Image.asset("assets/question_mark.png"),
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
    gridElement.add(ElevatedButton(
        onPressed: () {
          print("object");
        },
        child: Text("test")));
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
