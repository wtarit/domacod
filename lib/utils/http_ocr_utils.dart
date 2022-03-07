import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

Future<PredictionResponse> requestOcr(File imgFile) async {
  Uint8List data = await FlutterImageCompress.compressWithList(
    await imgFile.readAsBytes(),
    minWidth: 1600,
    minHeight: 1600,
    format: CompressFormat.jpeg,
  );

  var request = http.MultipartRequest(
      'POST',
      Uri.parse(
          "https://subject-classification-dot-domacod.as.r.appspot.com/predict"));
  // request.files.add(await http.MultipartFile.fromPath('file', path));
  request.files
      .add(http.MultipartFile.fromBytes('file', data, filename: "img.jpg"));
  http.StreamedResponse response;
  try {
    response = await request.send().timeout(const Duration(seconds: 100));
  } catch (e) {
    return PredictionResponse(
      text: "",
      subject: "",
      complete: false,
    );
  }

  if (response.statusCode == 200) {
    String jsonString = await response.stream.bytesToString();
    Map<String, dynamic> json = jsonDecode(jsonString);
    return PredictionResponse(
      text: json["text"],
      subject: json["subject"],
      complete: true,
    );
  } else {
    print(
        "Not 200 response ${response.statusCode} ${response.reasonPhrase} ${await response.stream.bytesToString()}");
  }
  return PredictionResponse(
    text: "",
    subject: "",
    complete: false,
  );
}

class PredictionResponse {
  String text;
  String subject;
  bool complete;
  PredictionResponse({
    required this.text,
    required this.subject,
    required this.complete,
  });
}
