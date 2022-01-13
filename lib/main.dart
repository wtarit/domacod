import 'package:domacod/grid_image_view.dart';
import 'package:domacod/home_page.dart';
import 'package:domacod/tflite/recognition.dart';
import 'package:domacod/utils/path_utils.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'objectbox.dart';
import 'image_data_models.dart';
import 'dart:isolate';
import 'utils/isolate_utils.dart';
import 'tflite/classifier_yolov4.dart';
import 'package:http/http.dart' as http;

/// Provides access to the ObjectBox Store throughout the app.
late ObjectBox objectbox;

Future<void> main() async {
  // This is required so ObjectBox can get the application directory
  // to store the database in.
  WidgetsFlutterBinding.ensureInitialized();

  objectbox = await ObjectBox.create();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final assetBox = objectbox.store.box<ImageData>();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Domacod',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(
        assetBox: assetBox,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  void printPath() {
    int index = 0;
    if (assets.isNotEmpty) {
      String? relpath = assets[index].relativePath;
      String? fname = assets[index].title;

      String path = getAbsolutePath(relpath, fname);
      print(path);
    } else {
      print("No image to index");
    }
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

  void printDB() {
    List<ImageData> a = assetBox.getAll();
    print("There are ${a.length} object");
    print(a);
  }

  void deleteDB() {
    assetBox.removeAll();
  }

  void inferone() async {
    // String imgPath = "/storage/emulated/0/DCIM/Camera/brave_ywwYLP3X1K.jpg";
    String imgPath = "/storage/emulated/0/DCIM/Camera/w644.jpg";
    List<String> objdetectionResult = await inference(imgPath);
    if (objdetectionResult[0] == "Document") {
      var request = http.MultipartRequest('POST',
          Uri.parse("https://asia-southeast1-domacod.cloudfunctions.net/ocr"));
      request.files.add(await http.MultipartFile.fromPath('file', imgPath));

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        print(await response.stream.bytesToString());
      } else {
        print(response.reasonPhrase);
      }
    }
    print("done");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Domacod'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Text('There are ${assets.length} assets'),
          ElevatedButton(onPressed: printDB, child: const Text("printDB")),
          ElevatedButton(onPressed: printPath, child: const Text("print path")),
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
