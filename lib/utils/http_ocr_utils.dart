import 'package:http/http.dart' as http;

Future<String> requestOcr(String path) async {
  String text = "";
  var request = http.MultipartRequest('POST',
      Uri.parse("https://asia-southeast1-domacod.cloudfunctions.net/ocr"));
  request.files.add(await http.MultipartFile.fromPath('file', path));

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    text = await response.stream.bytesToString();
    return text;
  } else {
    print("Not 200 response ${response.reasonPhrase}");
    print("Not 200 response ${response.statusCode}");
    print("Not 200 response ${response.stream.bytesToString()}");
  }
  return text;
}
