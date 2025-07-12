import 'dart:typed_data';

import 'package:fast_style_transfer_flutter/src/core/definition/export.dart' show RunTransferRequest;

abstract interface class IFastStyleTransfer {
  Future<Uint8List> run({required RunTransferRequest request});
}
