import 'dart:typed_data';

final class RunTransferRequest {
  final Uint8List image;
  final Uint8List style;

  const RunTransferRequest({required this.image, required this.style});
}
