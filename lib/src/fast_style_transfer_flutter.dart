import 'dart:io';
import 'dart:typed_data';
import 'package:fast_style_transfer_flutter/src/core/definition/export.dart';
import 'package:fast_style_transfer_flutter/src/core/exception/export.dart';
import 'package:fast_style_transfer_flutter/src/interface/fast_style_transfer.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'core/extension/util.dart';

final class FastStyleTransferFlutter implements IFastStyleTransfer {
  Interpreter? _predictionInterpreter;
  Interpreter? _styleTransferInterpreter;

  FastStyleTransferFlutter._internal(
    this._predictionInterpreter,
    this._styleTransferInterpreter,
  );

  factory FastStyleTransferFlutter.init({
    required FastStyleTransferConfig config,
  }) {
    final FastStyleTransferFlutter instance =
        FastStyleTransferFlutter._internal(null, null);

    instance._load(config);

    return instance;
  }

  void _load(FastStyleTransferConfig config) async {
    final predictionOptions = InterpreterOptions()..threads = config.thread;
    final styleTransferOptions = InterpreterOptions()..threads = config.thread;

    // Set GPU delegate
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

  @override
  Future<Uint8List> run({required RunTransferRequest request}) async {
    if (_styleTransferInterpreter == null && _predictionInterpreter == null) {
      throw const FastStyleTransferException(
        msg: 'Call init before using this method',
        code: FastStyleTransferExceptionCode.nonInitError,
      );
    }

    final Uint8List image = request.image;
    final Uint8List style = request.style;

    final prepareImageResult = await StyleTransferUtil.prepareImage(
      image: image,
      style: style,
    );

    final Image imageImg = prepareImageResult.$1;
    final Image styleImg = prepareImageResult.$2;

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

    // [1, 256, 256, 3]
    final predictionInput = [styleMatrix];

    // [1, 1, 1, 100]
    final predictionOutput = [
      [
        [List<double>.filled(100, 0)],
      ],
    ];

    // Run prediction inference
    _predictionInterpreter!.run(predictionInput, predictionOutput);

    final transferInput = [
      // image [1, 384, 384, 3]
      [imageMatrix],
      // style [1, 1, 1, 100]
      predictionOutput,
    ];

    // [1, 384, 384, 3]
    final transferOutput = [
      List.generate(384, (index) => List.filled(384, [0.0, 0.0, 0.0])),
    ];

    _styleTransferInterpreter!.runForMultipleInputs(transferInput, {
      0: transferOutput,
    });

    // Get first output tensor
    final result = transferOutput.first;

    final buffer = Uint8List.fromList(
      result
          .expand(
            (col) => col.expand((pixel) => pixel.map((e) => (e * 255).toInt())),
          )
          .toList(),
    );

    // Build image from matrix
    final imageResult = encodeJpg(
      Image.fromBytes(
        width: StyleTransferUtil.imageSize,
        height: StyleTransferUtil.imageSize,
        bytes: buffer.buffer,
        numChannels: 3,
      ),
    );

    return imageResult.buffer.asUint8List();
  }

  void close(){
    _predictionInterpreter?.close();
    _styleTransferInterpreter?.close();
    _predictionInterpreter = null;
    _predictionInterpreter = null;
  }
}
