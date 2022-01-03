import 'package:domacod/grid_image_view.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'objectbox.dart';
import 'image_data_models.dart';
import 'package:path/path.dart' as p;
import 'dart:isolate';
import 'utils/isolate_utils.dart';
import 'tflite/classifier_yolov4.dart';

/// Provides access to the ObjectBox Store throughout the app.
late ObjectBox objectbox;

Future<void> main() async {
  // This is required so ObjectBox can get the application directory
  // to store the database in.
  WidgetsFlutterBinding.ensureInitialized();

  objectbox = await ObjectBox.create();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Domacod',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Icon customIcon = const Icon(Icons.search);
  Widget customSearchBar = const Text('Domacod');

  List<AssetEntity> assets = [];
  final assetBox = objectbox.store.box<ImageData>();
  bool busy = false;
  int processed = 0;
  late IsolateUtils isolateUtils;
  Classifier classifier = Classifier();

  @override
  void initState() {
    isolateUtils = IsolateUtils();
    isolateUtils.start();
    _fetchAssets();
    super.initState();
  }

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

  void doSomething() {
    if (assets.isNotEmpty) {
      String? relpath = assets[0].relativePath;
      String? fname = assets[0].title;

      String path = p.join("", relpath, fname);
      print(p.isAbsolute(path));
      print(path);
    } else {
      print("No image to index");
    }
  }

  /// Runs inference in another isolate
  Future<Map<String, dynamic>> inference(String filepath) async {
    IsolateData isolateData = IsolateData(
      filepath,
      classifier.interpreter.address,
      classifier.labels,
    );
    ReceivePort responsePort = ReceivePort();
    isolateUtils.sendPort
        .send(isolateData..responsePort = responsePort.sendPort);
    var results = await responsePort.first;
    print(results);
    return results;
  }

  void addDB() async {
    setState(() {
      busy = true;
    });
    List<String> newPaths = [];
    List<String> dbPaths = [];
    List<ImageData> dataBase = assetBox.getAll();
    for (ImageData db in dataBase) {
      dbPaths.add(db.imagePath);
    }
    for (AssetEntity asset in assets) {
      String? relpath = asset.relativePath;
      String? fname = asset.title;
      String path = "";
      if (relpath != null && fname != null) {
        path = p.join(relpath, fname);
        if (!p.isAbsolute(path)) {
          path = p.join("/storage/emulated/0/", path);
        }
      }
      newPaths.add(path);
    }

    // Loop over database to see which image is deleted.
    for (int i = 0; i < dbPaths.length; i++) {
      if (!newPaths.contains(dbPaths[i])) {
        assetBox.remove(dataBase[i].id);
      }
    }

    // Add new image that not exist in database before.
    for (int i = 0; i < newPaths.length; i++) {
      if (!dbPaths.contains(newPaths[i])) {
        // TODO: Add inferencing code
        await inference(newPaths[i]);
        setState(() {
          processed++;
        });
      }
    }
    setState(() {
      busy = false;
    });
  }

  void printDB() {
    List<ImageData> a = assetBox.getAll();
    print(a.length);
  }

  void deleteDB() {
    assetBox.removeAll();
  }

  void inferone() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: customSearchBar,
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  if (customIcon.icon == Icons.search) {
                    customIcon = const Icon(Icons.cancel);
                    customSearchBar = const ListTile(
                      leading: Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 28,
                      ),
                      title: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'search',
                          hintStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                          ),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    );
                  } else {
                    customIcon = const Icon(Icons.search);
                    customSearchBar = const Text('Domacod');
                  }
                });
              },
              icon: customIcon)
        ],
      ),
      body: Column(
        children: <Widget>[
          Text('There are ${assets.length} assets'),
          ElevatedButton(onPressed: addDB, child: const Text("addDB")),
          ElevatedButton(onPressed: printDB, child: const Text("printDB")),
          ElevatedButton(
              onPressed: doSomething, child: const Text("print path")),
          ElevatedButton(onPressed: deleteDB, child: const Text("deleteDB")),
          ElevatedButton(onPressed: inferone, child: const Text("inferone")),
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => GridImageView(
                              assets: assets,
                              assetBox: assetBox,
                              category: "recent",
                            )));
              },
              child: const Text("Push to Grid View")),
          busy
              ? Container(
                  child: Row(
                    children: [
                      const CircularProgressIndicator(),
                      Text("Indexed $processed of ${assets.length}")
                    ],
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
