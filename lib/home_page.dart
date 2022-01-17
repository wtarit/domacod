import 'dart:io';

import 'package:domacod/grid_image_view.dart';
import 'package:domacod/objectbox.g.dart';
import 'package:domacod/screen/disclaimer.dart';
import 'package:domacod/search_result_view.dart';
import 'package:domacod/utils/http_ocr_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'image_data_models.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'utils/path_utils.dart';
import 'tflite/classifier_yolov4.dart';
import 'utils/isolate_utils.dart';
import 'dart:isolate';
import 'tflite/recognition.dart';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as image_lib;

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
  int processed = 0;
  late IsolateUtils isolateUtils;
  Classifier classifier = Classifier();

  Future<void> _showPermissionDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Grant Permission'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                    "Domacod need storage permission in order to access your photo."),
                Text(
                    "To grant Domacod permission click open setting and allow storage access."),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Quit App'),
              onPressed: () {
                // Navigator.of(context).pop();
                SystemChannels.platform
                    .invokeMethod<void>('SystemNavigator.pop');
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                PhotoManager.openSetting();
                var result = await PhotoManager.requestPermissionExtend();
                print("permission result $result");
                if (result.isAuth) {
                  Navigator.of(context).pop();
                } else {
                  SystemChannels.platform
                      .invokeMethod<void>('SystemNavigator.pop');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchAssets() async {
    var result = await PhotoManager.requestPermissionExtend();
    if (!result.isAuth) {
      await _showPermissionDialog();
    }
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

  /// Runs inference in another isolate
  Future<List<String>> inference(String filepath) async {
    Uint8List? data = File(filepath).readAsBytesSync();
    if (p.extension(filepath) == ".heic") {
      data = await FlutterImageCompress.compressWithList(
        data,
        minWidth: 416,
        minHeight: 416,
        format: CompressFormat.jpeg,
      );
    }
    image_lib.Image? img = image_lib.decodeImage(data);
    if (img == null) {
      return [];
    }
    IsolateData isolateData = IsolateData(
      img,
      classifier.interpreter.address,
      classifier.labels,
    );
    ReceivePort responsePort = ReceivePort();
    isolateUtils.sendPort
        .send(isolateData..responsePort = responsePort.sendPort);
    var results = await responsePort.first;
    List<String> outputCategory = [];
    for (Recognition recognition in results["recognitions"]) {
      outputCategory.add(recognition.label);
    }
    return outputCategory.take(5).toList();
  }

  void addDB() async {
    setState(() {
      busy = true;
    });
    List<String> newPaths = [];
    List<String> dbPaths = [];
    List<ImageData> dataBase = widget.assetBox.getAll();
    for (ImageData db in dataBase) {
      dbPaths.add(db.imagePath);
    }
    for (AssetEntity asset in assets) {
      String? relpath = asset.relativePath;
      String? fname = asset.title;
      String path = getAbsolutePath(relpath, fname);
      newPaths.add(path);
    }

    // Loop over database to see which image is deleted.
    for (int i = 0; i < dbPaths.length; i++) {
      if (!newPaths.contains(dbPaths[i])) {
        widget.assetBox.remove(dataBase[i].id);
      }
    }
    setState(() {
      processed = dbPaths.length;
    });
    // Add new image that not exist in database before.
    for (int i = 0; i < newPaths.length; i++) {
      if (!dbPaths.contains(newPaths[i])) {
        List<String> objdetectionResult = await inference(newPaths[i]);
        String text = "";
        String mainCategory = "";
        if (objdetectionResult.isNotEmpty) {
          mainCategory = objdetectionResult[0];
          if (mainCategory == "Document") {
            requestOcr(newPaths[i])
                .then((text) => widget.assetBox.putAsync(ImageData(
                      imagePath: newPaths[i],
                      mainCategory: mainCategory,
                      category: objdetectionResult,
                      text: text,
                    )));
          } else {
            widget.assetBox.putAsync(ImageData(
              imagePath: newPaths[i],
              mainCategory: mainCategory,
              category: objdetectionResult,
              text: text,
            ));
          }
        }

        setState(() {
          processed++;
        });
      }
    }
    setState(() {
      busy = false;
    });
  }

  @override
  void initState() {
    controller = FloatingSearchBarController();
    isolateUtils = IsolateUtils();
    isolateUtils.start();
    _fetchAssets().then((data) {
      classifier.load().then((data) {
        addDB();
      });
    });
    super.initState();
  }

  void printDB() {
    List<ImageData> dataBase = widget.assetBox.getAll();
    print(dataBase);
  }

  void deleteDB() {
    widget.assetBox.removeAll();
  }

  String queryImage(String queryCategory) {
    Query<ImageData> query;
    if (queryCategory == "Recent") {
      query = widget.assetBox.query().build();
    } else {
      query = widget.assetBox
          .query(ImageData_.mainCategory.equals(queryCategory))
          .build();
    }
    ImageData? doc = query.findFirst();

    if (doc != null && File(doc.imagePath).existsSync()) {
      return doc.imagePath;
    }
    List<String> imagePaths = query.property(ImageData_.imagePath).find();
    for (String imagePath in imagePaths) {
      if (File(imagePath).existsSync()) {
        return imagePath;
      }
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
        img = Image.file(
          File(imgPath),
          fit: BoxFit.cover,
        );
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
    }
    if (busy) {
      gridElement.add(Container(
        height: screenHeight,
      ));
    }
    gridElement.add(
        ElevatedButton(onPressed: deleteDB, child: const Text("DeleteDb")));
    double padding = 100;
    return GridView.count(
      padding: EdgeInsets.only(top: padding),
      // shrinkWrap: true,
      crossAxisCount: 2,
      children: gridElement,
    );
  }

  List<String> _searchHistory = [];

  static const historyLength = 5;

  List<String> filteredSearchHistory = [];

  List<String> filterSearchTerms({
    required String filter,
  }) {
    if (filter.isNotEmpty) {
      return _searchHistory.reversed
          .where((term) => term.startsWith(filter))
          .toList();
    } else {
      return _searchHistory.reversed.toList();
    }
  }

  void deleteSearchTerm(String term) {
    _searchHistory.removeWhere((t) => t == term);
    filteredSearchHistory = filterSearchTerms(filter: "");
  }

  void putSearchTermFirst(String term) {
    deleteSearchTerm(term);
    addSearchTerm(term);
  }

  void addSearchTerm(String term) {
    if (_searchHistory.contains(term)) {
      putSearchTermFirst(term);
      return;
    }

    _searchHistory.add(term);
    if (_searchHistory.length > historyLength) {
      _searchHistory.removeRange(0, _searchHistory.length - historyLength);
    }

    filteredSearchHistory = filterSearchTerms(filter: "");
  }

  // The currently searched-for term
  String selectedTerm = "";
  late FloatingSearchBarController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Domacod'),
            ),
            ListTile(
              title: const Text('Item 1'),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
            ListTile(
              title: const Text('Disclaimer'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DisclaimerView()),
                );
              },
            ),
          ],
        ),
      ),
      body: FloatingSearchBar(
        controller: controller,
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
                      children: [
                        const CircularProgressIndicator(),
                        const Spacer(),
                        Text("Indexed $processed of ${assets.length}"),
                        const Spacer(
                          flex: 2,
                        ),
                      ],
                    ),
                  )
                : Container(),
          ),
        ]),
        transition: CircularFloatingSearchBarTransition(),
        physics: const BouncingScrollPhysics(),
        title: Text(
          selectedTerm,
          style: Theme.of(context).textTheme.headline6,
        ),
        hint: 'Search and find out...',
        actions: [
          FloatingSearchBarAction.searchToClear(),
        ],
        onQueryChanged: (query) {
          setState(() {
            filteredSearchHistory = filterSearchTerms(filter: query);
          });
        },
        onSubmitted: (query) {
          setState(() {
            addSearchTerm(query);
            // selectedTerm = query;
            selectedTerm = "";
          });
          controller.close();
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SearchResultView(
                      query: query,
                      assetBox: widget.assetBox,
                      assets: assets,
                    )),
          );
        },
        builder: (context, transition) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Material(
              color: Colors.white,
              elevation: 4,
              child: Builder(
                builder: (context) {
                  if (filteredSearchHistory.isEmpty &&
                      controller.query.isEmpty) {
                    return Container(
                      height: 56,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Text(
                        'Start searching',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.caption,
                      ),
                    );
                  } else if (filteredSearchHistory.isEmpty) {
                    return ListTile(
                      title: Text(controller.query),
                      leading: const Icon(Icons.search),
                      onTap: () {
                        setState(() {
                          addSearchTerm(controller.query);
                          selectedTerm = controller.query;
                        });
                        controller.close();
                      },
                    );
                  } else {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: filteredSearchHistory
                          .map(
                            (term) => ListTile(
                              title: Text(
                                term,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              leading: const Icon(Icons.history),
                              trailing: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    deleteSearchTerm(term);
                                  });
                                },
                              ),
                              onTap: () {
                                setState(() {
                                  putSearchTermFirst(term);
                                  selectedTerm = term;
                                });
                                controller.close();
                              },
                            ),
                          )
                          .toList(),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
