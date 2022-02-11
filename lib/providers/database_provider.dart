import 'package:domacod/image_data_models.dart';
import 'package:domacod/objectbox.g.dart';
import 'package:flutter/material.dart';
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

class DatabaseProvider extends ChangeNotifier {
  List<AssetEntity> assets = [];
  late Box<ImageData> assetsBox;
  Classifier classifier = Classifier();
  IsolateUtils isolateUtils = IsolateUtils();
  bool busy = true;
  int processed = 0;

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
      // Now that we got the album, fetch all the assets it contains
      assets = await recentAlbum.getAssetListRange(
        start: 0, // start at index 0
        end: recentAlbum.assetCount, // end at max number of assets
      );
    }
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
    List<String> newIDs = [];
    List<String> dbIDs = [];
    List<ImageData> dataBase = assetsBox.getAll();
    for (ImageData db in dataBase) {
      dbIDs.add(db.imageID);
    }
    for (AssetEntity asset in assets) {
      newIDs.add(asset.id);
    }

    // Loop over database to see which image is deleted.
    for (int i = 0; i < dbIDs.length; i++) {
      if (!newIDs.contains(dbIDs[i])) {
        assetsBox.remove(dataBase[i].id);
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
        if (objdetectionResult.isNotEmpty) {
          String mainCategory = objdetectionResult[0];
          // if (mainCategory == "Document" && useOCR) {
          if (mainCategory == "Document") {
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
        } else {
          ImageData writeToDB = ImageData(
            imageID: asset.id,
            mainCategory: "",
            category: objdetectionResult,
            text: "",
            doneOCR: false,
          );
          addImage(writeToDB);
        }
      }
      processed++;
      notifyListeners();
    }
  }

  void indexImages() async {
    print("DEBUG: Start index");
    await _fetchAssets();
    print("DEBUG: fetched assets ${assets.length}");
    await classifier.load();
    await isolateUtils.start();
    await addDB();
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

  // PathAndAmount queryPathAndAmount(String queryCategory) {
  //   int amount = 0;
  //   Query<ImageData> query;
  //   if (queryCategory == "Recent") {
  //     query = assetsBox.query().build();
  //     amount = query.count();
  //   } else {
  //     query = assetsBox
  //         .query(ImageData_.mainCategory.equals(queryCategory))
  //         .build();
  //     amount = query.count();
  //   }
  //   List<ImageData> docs = query.find();
  //   if (docs.isEmpty) {
  //     query =
  //         assetsBox.query(ImageData_.category.contains(queryCategory)).build();
  //     amount = query.count();
  //     docs = query.find();
  //   }
  //   if (docs.isNotEmpty) {
  //     ImageData doc = docs.last;
  //     if (File(doc.imagePath).existsSync()) {
  //       return PathAndAmount(imagePath: doc.imagePath, amount: amount);
  //     }
  //   }
  //   return PathAndAmount(imagePath: "", amount: amount);
  // }

  get getDB => assetsBox;
}

class PathAndAmount {
  late String imagePath;
  late int amount;
  PathAndAmount({
    required this.imagePath,
    required this.amount,
  });
}
