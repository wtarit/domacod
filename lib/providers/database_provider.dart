import 'package:domacod/image_data_models.dart';
import 'package:domacod/objectbox.g.dart';
import 'package:flutter/material.dart';

class DatabaseProvider extends ChangeNotifier {
  late Box<ImageData> assetsBox;
  DatabaseProvider();
  void addDBtoProvider(Box<ImageData> assetsBox) {
    this.assetsBox = assetsBox;
  }

  void addImage(ImageData data) {
    assetsBox.put(data);
    notifyListeners();
  }

  void deleteDBbyPath(String deletePath) {
    Query<ImageData> query =
        assetsBox.query(ImageData_.imagePath.equals(deletePath)).build();
    assetsBox.remove(query.findIds()[0]);
    notifyListeners();
  }

  List<String> queryCategory(String imagePath) {
    Query<ImageData> query =
        assetsBox.query(ImageData_.imagePath.equals(imagePath)).build();
    ImageData? result = query.findFirst();
    if (result == null) {
      return [];
    }
    return result.category.toSet().toList();
  }

  get getDB => assetsBox;
}
