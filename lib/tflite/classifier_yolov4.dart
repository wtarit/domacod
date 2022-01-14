import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'recognition.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import 'stats.dart';

/// Classifier
class Classifier {
  /// Instance of Interpreter
  late Interpreter interpreter;

  //Interpreter Options (Settings)
  final int numThreads = 4;
  final bool isNNAPI = false;
  final bool isGPU = true;

  /// Labels file loaded as list
  List<String> labels = [];

  static const String modelFileName = "coco_document.tflite";
  static const String labelFileName = "obj.names";

  // Model Input size
  static const int inputSize = 416;

  /// Minimum Confidence Probabilty score threshold
  static const double minConfidence = 0.5;

  /// Non-maximum suppression threshold
  static double mNmsThresh = 0.6;

  /// [ImageProcessor] used to pre-process the image
  late ImageProcessor imageProcessor;

  /// Padding the image to transform into square
  int padSize = 0;

  /// Shapes of output tensors
  List<List<int>> _outputShapes = [];

  /// Types of output tensors
  List<TfLiteType> _outputTypes = [];

  /// Number of results to show
  static const int numResult = 10;

  Classifier();

  Classifier.fromPointer({required this.interpreter, required this.labels}) {
    loadModelFromPointer();
  }

  /// Loads interpreter from asset
  void loadModelFromPointer() {
    try {
      List<Tensor> outputTensors = interpreter.getOutputTensors();
      //print("the length of the ouput Tensors is ${outputTensors.length}");
      _outputShapes = [];
      _outputTypes = [];
      for (Tensor tensor in outputTensors) {
        _outputShapes.add(tensor.shape);
        _outputTypes.add(tensor.type);
      }
    } catch (e) {
      print("Error while creating interpreter: $e");
    }
  }

  /// Loads labels from assets
  void loadLabels() async {
    try {
      labels = await FileUtil.loadLabels("assets/" + labelFileName);
    } catch (e) {
      print("Error while loading labels: $e");
    }
  }

  Future<bool> load() async {
    try {
      interpreter = await Interpreter.fromAsset(
        modelFileName,
        options: InterpreterOptions()..threads = numThreads, //myOptions,
      );

      List<Tensor> outputTensors = interpreter.getOutputTensors();
      //print("the length of the ouput Tensors is ${outputTensors.length}");
      _outputShapes = [];
      _outputTypes = [];
      for (Tensor tensor in outputTensors) {
        _outputShapes.add(tensor.shape);
        _outputTypes.add(tensor.type);
      }
      labels = await FileUtil.loadLabels("assets/" + labelFileName);
    } catch (e) {
      print("Error while creating interpreter: $e");
    }
    return true;
  }

  /// Loads interpreter from asset
  void loadModel() async {
    try {
      //Still working on it
      /*InterpreterOptions myOptions = new InterpreterOptions();
      myOptions.threads = numThreads;
      if (isNNAPI) {
        NnApiDelegate nnApiDelegate;
        bool androidApithresholdMet = true;
        if (androidApithresholdMet) {
          nnApiDelegate = new NnApiDelegate();
          myOptions.addDelegate(nnApiDelegate);
          myOptions.useNnApiForAndroid = true;
        }
      }
      if (isGPU) {
        GpuDelegateV2 gpuDelegateV2 = new GpuDelegateV2();
        myOptions.addDelegate(gpuDelegateV2);
      }*/

      interpreter = await Interpreter.fromAsset(
        modelFileName,
        options: InterpreterOptions()..threads = numThreads, //myOptions,
      );

      List<Tensor> outputTensors = interpreter.getOutputTensors();
      //print("the length of the ouput Tensors is ${outputTensors.length}");
      _outputShapes = [];
      _outputTypes = [];
      for (Tensor tensor in outputTensors) {
        _outputShapes.add(tensor.shape);
        _outputTypes.add(tensor.type);
      }
    } catch (e) {
      print("Error while creating interpreter: $e");
    }
  }

  /// Pre-process the image
  /// Only does something to the image if it doesn't meet the specified input sizes.
  TensorImage getProcessedImage(TensorImage inputImage) {
    padSize = max(inputImage.height, inputImage.width);

    imageProcessor = ImageProcessorBuilder()
        // .add(ResizeWithCropOrPadOp(padSize, padSize))
        .add(ResizeOp(inputSize, inputSize, ResizeMethod.BILINEAR))
        .add(NormalizeOp.multipleChannels([0, 0, 0], [255.0, 255.0, 255.0]))
        .build();
    inputImage = imageProcessor.process(inputImage);
    return inputImage;
  }

  List<Recognition> nms(List<Recognition> list) {
    List<Recognition> nmsList = [];

    // Iterate in each label
    for (String label in labels) {
      List<Recognition> sameClassTmp = [];
      for (Recognition detectionResult in list) {
        if (detectionResult.label == label &&
            detectionResult.score > minConfidence) {
          sameClassTmp.add(detectionResult);
        }
      }
      while (sameClassTmp.isNotEmpty) {
        sameClassTmp.sort((a, b) {
          return b.score.compareTo(a.score);
        });
        Recognition maxProb = sameClassTmp.first;
        nmsList.add(maxProb);

        sameClassTmp = sameClassTmp.whereNot((element) {
          return boxIou(maxProb.location, element.location) > mNmsThresh;
        }).toList();
      }
    }
    return nmsList;
  }

  double boxIou(Rect a, Rect b) {
    return boxIntersection(a, b) / boxUnion(a, b);
  }

  double boxIntersection(Rect a, Rect b) {
    double w = overlap((a.left + a.right) / 2, a.right - a.left,
        (b.left + b.right) / 2, b.right - b.left);
    double h = overlap((a.top + a.bottom) / 2, a.bottom - a.top,
        (b.top + b.bottom) / 2, b.bottom - b.top);
    if ((w < 0) || (h < 0)) {
      return 0;
    }
    double area = (w * h);
    return area;
  }

  double boxUnion(Rect a, Rect b) {
    double i = boxIntersection(a, b);
    double u = ((((a.right - a.left) * (a.bottom - a.top)) +
            ((b.right - b.left) * (b.bottom - b.top))) -
        i);
    return u;
  }

  double overlap(double x1, double w1, double x2, double w2) {
    double l1 = (x1 - (w1 / 2));
    double l2 = (x2 - (w2 / 2));
    double left = ((l1 > l2) ? l1 : l2);
    double r1 = (x1 + (w1 / 2));
    double r2 = (x2 + (w2 / 2));
    double right = ((r1 < r2) ? r1 : r2);
    return right - left;
  }

  /// Transforms a [rect] from coordinates system of the result image back to the one of the input
  /// image.
  Rect inverseTransformRect(
      Rect rect, int inputImageHeight, int inputImageWidth) {
    double factorX = inputImageWidth / inputSize;
    double factorY = inputImageHeight / inputSize;
    return Rect.fromLTRB(
      rect.left * factorX,
      rect.top * factorY,
      rect.right * factorX,
      rect.bottom * factorY,
    );
  }

  /// Runs object detection on the input image
  Map<String, dynamic> predict(image_lib.Image image) {
    var predictStartTime = DateTime.now().millisecondsSinceEpoch;
    var preProcessStart = DateTime.now().millisecondsSinceEpoch;

    // Initliazing TensorImage as the needed model input type
    // of TfLiteType.float32. Then, creating TensorImage from image
    TensorImage inputImage = TensorImage(TfLiteType.float32);
    inputImage.loadImage(image);
    // Do not use static methods, fromImage(Image) or fromFile(File),
    // of TensorImage unless the desired input TfLiteDataType is Uint8.
    // Create TensorImage from image
    // TensorImage inputImage = TensorImage.fromImage(image);

    // Pre-process TensorImage
    inputImage = getProcessedImage(inputImage);

    var preProcessElapsedTime =
        DateTime.now().millisecondsSinceEpoch - preProcessStart;

    // TensorBuffers for output tensors
    TensorBuffer outputLocations = TensorBufferFloat(
        _outputShapes[0]); // The location of each detected object

    List<List<List<double>>> outputClassScores = List.generate(
        _outputShapes[1][0],
        (_) => List.generate(
            _outputShapes[1][1], (_) => List.filled(_outputShapes[1][2], 0.0),
            growable: false),
        growable: false);
    // Inputs object for runForMultipleInputs
    // Use [TensorImage.buffer] or [TensorBuffer.buffer] to pass by reference
    List<Object> inputs = [inputImage.buffer];

    // Outputs map
    Map<int, Object> outputs = {
      0: outputLocations.buffer,
      1: outputClassScores,
    };

    var inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;
    // run inference
    interpreter.runForMultipleInputs(inputs, outputs);

    var inferenceTimeElapsed =
        DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;

    // Using bounding box utils for easy conversion of tensorbuffer to List<Rect>
    List<Rect> locations = BoundingBoxUtils.convert(
      tensor: outputLocations,
      //valueIndex: [1, 0, 3, 2], Commented out because default order is needed.
      boundingBoxAxis: 2,
      boundingBoxType: BoundingBoxType.CENTER,
      coordinateType: CoordinateType.PIXEL,
      height: inputSize,
      width: inputSize,
    );

    List<Recognition> recognitions = [];

    var gridWidth = _outputShapes[0][1];
    List<Rect> rectAtiList = [];
    for (int i = 0; i < gridWidth; i++) {
      // Since we are given a list of scores for each class for
      // each detected Object, we are interested in finding the class
      // with the highest output score

      var maxClassScore = 0.00;
      var labelIndex = -1;

      for (int c = 0; c < labels.length; c++) {
        // output[0][i][c] is the confidence score of c class
        if (outputClassScores[0][i][c] > maxClassScore) {
          labelIndex = c;
          maxClassScore = outputClassScores[0][i][c];
        }
      }
      // Prediction score
      var score = maxClassScore;

      var label;
      if (labelIndex != -1) {
        // Label string
        label = labels.elementAt(labelIndex);
      } else {
        label = null;
      }
      // Makes sure the confidence is above the
      // minimum threshold score for each object.
      if (score > minConfidence) {
        // inverse of rect
        // [locations] corresponds to the image input size
        // inverseTransformRect transforms it our [inputImage]

        Rect rectAti = Rect.fromLTRB(
            max(0, locations[i].left),
            max(0, locations[i].top),
            min(inputSize.toDouble(), locations[i].right),
            min(inputSize.toDouble(), locations[i].bottom));
        rectAtiList.add(rectAti);
        // Gets the coordinates based on the original image if anything was done to it.
        Rect transformedRect = imageProcessor.inverseTransformRect(
            rectAti, image.height, image.width);

        recognitions.add(
          Recognition(i, label, score, transformedRect),
        );
      }
    } // End of for loop and added all recognitions
    List<Recognition> recognitionsNMS = nms(recognitions);
    var predictElapsedTime =
        DateTime.now().millisecondsSinceEpoch - predictStartTime;
    return {
      "recognitions": recognitionsNMS,
      "stats": Stats(
          totalPredictTime: predictElapsedTime,
          inferenceTime: inferenceTimeElapsed,
          preProcessingTime: preProcessElapsedTime),
    };
  }

  Map<String, dynamic> predictFromPath(String filepath) {
    image_lib.Image? img =
        image_lib.decodeImage(File(filepath).readAsBytesSync());
    if (img != null) {
      return predict(img);
    }
    return {"error": "cannot read image"};
  }
}
