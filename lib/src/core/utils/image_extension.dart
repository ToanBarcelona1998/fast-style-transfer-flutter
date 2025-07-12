import 'dart:typed_data';

import 'package:fast_style_transfer_flutter/src/core/exception/export.dart';
import 'package:image/image.dart' as image;

const decodeImageError = 'Decode image error';

extension ImageExtension on Uint8List {
  Future<Uint8List> resizeImage({required int size}) async {
    var img = image.decodeImage(this);

    if (img == null) {
      throw const FastStyleTransferException(msg: decodeImageError , code: FastStyleTransferExceptionCode.decodeImageError);
    }

    final max = img.width > img.height ? img.width : img.height;

    img = image.copyExpandCanvas(img, newHeight: max, newWidth: max);

    img = image.copyResizeCropSquare(
      img,
      size: size,
      interpolation: image.Interpolation.cubic,
    );

    final output = image.encodeJpg(img);

    return output;
  }

  Future<Uint8List> rotateLeft() async {
    var img = image.decodeImage(this);

    if (img == null) {
      throw const FastStyleTransferException(msg: decodeImageError , code: FastStyleTransferExceptionCode.decodeImageError);
    }

    img = image.copyRotate(img, angle: -90);

    final output = image.encodeJpg(img);

    return output;
  }

  Future<Uint8List> rotateRight() async {
    var img = image.decodeImage(this);

    if (img == null) {
      throw const FastStyleTransferException(msg: decodeImageError , code: FastStyleTransferExceptionCode.decodeImageError);
    }

    img = image.copyRotate(img, angle: 90);

    final output = image.encodeJpg(img);

    return output;
  }
}
