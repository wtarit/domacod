import 'package:domacod/objectbox.g.dart';
import 'package:domacod/screen/disclaimer.dart';
import 'package:domacod/screen/settings.dart';
import 'package:domacod/search_result_view.dart';
import 'package:domacod/widgets/category_thumbnail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'image_data_models.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:domacod/providers/database_provider.dart';
import 'package:flutter/foundation.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key, required this.assetsBox}) : super(key: key);

  final Box<ImageData> assetsBox;
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late double screenWidth = MediaQuery.of(context).size.width;
  late double screenHeight = MediaQuery.of(context).size.height;

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
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
            defaultTargetPlatform != TargetPlatform.iOS
                ? TextButton(
                    child: const Text('Quit App'),
                    onPressed: () {
                      // Navigator.of(context).pop();
                      SystemChannels.platform
                          .invokeMethod<void>('SystemNavigator.pop');
                    },
                  )
                : Container(),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                PhotoManager.openSetting();
                var result = await PhotoManager.requestPermissionExtend();
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

  Future<void> _requestPermission() async {
    var result = await PhotoManager.requestPermissionExtend();
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (!result.isAuth) {
        await _showPermissionDialog();
      }
    } else {
      if (result.index == 2) {
        await _showPermissionDialog();
      }
    }
  }

  @override
  void initState() {
    context.read<DatabaseProvider>().addDBtoProvider(widget.assetsBox);
    controller = FloatingSearchBarController();
    _requestPermission()
        .then((value) => context.read<DatabaseProvider>().indexImages(_prefs));
    super.initState();
  }

  Widget categoryGrid() {
    double width = MediaQuery.of(context).size.width;
    List<ImageCategoryThumbnail> thumbnailData =
        context.read<DatabaseProvider>().getThumbData();
    List<Widget> gridElement = [];
    for (ImageCategoryThumbnail thumb in thumbnailData) {
      gridElement.add(CategoryThumbnail(thumb: thumb));
    }
    if (context.watch<DatabaseProvider>().busy) {
      gridElement.add(Container());
    }
    double padding = 100;
    return GridView.count(
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      padding: EdgeInsets.only(top: padding),
      // shrinkWrap: true,
      crossAxisCount: width ~/ 180,
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
                color: Colors.teal,
              ),
              child: Text(
                'Domacod',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Disclaimer'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DisclaimerScreen()),
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
            child: context.watch<DatabaseProvider>().busy
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
                        Text(
                          "Indexed ${context.watch<DatabaseProvider>().processed} of ${context.watch<DatabaseProvider>().assets.length}",
                          style: const TextStyle(color: Colors.black),
                        ),
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
              ),
            ),
          );
        },
        builder: (context, transition) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Material(
              color: Colors.black87,
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
                                putSearchTermFirst(term);
                                // selectedTerm = term;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchResultView(
                                      query: term,
                                    ),
                                  ),
                                );
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
