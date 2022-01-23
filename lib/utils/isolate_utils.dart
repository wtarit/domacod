import 'dart:isolate';
import '../tflite/classifier_yolov4.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as image_lib;

/// Manages separate Isolate instance for inference
class IsolateUtils {
  static const String debugName = "InferenceIsolate";

  late Isolate _isolate;
  ReceivePort _receivePort = ReceivePort();
  late SendPort _sendPort;

  SendPort get sendPort => _sendPort;

  Future<void> start() async {
    _isolate = await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: debugName,
    );

    _sendPort = await _receivePort.first;
  }

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final IsolateData isolateData in port) {
      Classifier classifier = Classifier.fromPointer(
          interpreter: Interpreter.fromAddress(isolateData.interpreterAddress),
          labels: isolateData.labels);
      Map<String, dynamic> results = {};
      if (isolateData.img != null) {
        results = classifier.predict(isolateData.img!);
      } else {
        results = classifier.predictFromPath(isolateData.imgPath!);
      }
      isolateData.responsePort.send(results);
    }
  }
}

/// Bundles data to pass between Isolate
class IsolateData {
  late int interpreterAddress;
  late List<String> labels;
  late String? imgPath;
  late image_lib.Image? img;
  late SendPort responsePort;

  IsolateData({
    required this.interpreterAddress,
    required this.labels,
    this.img,
    this.imgPath,
  });
}
