import 'dart:io';

import 'package:domacod/grid_image_view.dart';
import 'package:domacod/objectbox.g.dart';
import 'package:domacod/search_result_view.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'image_data_models.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key, required this.assetBox}) : super(key: key);

  final Box<ImageData> assetBox;
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool busy = false;
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
    controller = FloatingSearchBarController();
    _fetchAssets();
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
    var fsb = FloatingSearchBar.of(context);

    double padding = 0;
    if (fsb != null) {
      padding = fsb.widget.height;
      print(padding);
    }
    print(fsb);
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

  List<String> _searchHistory = [
    'fuchsia',
    'flutter',
    'widgets',
    'resocoder',
  ];

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
                        Text("Indexed 0 of ${assets.length}"),
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
