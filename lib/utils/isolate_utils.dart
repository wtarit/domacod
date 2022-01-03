import 'dart:isolate';
import 'package:image/image.dart' as imageLib;
import '../tflite/classifier_yolov4.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Manages separate Isolate instance for inference
class IsolateUtils {
  static const String DEBUG_NAME = "InferenceIsolate";

  late Isolate _isolate;
  ReceivePort _receivePort = ReceivePort();
  late SendPort _sendPort;

  SendPort get sendPort => _sendPort;

  Future<void> start() async {
    _isolate = await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: DEBUG_NAME,
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
      Map<String, dynamic> results =
          classifier.predictFromPath(isolateData.filepath);
      isolateData.responsePort.send(results);
    }
  }
}

/// Bundles data to pass between Isolate
class IsolateData {
  late String filepath;
  late int interpreterAddress;
  late List<String> labels;
  late SendPort responsePort;

  IsolateData(
    this.filepath,
    this.interpreterAddress,
    this.labels,
  );
}
