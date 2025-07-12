import 'dart:io';
import 'dart:typed_data';

/// Configuration for initializing the FastStyleTransfer engine.
///
/// Includes threading settings, GPU usage, and model loading method.
final class FastStyleTransferConfig {
  /// Whether to use GPU delegate for model acceleration.
  final bool useGPU;

  /// Number of threads to use for each interpreter.
  final int thread;

  /// Loader configuration specifying how to load the models.
  final FastStyleLoaderConfig loaderConfig;

  /// Constructs a [FastStyleTransferConfig].
  ///
  /// - [useGPU] enables GPU acceleration (default: true).
  /// - [thread] sets the number of interpreter threads (default: 4).
  /// - [loaderConfig] defines how the models are loaded (from assets, file, or bytes).
  const FastStyleTransferConfig({
    this.useGPU = true,
    this.thread = 4,
    required this.loaderConfig,
  });
}

/// Abstract base class for specifying model loading configuration.
///
/// Type parameter [R] represents the resource type (e.g., String, File, Uint8List).
abstract class FastStyleLoaderConfig<R> {
  /// Resource for the style prediction model.
  final R predictResource;

  /// Resource for the style transfer model.
  final R styleTransferResource;

  /// Constructs a loader config with the given resources.
  const FastStyleLoaderConfig({
    required this.predictResource,
    required this.styleTransferResource,
  });
}

/// Model loader configuration using asset paths.
///
/// Use this when your models are bundled inside the app's asset folder.
final class FastStyleAssetsLoaderConfig
    extends FastStyleLoaderConfig<String> {
  /// Constructs an asset-based loader config.
  ///
  /// [predictResource] and [styleTransferResource] are asset file paths.
  const FastStyleAssetsLoaderConfig({
    required super.predictResource,
    required super.styleTransferResource,
  });
}

/// Model loader configuration using file system.
///
/// Use this when your models are stored in local files (e.g., downloaded).
final class FastStyleFileLoaderConfig extends FastStyleLoaderConfig<File> {
  /// Constructs a file-based loader config.
  ///
  /// [predictResource] and [styleTransferResource] are [File] instances.
  const FastStyleFileLoaderConfig({
    required super.predictResource,
    required super.styleTransferResource,
  });
}

/// Model loader configuration using in-memory model bytes.
///
/// Use this when you already have the model files loaded into memory.
final class FastStyleBytesLoaderConfig
    extends FastStyleLoaderConfig<Uint8List> {
  /// Constructs a bytes-based loader config.
  ///
  /// [predictResource] and [styleTransferResource] are raw TFLite model bytes.
  const FastStyleBytesLoaderConfig({
    required super.predictResource,
    required super.styleTransferResource,
  });
}