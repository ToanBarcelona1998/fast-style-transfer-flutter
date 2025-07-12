import 'dart:io';
import 'dart:typed_data';

final class FastStyleTransferConfig {
  final bool useGPU;
  final int thread;
  final FastStyleLoaderConfig loaderConfig;

  const FastStyleTransferConfig({
    this.useGPU = true,
    this.thread = 4,
    required this.loaderConfig,
  });
}

abstract class FastStyleLoaderConfig<R> {
  final R predictResource;
  final R styleTransferResource;

  const FastStyleLoaderConfig({required this.predictResource,required this.styleTransferResource});
}

final class FastStyleAssetsLoaderConfig extends FastStyleLoaderConfig<String> {
  const FastStyleAssetsLoaderConfig({required super.predictResource,required super.styleTransferResource,});
}

final class FastStyleFileLoaderConfig extends FastStyleLoaderConfig<File> {
  const FastStyleFileLoaderConfig({required super.predictResource,required super.styleTransferResource,});
}

final class FastStyleBytesLoaderConfig extends FastStyleLoaderConfig<Uint8List> {
  const FastStyleBytesLoaderConfig(
      {required super.predictResource, required super.styleTransferResource,});
}
