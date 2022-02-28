import 'package:domacod/image_data_models.dart';
import 'package:domacod/objectbox.g.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:domacod/utils/http_ocr_utils.dart';
import 'dart:isolate';
import '../tflite/classifier_yolov4.dart';
import '../tflite/recognition.dart';
import '../utils/isolate_utils.dart';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as image_lib;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseProvider extends ChangeNotifier {
  List<AssetEntity> assets = [];
  late Box<ImageData> assetsBox;
  Classifier classifier = Classifier();
  IsolateUtils isolateUtils = IsolateUtils();
  bool busy = true;
  int processed = 0;
  bool useOCR = true;
  bool _reindex = true;

  DatabaseProvider();

  void addDBtoProvider(Box<ImageData> assetsBox) {
    this.assetsBox = assetsBox;
  }

  Future<void> _fetchAssets() async {
    // Set onlyAll to true, to fetch only the 'Recent' album
    // which contains all the photos/videos in the storage
    final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image, onlyAll: true);
    if (albums.isNotEmpty) {
      final recentAlbum = albums.first;
      if (recentAlbum.assetCount != 0) {
        // Now that we got the album, fetch all the assets it contains
        assets = await recentAlbum.getAssetListRange(
          start: 0, // start at index 0
          end: recentAlbum.assetCount, // end at max number of assets
        );
      }
    }
    // PhotoManager.addChangeCallback(changeNotify);
    // PhotoManager.startChangeNotify();
  }

  void changeNotify(value) async {
    if (busy) {
      _reindex = true;
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      Map<String, dynamic> data = Map<String, dynamic>.from(value.arguments);
      if (data["type"] == "insert") {
        if (!assets.map((e) => e.id).contains(data["id"].toString())) {
          final asset = await AssetEntity.fromId(data["id"].toString());
          if (asset != null) {
            assets.add(asset);
          }
        }
      } else if (data["type"] == "delete") {
        assets.removeWhere((element) => element.id == data["id"].toString());
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      Map<String, dynamic> data = Map<String, dynamic>.from(value.arguments);
      if (data["create"].length >= 1) {
        for (var id in data["create"]) {
          if (!assets.map((e) => e.id).contains(id["id"])) {
            final asset = await AssetEntity.fromId(id["id"]);
            if (asset != null) {
              assets.add(asset);
            }
          }
        }
      } else if (data["delete"].length >= 1) {
        for (var id in data["delete"]) {
          assets.removeWhere((element) => element.id == id["id"]);
        }
      }
    }
    print("ioschange");
    addDB();
  }

  // Runs inference in another isolate
  Future<List<String>> inference(File imgFile) async {
    String filepath = imgFile.path;
    Uint8List data = await imgFile.readAsBytes();
    IsolateData isolateData;
    if (p.extension(filepath) == ".heic") {
      data = await FlutterImageCompress.compressWithList(
        data,
        minWidth: 416,
        minHeight: 416,
        format: CompressFormat.jpeg,
      );
      image_lib.Image? img = image_lib.decodeImage(data);
      if (img == null) {
        return [];
      }
      isolateData = IsolateData(
        interpreterAddress: classifier.interpreter.address,
        labels: classifier.labels,
        img: img,
      );
    } else {
      isolateData = IsolateData(
        interpreterAddress: classifier.interpreter.address,
        labels: classifier.labels,
        imgPath: filepath,
      );
    }

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

  Future<void> addDB() async {
    busy = true;
    Query<ImageData> queryIDs = assetsBox.query().build();
    List<String> dbIDs = queryIDs.property(ImageData_.imageID).find();

    // Loop over database to see which image is deleted.
    for (int i = 0; i < dbIDs.length; i++) {
      if (!assets[i].id.contains(dbIDs[i])) {
        Query<ImageData> queryDBIDs =
            assetsBox.query(ImageData_.imageID.equals(dbIDs[i])).build();
        ImageData? toremove = queryDBIDs.findFirst();
        if (toremove != null) {
          assetsBox.remove(toremove.id);
        }
      }
    }
    processed = dbIDs.length;
    notifyListeners();
    // Add new image that not exist in database before.
    for (AssetEntity asset in assets) {
      if (!dbIDs.contains(asset.id)) {
        File? imgFile = await asset.file;
        if (imgFile == null) {
          continue;
        }
        List<String> objdetectionResult = await inference(imgFile);
        String mainCategory = "";
        if (objdetectionResult.isNotEmpty) {
          mainCategory = objdetectionResult[0];
        }
        if (mainCategory == "Document" && useOCR) {
          requestOcr(imgFile).then((data) {
            ImageData writeToDB = ImageData(
              imageID: asset.id,
              mainCategory: mainCategory,
              category: objdetectionResult,
              text: data["text"],
              doneOCR: data["complete"],
            );
            addImage(writeToDB);
          });
        } else {
          ImageData writeToDB = ImageData(
            imageID: asset.id,
            mainCategory: mainCategory,
            category: objdetectionResult,
            text: "",
            doneOCR: false,
          );
          addImage(writeToDB);
        }
        processed++;
        notifyListeners();
      }
    }
  }

  void indexImages(Future<SharedPreferences> _prefs) async {
    SharedPreferences prefs = await _prefs;
    useOCR = prefs.getBool('useOCR') ?? true;
    await classifier.load();
    await isolateUtils.start();
    while (_reindex) {
      _reindex = false;
      await _fetchAssets();
      await addDB();
    }
    busy = false;
    notifyListeners();
  }

  void addImage(ImageData data) {
    assetsBox.put(data);
    notifyListeners();
  }

  void deleteDBbyID(String deleteID) {
    Query<ImageData> query =
        assetsBox.query(ImageData_.imageID.equals(deleteID)).build();
    assetsBox.remove(query.findIds()[0]);
    notifyListeners();
  }

  List<String> queryCategory(String imageID) {
    Query<ImageData> query =
        assetsBox.query(ImageData_.imageID.equals(imageID)).build();
    ImageData? result = query.findFirst();
    if (result == null) {
      return [];
    }
    return result.category.toSet().toList();
  }

  List<ImageCategoryThumbnail> getThumbData() {
    if (assets.isEmpty) return [];
    List<ImageCategoryThumbnail> thumbresult = [];
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
      "Tree",
    ];
    for (String category in categories) {
      if (category == "Recent") {
        thumbresult.add(
          ImageCategoryThumbnail(
              category: category,
              amount: assets.length,
              thumbdata: assets[0].file),
        );
      } else {
        Query<ImageData> query =
            assetsBox.query(ImageData_.mainCategory.equals(category)).build();
        ImageData? result = query.findFirst();
        if (result == null) {
          query =
              assetsBox.query(ImageData_.category.contains(category)).build();
          result = query.findFirst();
          if (result == null) {
            continue;
          }
        }
        AssetEntity resultasset =
            assets.firstWhere((element) => element.id == result!.imageID);
        thumbresult.add(ImageCategoryThumbnail(
          category: category,
          amount: query.count(),
          thumbdata: resultasset.file,
        ));
      }
    }
    return thumbresult;
  }

  get getDB => assetsBox;
}

class ImageCategoryThumbnail {
  String category;
  int amount;
  Future<File?> thumbdata;
  ImageCategoryThumbnail({
    required this.category,
    required this.amount,
    required this.thumbdata,
  });
}
