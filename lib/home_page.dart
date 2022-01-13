import 'dart:io';

import 'package:domacod/grid_image_view.dart';
import 'package:domacod/objectbox.g.dart';
import 'package:domacod/search_result_view.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'image_data_models.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'utils/path_utils.dart';
import 'package:http/http.dart' as http;
import 'tflite/classifier_yolov4.dart';
import 'utils/isolate_utils.dart';
import 'dart:isolate';
import 'tflite/recognition.dart';

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

  Future<List<AssetEntity>> _fetchAssets() async {
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
      return recentAssets;
    }
    return [];
  }

  /// Runs inference in another isolate
  Future<List<String>> inference(String filepath) async {
    IsolateData isolateData = IsolateData(
      filepath,
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

    // Add new image that not exist in database before.
    for (int i = 0; i < newPaths.length; i++) {
      if (!dbPaths.contains(newPaths[i])) {
        List<String> objdetectionResult = await inference(newPaths[i]);
        String text = "";
        String mainCategory = "";
        if (objdetectionResult.isNotEmpty) {
          mainCategory = objdetectionResult[0];
          if (mainCategory == "Document") {
            var request = http.MultipartRequest(
                'POST',
                Uri.parse(
                    "https://asia-southeast1-domacod.cloudfunctions.net/ocr"));
            request.files
                .add(await http.MultipartFile.fromPath('file', newPaths[i]));

            http.StreamedResponse response = await request.send();

            if (response.statusCode == 200) {
              text = await response.stream.bytesToString();
            } else {
              print(response.reasonPhrase);
            }
          }
        }
        await widget.assetBox.putAsync(ImageData(
          imagePath: newPaths[i],
          mainCategory: mainCategory,
          category: objdetectionResult,
          text: text,
        ));
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
      addDB();
    });
    super.initState();
  }

  void printDB() {
    // List<ImageData> a = widget.assetBox.getAll();
    // Query<ImageData> query =
    //     widget.assetBox.query(ImageData_.category.contains("Document")).build();
    // ImageData? doc = query.findFirst();
    // if (doc != null) {
    //   print(doc);
    // }
    // var fsb = FloatingSearchBar.of(context);

    // double padding = 0;
    // if (fsb != null) {
    //   padding = fsb.widget.height;
    //   print(padding);
    // }
    // print(fsb);
    setState(() {
      busy = !busy;
    });
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
    gridElement.add(ElevatedButton(onPressed: printDB, child: Text("test")));
    final fsb = FloatingSearchBar.of(context);
    double padding = 100;
    if (fsb != null) {
      padding = fsb.widget.height;
      print(padding);
    }
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
      body: FloatingSearchBar(
        controller: controller,
        // body: FloatingSearchBarScrollNotifier(
        //   child: SearchResultView(
        //       // searchTerm: selectedTerm,
        //       ),
        // ),
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
        physics: BouncingScrollPhysics(),
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
                      )));
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
