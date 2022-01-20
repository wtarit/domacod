import 'package:objectbox/objectbox.dart';

@Entity()
class ImageData {
  int id;
  String imagePath;
  String mainCategory;
  List<String> category;
  String text;
  bool doneOCR;
  ImageData({
    this.id = 0,
    required this.imagePath,
    required this.mainCategory,
    required this.category,
    required this.text,
    required this.doneOCR,
  });
}
