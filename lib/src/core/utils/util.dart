import 'dart:typed_data';

import 'package:fast_style_transfer_flutter/src/core/exception/export.dart';
import 'package:image/image.dart';

import 'image_extension.dart';

final class StyleTransferUtil {
  const StyleTransferUtil._();

  static const int imageSize = 384;
  static const int styleSize = 256;

  static Future<(Image , Image)> prepareImage({required Uint8List image, required Uint8List style}) async{
    Image ? imageImg = decodeImage(image);
    Image ? styleImg = decodeImage(style);

    _validateImageDecodeError(imageImg, styleImg);

    final List<Future<Uint8List>> futures = [];
    if (imageImg!.width != imageSize || imageImg.height != imageSize) {
      final Future<Uint8List> resizedImageFuture = image.resizeImage(size: imageSize);

      futures.add(resizedImageFuture);
    }
    if (styleImg!.width != styleSize || styleImg.height != styleSize) {
      final Future<Uint8List> resizedStyleFuture = style.resizeImage(size: styleSize);

      futures.add(resizedStyleFuture);
    }

    if(futures.isNotEmpty){
      final List<Uint8List> resizedImages =  await Future.wait(futures);

      imageImg = decodeImage(resizedImages[0]);
      styleImg = decodeImage(resizedImages[1]);

      _validateImageDecodeError(imageImg, styleImg);
    }

    return (imageImg! , styleImg!);
  }

  static void _validateImageDecodeError(Image ? imageImg , Image ? styleImg){
    if (imageImg == null || styleImg == null) {
      throw const FastStyleTransferException(msg: decodeImageError, code: FastStyleTransferExceptionCode.decodeImageError);
    }
  }
}
