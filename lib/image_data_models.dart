import 'package:objectbox/objectbox.dart';

@Entity()
class ImageData {
  int id;
  String imageID;
  String mainCategory;
  List<String> category;
  String text;
  bool doneOCR;
  String subject;
  ImageData({
    this.id = 0,
    required this.imageID,
    required this.mainCategory,
    required this.category,
    required this.text,
    required this.doneOCR,
    required this.subject,
  });
}
