import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

Future<Map<String, dynamic>> requestOcr(File imgFile) async {
  String text = "";
  Uint8List data = await FlutterImageCompress.compressWithList(
    await imgFile.readAsBytes(),
    minWidth: 1600,
    minHeight: 1600,
    format: CompressFormat.jpeg,
  );

  var request = http.MultipartRequest(
      'POST', Uri.parse("https://domacod.as.r.appspot.com/ocr"));
  // request.files.add(await http.MultipartFile.fromPath('file', path));
  request.files
      .add(http.MultipartFile.fromBytes('file', data, filename: "img.jpg"));
  http.StreamedResponse response;
  try {
    response = await request.send();
  } catch (e) {
    return {"text": text, "complete": false};
  }

  if (response.statusCode == 200) {
    text = await response.stream.bytesToString();
    return {"text": text, "complete": true};
  } else {
    print(
        "Not 200 response ${response.statusCode} ${response.reasonPhrase} ${await response.stream.bytesToString()}");
  }
  return {"text": text, "complete": false};
}
