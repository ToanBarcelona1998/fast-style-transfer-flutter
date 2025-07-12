import 'dart:io';
import 'dart:typed_data';
import 'package:fast_style_transfer_flutter/src/core/definition/export.dart';
import 'package:fast_style_transfer_flutter/src/core/exception/export.dart';
import 'package:fast_style_transfer_flutter/src/interface/fast_style_transfer.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'core/utils/util.dart';

/// A class that implements fast neural style transfer using TFLite models.
final class FastStyleTransferFlutter implements IFastStyleTransfer {
  Interpreter? _predictionInterpreter;
  Interpreter? _styleTransferInterpreter;

  FastStyleTransferFlutter._internal(
    this._predictionInterpreter,
    this._styleTransferInterpreter,
  );

  /// Factory constructor to initialize interpreters with given config.
  factory FastStyleTransferFlutter.init({
    required FastStyleTransferConfig config,
  }) {
    final FastStyleTransferFlutter instance =
        FastStyleTransferFlutter._internal(null, null);

    instance._load(config);

    return instance;
  }

  /// Loads interpreters based on the provided configuration.
  void _load(FastStyleTransferConfig config) async {
    final predictionOptions = InterpreterOptions()..threads = config.thread;
    final styleTransferOptions = InterpreterOptions()..threads = config.thread;

    // Use GPU delegate for Android and iOS if specified
    if (config.useGPU) {
      if (Platform.isAndroid) {
        predictionOptions.addDelegate(GpuDelegateV2());
        styleTransferOptions.addDelegate(GpuDelegateV2());
      }

      if (Platform.isIOS) {
        predictionOptions.addDelegate(GpuDelegate());
        styleTransferOptions.addDelegate(GpuDelegate());
      }
    }

    final FastStyleLoaderConfig loaderConfig = config.loaderConfig;

    // Load interpreters from asset, file, or memory
    if (loaderConfig is FastStyleAssetsLoaderConfig) {
      _predictionInterpreter = await Interpreter.fromAsset(
        loaderConfig.predictResource,
      );
      _styleTransferInterpreter = await Interpreter.fromAsset(
        loaderConfig.styleTransferResource,
      );
    } else if (loaderConfig is FastStyleFileLoaderConfig) {
      _predictionInterpreter = Interpreter.fromFile(
        loaderConfig.predictResource,
      );
      _styleTransferInterpreter = Interpreter.fromFile(
        loaderConfig.styleTransferResource,
      );
    } else if (loaderConfig is FastStyleBytesLoaderConfig) {
      _predictionInterpreter = Interpreter.fromBuffer(
        loaderConfig.predictResource,
      );
      _styleTransferInterpreter = Interpreter.fromBuffer(
        loaderConfig.styleTransferResource,
      );
    } else {
      throw const FastStyleTransferException(
        msg: 'Unsupported loader config type',
        code: FastStyleTransferExceptionCode.nonSupportLoaderError,
      );
    }
  }

  /// Runs style transfer on the input image and style.
  ///
  /// Returns a JPEG-encoded image as Uint8List.
  @override
  Future<Uint8List> run({required RunTransferRequest request}) async {
    // Check interpreters are initialized
    if (_styleTransferInterpreter == null && _predictionInterpreter == null) {
      throw const FastStyleTransferException(
        msg: 'Call init before using this method',
        code: FastStyleTransferExceptionCode.nonInitError,
      );
    }

    final Uint8List image = request.image;
    final Uint8List style = request.style;

    // Preprocess the input images
    final prepareImageResult = await StyleTransferUtil.prepareImage(
      image: image,
      style: style,
    );

    final Image imageImg = prepareImageResult.$1;
    final Image styleImg = prepareImageResult.$2;

    // Convert image and style to normalized float matrices [0..1]
    final imageMatrix = List.generate(
      imageImg.height,
      (y) => List.generate(imageImg.width, (x) {
        final pixel = imageImg!.getPixel(x, y);
        return [pixel.r / 255, pixel.g / 255, pixel.b / 255];
      }),
    );

    final styleMatrix = List.generate(
      styleImg.height,
      (y) => List.generate(styleImg.width, (x) {
        final pixel = styleImg!.getPixel(x, y);
        return [pixel.r / 255, pixel.g / 255, pixel.b / 255];
      }),
    );

    // Prepare input for prediction model: [1, 256, 256, 3]
    final predictionInput = [styleMatrix];

    // Allocate output tensor for prediction: [1, 1, 1, 100]
    final predictionOutput = [
      [
        [List<double>.filled(100, 0)],
      ],
    ];

    // Run the prediction interpreter to extract style features
    _predictionInterpreter!.run(predictionInput, predictionOutput);

    // Prepare input for transfer model
    final transferInput = [
      [imageMatrix],      // [1, 384, 384, 3] - content image
      predictionOutput,   // [1, 1, 1, 100] - style features
    ];

    // Prepare output for transfer result: [1, 384, 384, 3]
    final transferOutput = [
      List.generate(384, (index) => List.filled(384, [0.0, 0.0, 0.0])),
    ];

    // Run the style transfer interpreter
    _styleTransferInterpreter!.runForMultipleInputs(transferInput, {
      0: transferOutput,
    });

    // Extract float RGB values and convert them to 0-255 Uint8List
    final result = transferOutput.first;

    final buffer = Uint8List.fromList(
      result
          .expand(
            (col) => col.expand((pixel) => pixel.map((e) => (e * 255).toInt())),
          )
          .toList(),
    );

    // Convert to Image object and encode to JPEG
    final imageResult = encodeJpg(
      Image.fromBytes(
        width: StyleTransferUtil.imageSize,
        height: StyleTransferUtil.imageSize,
        bytes: buffer.buffer,
        numChannels: 3,
      ),
    );

    // Return as Uint8List
    return imageResult.buffer.asUint8List();
  }

  /// Releases native interpreter resources.
  void close(){
    _predictionInterpreter?.close();
    _styleTransferInterpreter?.close();
    _predictionInterpreter = null;
    _predictionInterpreter = null;
  }
}
