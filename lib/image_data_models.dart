import 'package:objectbox/objectbox.dart';

@Entity()
class ImageData {
  int id;
  String imagePath;
  List<String> category;
  String text;
  ImageData({
    this.id = 0,
    required this.imagePath,
    required this.category,
    required this.text,
  });
}
