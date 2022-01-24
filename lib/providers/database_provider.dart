import 'package:domacod/image_data_models.dart';
import 'package:domacod/objectbox.g.dart';
import 'package:flutter/material.dart';
import 'dart:io';

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

  PathAndAmount queryPathAndAmount(String queryCategory) {
    int amount = 0;
    Query<ImageData> query;
    if (queryCategory == "Recent") {
      query = assetsBox.query().build();
      amount = query.count();
    } else {
      query = assetsBox
          .query(ImageData_.mainCategory.equals(queryCategory))
          .build();
      amount = query.count();
    }
    List<ImageData> docs = query.find();
    if (docs.isEmpty) {
      query =
          assetsBox.query(ImageData_.category.contains(queryCategory)).build();
      amount = query.count();
      docs = query.find();
    }
    if (docs.isNotEmpty) {
      ImageData doc = docs.last;
      if (File(doc.imagePath).existsSync()) {
        return PathAndAmount(imagePath: doc.imagePath, amount: amount);
      }
    }
    return PathAndAmount(imagePath: "", amount: amount);
  }

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
