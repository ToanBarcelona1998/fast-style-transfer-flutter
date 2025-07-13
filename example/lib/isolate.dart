import 'dart:isolate';
import 'dart:typed_data';
import 'package:fast_style_transfer_flutter/fast_style_transfer_flutter.dart';

class StyleTransferIsolateParams {
  final Uint8List image;
  final Uint8List style;
  final FastStyleTransferFlutter fastStyleTransferFlutter;
  final SendPort sendPort;

  StyleTransferIsolateParams({
    required this.fastStyleTransferFlutter,
    required this.image,
    required this.style,
    required this.sendPort,
  });
}

void styleTransferIsolate(StyleTransferIsolateParams params) async {
  final result = await params.fastStyleTransferFlutter.run(
    request: RunTransferRequest(image: params.image, style: params.style),
  );

  params.sendPort.send(result);
}